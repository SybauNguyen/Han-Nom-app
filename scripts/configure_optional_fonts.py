#!/usr/bin/env python3
"""Register only CJK fallback fonts that actually exist in assets/fonts/."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
pubspec = ROOT / "pubspec.yaml"
font_dir = ROOT / "assets/fonts"
text = pubspec.read_text(encoding="utf-8")

# Remove the generated fonts section and rebuild it from the files present.
text = re.sub(
    r"(?ms)^  fonts:\n(?:    - family: [^\n]+\n      fonts:\n        - asset: [^\n]+\n?)+",
    "",
    text,
).rstrip() + "\n"

font_blocks = []
for family, filename in (
    ("NomNaTong", "NomNaTong-Regular.ttf"),
    ("HanNomB", "HanNomB.ttf"),
):
    if (font_dir / filename).is_file():
        font_blocks.append(
            f"    - family: {family}\n      fonts:\n        - asset: assets/fonts/{filename}\n"
        )
        print(f"Đã bật font {family}: {filename}.")
    else:
        print(f"Không có {filename}; sẽ dùng font CJK của hệ thống nếu cần.")

if font_blocks:
    text = text.rstrip() + "\n\n  fonts:\n" + "".join(font_blocks)
pubspec.write_text(text.rstrip() + "\n", encoding="utf-8")
