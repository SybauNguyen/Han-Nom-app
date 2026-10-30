#!/usr/bin/env python3
"""Build the CJKV master asset from the current Hán seed, dictionary.json and reading overrides.

The script deliberately leaves readings empty when the source does not provide them.
It does not invent a Pinyin/On'yomi value, and it does not treat Chinese Simplified
forms as Japanese Shinjitai by default.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
SEED_PATTERN = re.compile(
    r"HanCharacter\(character:\s*'((?:\\.|[^'])*)'\s*,\s*"
    r"hanVietReading:\s*'((?:\\.|[^'])*)'\s*,\s*"
    r"meaning:\s*'((?:\\.|[^'])*)'"
)


def as_reading_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        values = [str(item).strip() for item in value if str(item).strip()]
    else:
        text = str(value).strip()
        values = [part.strip() for part in re.split(r"[,;/]", text) if part.strip()]
    result: list[str] = []
    for value in values:
        if value not in result:
            result.append(value)
    return result


def load_json_records(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    payload = json.loads(path.read_text(encoding="utf-8-sig"))
    if isinstance(payload, list):
        records = payload
    elif isinstance(payload, dict):
        records = payload.get("characters") or payload.get("items") or payload.get("data") or []
    else:
        records = []
    if not isinstance(records, list):
        raise ValueError(f"Dữ liệu trong {path} phải là một danh sách JSON.")
    return [dict(item) for item in records if isinstance(item, dict)]


def parse_seed_dart(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8")
    records: list[dict[str, Any]] = []
    for char, reading, meaning in SEED_PATTERN.findall(raw):
        # Current seed entries don't use escaped single quotes, but unescape them
        # so the parser remains safe if a future Vietnamese gloss contains one.
        records.append({
            "character": char.replace(r"\'", "'"),
            "han_viet_reading": reading.replace(r"\'", "'"),
            "meaning_vi": meaning.replace(r"\'", "'"),
            "source": "curriculum_seed",
        })
    return records


def first_non_empty(item: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = item.get(key)
        if value is not None and str(value).strip():
            return value
    return None


def build_master_dictionary(
    dictionary_path: Path,
    seed_path: Path,
    overrides_path: Path,
    output_path: Path,
) -> tuple[int, int, int]:
    overrides = json.loads(overrides_path.read_text(encoding="utf-8-sig")) if overrides_path.exists() else {}
    if not isinstance(overrides, dict):
        raise ValueError("cjk_readings_overrides.json phải là một object JSON theo mã chữ.")

    # Seed first: this keeps the curriculum's curated Hán-Việt readings/meanings
    # authoritative when the same character also appears in dictionary.json.
    sources = parse_seed_dart(seed_path) + load_json_records(dictionary_path)
    by_character: dict[str, dict[str, Any]] = {}
    order: list[str] = []

    for item in sources:
        char = first_non_empty(item, "char_traditional", "character", "hanzi", "char", "glyph")
        if char is None:
            continue
        char = str(char).strip()
        if not char:
            continue

        if char not in by_character:
            order.append(char)
            by_character[char] = {
                "char_traditional": char,
                "char_simplified": str(first_non_empty(item, "char_simplified", "simplified") or char).strip(),
                # Important: Japanese Shinjitai is not always the same as Chinese Simplified.
                "char_shinjitai": str(first_non_empty(item, "char_shinjitai", "shinjitai", "japanese_form") or char).strip(),
                "meaning_vi": str(first_non_empty(item, "meaning_vi", "meaning", "meaningVi", "gloss") or "").strip(),
                "meaning_en": str(first_non_empty(item, "meaning_en", "meaningEn") or "").strip(),
                "readings_hanviet": as_reading_list(first_non_empty(item, "han_viet_reading", "readings_hanviet", "hanViet", "sinoViet", "reading")),
                "readings_pinyin": as_reading_list(first_non_empty(item, "pinyin", "readings_pinyin")),
                "readings_onyomi": as_reading_list(first_non_empty(item, "onyomi", "readings_onyomi")),
                "readings_kunyomi": as_reading_list(first_non_empty(item, "kunyomi", "readings_kunyomi")),
                "readings_hanja": as_reading_list(first_non_empty(item, "readings_hanja", "hanja")),
                "readings_jyutping": as_reading_list(first_non_empty(item, "readings_jyutping", "jyutping")),
            }
        else:
            row = by_character[char]
            # Fill gaps from dictionary.json without replacing the lesson seed's
            # approved Hán-Việt reading or meaning.
            for out_key, in_keys in {
                "meaning_vi": ("meaning_vi", "meaning", "meaningVi", "gloss"),
                "meaning_en": ("meaning_en", "meaningEn"),
                "char_simplified": ("char_simplified", "simplified"),
                "char_shinjitai": ("char_shinjitai", "shinjitai", "japanese_form"),
            }.items():
                current = str(row.get(out_key) or "").strip()
                incoming = first_non_empty(item, *in_keys)
                if not current and incoming is not None:
                    row[out_key] = str(incoming).strip()
            for out_key, in_keys in {
                "readings_hanviet": ("han_viet_reading", "readings_hanviet", "hanViet", "sinoViet", "reading"),
                "readings_pinyin": ("pinyin", "readings_pinyin"),
                "readings_onyomi": ("onyomi", "readings_onyomi"),
                "readings_kunyomi": ("kunyomi", "readings_kunyomi"),
                "readings_hanja": ("readings_hanja", "hanja"),
                "readings_jyutping": ("readings_jyutping", "jyutping"),
            }.items():
                current = row.get(out_key, [])
                incoming = as_reading_list(first_non_empty(item, *in_keys))
                row[out_key] = current or incoming

    for char, override in overrides.items():
        if not isinstance(override, dict):
            continue
        if char not in by_character:
            # Allow a curated CJK record outside the current lesson seed.
            by_character[char] = {
                "char_traditional": char,
                "char_simplified": char,
                "char_shinjitai": char,
                "meaning_vi": "",
                "meaning_en": "",
                "readings_hanviet": [],
                "readings_pinyin": [],
                "readings_onyomi": [],
                "readings_kunyomi": [],
                "readings_hanja": [],
                "readings_jyutping": [],
            }
            order.append(char)
        row = by_character[char]
        for key in ("char_simplified", "char_shinjitai", "meaning_vi", "meaning_en"):
            value = override.get(key)
            if value is not None and str(value).strip():
                row[key] = str(value).strip()
        for key in (
            "readings_hanviet", "readings_pinyin", "readings_onyomi",
            "readings_kunyomi", "readings_hanja", "readings_jyutping",
        ):
            if key in override:
                row[key] = as_reading_list(override[key])

    result: list[dict[str, Any]] = []
    missing_mandarin = 0
    missing_japanese = 0
    for index, char in enumerate(order, start=1):
        row = dict(by_character[char])
        row["id"] = index
        # Ensure required list keys are present and normalized.
        for key in (
            "readings_hanviet", "readings_pinyin", "readings_onyomi",
            "readings_kunyomi", "readings_hanja", "readings_jyutping",
        ):
            row[key] = as_reading_list(row.get(key))
        if not row["readings_pinyin"]:
            missing_mandarin += 1
        if not row["readings_onyomi"]:
            missing_japanese += 1
        result.append(row)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return len(result), missing_mandarin, missing_japanese


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dictionary", type=Path, default=ROOT / "assets/data/dictionary.json")
    parser.add_argument("--seed-dart", type=Path, default=ROOT / "lib/data/han_seed_data.dart")
    parser.add_argument("--overrides", type=Path, default=ROOT / "assets/data/cjk_readings_overrides.json")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/data/master_dictionary.json")
    args = parser.parse_args()

    if not args.seed_dart.is_file():
        parser.error(f"Không tìm thấy seed Hán: {args.seed_dart}")
    try:
        total, no_mandarin, no_japanese = build_master_dictionary(
            args.dictionary, args.seed_dart, args.overrides, args.output
        )
    except (OSError, json.JSONDecodeError, ValueError) as exc:
        parser.error(str(exc))
    print(f"Đã tạo {total} bản ghi CJKV: {args.output}")
    print(f"Thiếu Pinyin: {no_mandarin}; thiếu On'yomi: {no_japanese}.")
    if no_mandarin or no_japanese:
        print("Lưu ý: các ô đọc chưa có nguồn xác thực được để trống, không tự suy đoán âm đọc.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
