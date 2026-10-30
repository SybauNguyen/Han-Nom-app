#!/usr/bin/env python3
"""Download the RIME Nôm Việt mapping and create up to N unique single-character entries.

The upstream file is a RIME input schema, not a fully glossed dictionary. It maps
Vietnamese Telex keystrokes to output characters and does not consistently supply
semantic definitions or radicals. This importer therefore uses the decoded Telex
reading in both the app's reading and provisional meaning fields; the app marks
such entries as needing editorial meaning review.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
import urllib.error
import urllib.request
from pathlib import Path
from typing import Iterable

DEFAULT_URL = "https://raw.githubusercontent.com/nomnaviet/rime-nom-viet/main/nom_viet.dict.yaml"
TONE_KEYS = {"s": "\u0301", "f": "\u0300", "r": "\u0309", "x": "\u0303", "j": "\u0323"}
TONE_COMPOSE = {
    (base, mark): composed
    for base, composed in {
        "a": {"\u0301": "á", "\u0300": "à", "\u0309": "ả", "\u0303": "ã", "\u0323": "ạ"},
        "ă": {"\u0301": "ắ", "\u0300": "ằ", "\u0309": "ẳ", "\u0303": "ẵ", "\u0323": "ặ"},
        "â": {"\u0301": "ấ", "\u0300": "ầ", "\u0309": "ẩ", "\u0303": "ẫ", "\u0323": "ậ"},
        "e": {"\u0301": "é", "\u0300": "è", "\u0309": "ẻ", "\u0303": "ẽ", "\u0323": "ẹ"},
        "ê": {"\u0301": "ế", "\u0300": "ề", "\u0309": "ể", "\u0303": "ễ", "\u0323": "ệ"},
        "i": {"\u0301": "í", "\u0300": "ì", "\u0309": "ỉ", "\u0303": "ĩ", "\u0323": "ị"},
        "o": {"\u0301": "ó", "\u0300": "ò", "\u0309": "ỏ", "\u0303": "õ", "\u0323": "ọ"},
        "ô": {"\u0301": "ố", "\u0300": "ồ", "\u0309": "ổ", "\u0303": "ỗ", "\u0323": "ộ"},
        "ơ": {"\u0301": "ớ", "\u0300": "ờ", "\u0309": "ở", "\u0303": "ỡ", "\u0323": "ợ"},
        "u": {"\u0301": "ú", "\u0300": "ù", "\u0309": "ủ", "\u0303": "ũ", "\u0323": "ụ"},
        "ư": {"\u0301": "ứ", "\u0300": "ừ", "\u0309": "ử", "\u0303": "ữ", "\u0323": "ự"},
        "y": {"\u0301": "ý", "\u0300": "ỳ", "\u0309": "ỷ", "\u0303": "ỹ", "\u0323": "ỵ"},
    }.items()
    for mark, composed in composed.items()
}


def is_cjk_ideograph(text: str) -> bool:
    """True for one Unicode code point in common CJK ideograph blocks."""
    if len(text) != 1:
        return False
    cp = ord(text)
    return (
        0x3400 <= cp <= 0x4DBF
        or 0x4E00 <= cp <= 0x9FFF
        or 0xF900 <= cp <= 0xFAFF
        or 0x20000 <= cp <= 0x2FA1F
        or 0x30000 <= cp <= 0x3347F
    )


def _apply_tone(syllable: str, combining_tone: str | None) -> str:
    if not combining_tone:
        return unicodedata.normalize("NFC", syllable)
    vowels = "aăâeêioôơuưy"
    indexes = [i for i, char in enumerate(syllable) if char in vowels]
    if not indexes:
        return syllable

    # Vietnamese placement heuristics: prefer the conventional nucleus vowel.
    # Handles common combinations in the Nôm Việt mapping; this is not a full
    # linguistic transliterator and unknown patterns keep the last-vowel rule.
    target = indexes[-1]
    priority_patterns = (
        ("uyê", "ê"), ("iêu", "ê"), ("yêu", "ê"), ("ươ", "ơ"),
        ("iê", "ê"), ("yê", "ê"), ("uô", "ô"), ("uôi", "ô"),
        ("êu", "ê"), ("ươi", "ơ"), ("oai", "a"), ("uây", "â"),
    )
    for pattern, target_vowel in priority_patterns:
        start = syllable.find(pattern)
        if start >= 0:
            target = start + pattern.index(target_vowel)
            break
    else:
        nucleus = "".join(syllable[i] for i in indexes)
        if len(indexes) >= 2:
            if nucleus.startswith(("oa", "oe", "uy")):
                target = indexes[1]
            elif nucleus.startswith(("ai", "ao", "au", "ay", "eo", "oi", "ơi", "ui", "ưi", "ia", "ua", "ưa")):
                target = indexes[0]
    base = syllable[target]
    composed = TONE_COMPOSE.get((base, combining_tone))
    if composed:
        syllable = syllable[:target] + composed + syllable[target + 1:]
    return unicodedata.normalize("NFC", syllable)


def decode_telex_code(code: str) -> str:
    """Decode common RIME Telex keystrokes into a readable Vietnamese form.

    This is intentionally an approximate display helper, not a general Telex
    keyboard implementation. The raw mapping code is preserved in JSON examples
    only when the reading could not be decoded meaningfully.
    """
    output_words: list[str] = []
    for word in code.strip().split():
        raw = word.lower()
        tone: str | None = None
        # Telex tone keys occur after the first vowel. An initial s/r is an onset,
        # not a tone mark. RIME keys often place the tone marker before final i/n/g.
        first_vowel = next((i for i, ch in enumerate(raw) if ch in "aeiouy"), len(raw))
        tone_indexes = [i for i, ch in enumerate(raw) if i > first_vowel and ch in TONE_KEYS]
        if tone_indexes:
            tone_index = tone_indexes[-1]
            tone = TONE_KEYS[raw[tone_index]]
            raw = raw[:tone_index] + raw[tone_index + 1:]

        # RIME/Nôm Việt examples include uow -> ươ; process before generic pairs.
        replacements = [
            ("uow", "ươ"), ("aa", "â"), ("aw", "ă"), ("ee", "ê"),
            ("oo", "ô"), ("ow", "ơ"), ("uw", "ư"), ("dd", "đ"),
        ]
        for source, replacement in replacements:
            raw = raw.replace(source, replacement)
        # An unpaired 'w' is not standard Vietnamese; keep it instead of guessing.
        output_words.append(_apply_tone(raw, tone))
    return " ".join(output_words).strip()


def parse_rime_lines(lines: Iterable[str], *, limit: int, blocked_characters: set[str]) -> tuple[list[dict[str, str]], int]:
    in_data = False
    output: list[dict[str, str]] = []
    seen = set(blocked_characters)
    skipped = 0
    for line in lines:
        stripped = line.strip()
        if not in_data:
            if stripped == "...":
                in_data = True
            continue
        if not stripped or stripped.startswith("#"):
            continue
        columns = line.rstrip("\r\n").split("\t")
        if len(columns) < 2:
            columns = re.split(r"\s+", stripped, maxsplit=3)
        if len(columns) < 2:
            skipped += 1
            continue
        first, second = columns[0].strip(), columns[1].strip()
        if is_cjk_ideograph(first):
            character, code = first, second
        elif is_cjk_ideograph(second):
            # Accept inverted tabular dumps too, but the upstream RIME file normally
            # has output glyph first and Telex code second.
            character, code = second, first
        else:
            skipped += 1
            continue
        if character in seen:
            skipped += 1
            continue
        reading = decode_telex_code(code)
        if not reading:
            reading = code
        output.append({
            "character": character,
            "han_viet_reading": reading,
            # RIME provides input-code mappings, not full semantic glosses.
            # The UI marks dictionary-only records with this provisional value.
            "meaning": reading,
            "radical": "",
            "structure": "Chưa có dữ liệu cấu tạo",
            "difficulty": 3,
            "type": "Nôm",
            "mnemonic": "",
            "examples": [],
        })
        seen.add(character)
        if len(output) >= limit:
            break
    if not in_data:
        raise ValueError("Không tìm thấy dấu '...' kết thúc phần header của file RIME YAML.")
    return output, skipped


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DEFAULT_URL, help="URL raw của nom_viet.dict.yaml")
    parser.add_argument("--output", type=Path, default=root / "assets/data/dictionary.json")
    parser.add_argument("--curriculum-symbols", type=Path, default=root / "assets/data/curriculum_symbols.txt")
    parser.add_argument("--limit", type=int, default=5000, help="Số ký tự duy nhất tối đa (mặc định 5000)")
    parser.add_argument("--timeout", type=float, default=45.0)
    args = parser.parse_args()
    if args.limit < 1:
        parser.error("--limit phải lớn hơn 0")

    blocked = set()
    if args.curriculum_symbols.exists():
        blocked = {
            line.strip() for line in args.curriculum_symbols.read_text(encoding="utf-8-sig").splitlines()
            if line.strip() and not line.strip().startswith("#")
        }

    request = urllib.request.Request(args.url, headers={"User-Agent": "Han-Viet-Duo-dictionary-importer/1.9"})
    try:
        with urllib.request.urlopen(request, timeout=args.timeout) as response:
            source_text = response.read().decode("utf-8-sig")
    except (urllib.error.URLError, TimeoutError, UnicodeDecodeError) as exc:
        print(f"Không tải/đọc được nguồn RIME: {exc}", file=sys.stderr)
        print("Hãy kiểm tra mạng hoặc tải nom_viet.dict.yaml thủ công rồi dùng --url file:///đường/dẫn.", file=sys.stderr)
        return 2

    try:
        records, skipped = parse_rime_lines(source_text.splitlines(), limit=args.limit, blocked_characters=blocked)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 3
    if len(records) < args.limit:
        print(f"Cảnh báo: chỉ trích xuất được {len(records)} ký tự duy nhất; mục tiêu là {args.limit}.", file=sys.stderr)

    # Atomic write: a failed import never leaves a half-written dictionary.json.
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temp_path = args.output.with_suffix(args.output.suffix + ".tmp")
    temp_path.write_text(json.dumps(records, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp_path.replace(args.output)
    print(f"Đã đọc nguồn RIME và ghi {len(records)} ký tự duy nhất; bỏ qua {skipped} dòng/ký tự trùng.")
    print(f"File đầu ra: {args.output}")
    print("Lưu ý: nguồn này là bảng ánh xạ Telex → ký tự; trường nghĩa/đọc được dùng tạm theo mã gõ, chưa phải nghĩa học thuật đã biên tập.")
    print("Sau khi tạo JSON, chạy flutter clean, flutter pub get và flutter run để nạp asset mới.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
