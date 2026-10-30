#!/usr/bin/env python3
"""Normalize a source Hán/Nôm JSON dictionary for assets/data/dictionary.json.

Supported source keys include character/hanzi/char, han_viet_reading/sinoViet/
hanViet/reading and meaning/meaningVi/meaning_vi/gloss. The app's SQLite
UNIQUE(character) constraint then protects the curriculum from duplicate rows.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def load_records(path: Path) -> list[dict[str, Any]]:
    raw = path.read_text(encoding="utf-8-sig")
    try:
        payload = json.loads(raw)
        if isinstance(payload, list):
            records = payload
        elif isinstance(payload, dict):
            records = payload.get("characters") or payload.get("data") or payload.get("items") or []
        else:
            records = []
        if not isinstance(records, list):
            raise ValueError("JSON must be a list, or an object containing characters/data/items list")
        return [item for item in records if isinstance(item, dict)]
    except json.JSONDecodeError:
        # Also accept newline-delimited JSON.
        records: list[dict[str, Any]] = []
        for line_number, line in enumerate(raw.splitlines(), 1):
            if not line.strip():
                continue
            try:
                item = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON on line {line_number}: {exc}") from exc
            if isinstance(item, dict):
                records.append(item)
        return records


def first_value(item: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = item.get(key)
        if value is not None and str(value).strip():
            return value
    return None


def normalize_records(records: list[dict[str, Any]], blocked_chars: set[str]) -> tuple[list[dict[str, Any]], int, int]:
    normalized: list[dict[str, Any]] = []
    seen = set(blocked_chars)
    skipped = 0
    for source in records:
        char = first_value(source, "character", "hanzi", "char", "glyph", "word")
        reading = first_value(source, "han_viet_reading", "sinoViet", "hanViet", "reading", "hanviet")
        meaning = first_value(source, "meaning", "meaningVi", "meaning_vi", "gloss", "definition", "translation")
        if char is None or reading is None or meaning is None:
            skipped += 1
            continue
        char = str(char).strip()
        reading = str(reading).strip()
        meaning = str(meaning).strip()
        if not char or not reading or not meaning or char in seen:
            skipped += 1
            continue

        raw_radical = first_value(source, "radical", "radicals")
        if isinstance(raw_radical, list):
            radical = str(raw_radical[0]).strip() if raw_radical else ""
        else:
            radical = str(raw_radical).strip() if raw_radical is not None else ""

        raw_examples = source.get("examples", [])
        examples = [str(value).strip() for value in raw_examples if str(value).strip()] if isinstance(raw_examples, list) else []
        raw_type = str(first_value(source, "type", "character_type") or "Hán").strip()
        record_type = "Nôm" if raw_type.lower() in {"nôm", "nom", "chữ nôm", "chu nom"} else "Hán"
        try:
            difficulty = int(source.get("difficulty", source.get("hskLevel", 3)))
        except (TypeError, ValueError):
            difficulty = 3
        difficulty = max(1, min(5, difficulty))

        normalized.append({
            "character": char,
            "han_viet_reading": reading,
            "meaning": meaning,
            "radical": radical,
            "structure": str(source.get("structure") or "Chưa rõ"),
            "difficulty": difficulty,
            "type": record_type,
            "mnemonic": str(source.get("mnemonic") or "").strip(),
            "examples": examples,
        })
        seen.add(char)
    return normalized, skipped, len(seen.intersection({entry["character"] for entry in normalized}))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Path to licensed source JSON or JSONL")
    parser.add_argument("--output", type=Path, default=Path("assets/data/dictionary.json"))
    parser.add_argument("--curriculum-symbols", type=Path, help="Optional UTF-8 file with curriculum characters, one per line")
    args = parser.parse_args()

    if not args.input.is_file():
        parser.error(f"Input file not found: {args.input}")
    blocked = set()
    if args.curriculum_symbols:
        if not args.curriculum_symbols.is_file():
            parser.error(f"Curriculum symbols file not found: {args.curriculum_symbols}")
        blocked = {line.strip() for line in args.curriculum_symbols.read_text(encoding="utf-8-sig").splitlines() if line.strip()}

    source = load_records(args.input)
    output, skipped, _ = normalize_records(source, blocked)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Read {len(source)} records; wrote {len(output)} unique dictionary entries; skipped {skipped} missing/duplicate records.")
    print(f"Output: {args.output}")
    if len(output) < 5000:
        print("Note: fewer than 5,000 records were written. Use a larger licensed source to populate a 5,000-character dictionary.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
