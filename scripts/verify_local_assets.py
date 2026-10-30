#!/usr/bin/env python3
"""Check bundled dictionary/font assets before a Flutter build."""
from __future__ import annotations
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
JSON_PATH = ROOT / "assets/data/dictionary.json"
SYMBOLS_PATH = ROOT / "assets/data/curriculum_symbols.txt"
FONT_DIR = ROOT / "assets/fonts"
REQUIRED_FONT = FONT_DIR / "NomNaTong-Regular.ttf"
OPTIONAL_FONT = FONT_DIR / "HanNomB.ttf"

errors: list[str] = []
if "assets/data/" not in PUBSPEC:
    errors.append("pubspec.yaml chưa khai báo assets/data/.")
if "assets/fonts/" not in PUBSPEC:
    errors.append("pubspec.yaml chưa khai báo assets/fonts/.")
font_declared = bool(re.search(r"(?m)^\s*- asset: assets/fonts/NomNaTong-Regular\.ttf\s*$", PUBSPEC))
if font_declared and not REQUIRED_FONT.is_file():
    errors.append("pubspec.yaml khai báo font NomNaTong-Regular.ttf nhưng file chưa có. Chạy scripts/configure_optional_fonts.py.")

records = []
if not JSON_PATH.is_file():
    errors.append("Thiếu assets/data/dictionary.json. Hãy chạy import_rime_dictionary.bat hoặc cung cấp JSON.")
else:
    try:
        decoded = json.loads(JSON_PATH.read_text(encoding="utf-8-sig"))
        if not isinstance(decoded, list):
            errors.append("dictionary.json phải là một mảng JSON.")
        else:
            records = decoded
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        errors.append(f"dictionary.json không đọc được: {exc}")

symbols = set()
if SYMBOLS_PATH.exists():
    symbols = {
        line.strip() for line in SYMBOLS_PATH.read_text(encoding="utf-8-sig").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    }
seen: set[str] = set()
duplicates: list[str] = []
invalid = 0
collisions = 0
for row in records:
    if not isinstance(row, dict):
        invalid += 1
        continue
    character = str(row.get("character", "")).strip()
    reading = str(row.get("han_viet_reading", row.get("reading", ""))).strip()
    meaning = str(row.get("meaning", "")).strip()
    if not character or not reading or not meaning:
        invalid += 1
        continue
    if character in seen:
        duplicates.append(character)
    seen.add(character)
    if character in symbols:
        collisions += 1

print(f"Từ điển JSON: {len(records)} bản ghi; {len(seen)} ký tự phân biệt hợp lệ.")
if duplicates:
    print(f"CẢNH BÁO: JSON có {len(duplicates)} bản ghi trùng; SQLite sẽ bỏ bản ghi sau.")
if invalid:
    print(f"CẢNH BÁO: {invalid} bản ghi không đủ trường character/han_viet_reading/meaning.")
if collisions:
    print(f"CẢNH BÁO: {collisions} mục trùng với ký tự lộ trình; nên lọc bằng curriculum_symbols.txt.")
if len(records) < 5000:
    print("GHI CHÚ: chưa đạt 5.000 mục từ điển; app vẫn chạy với số dữ liệu hiện có.")
if REQUIRED_FONT.is_file():
    print("Font NomNaTong-Regular.ttf: OK.")
else:
    print("GHI CHÚ: chưa có NomNaTong-Regular.ttf; dùng font CJK hệ thống. Có thể tải font qua setup_and_run.bat sau.")
if OPTIONAL_FONT.is_file():
    if "family: HanNomB" not in PUBSPEC:
        print("GHI CHÚ: có HanNomB.ttf nhưng chưa đăng ký; chạy scripts/configure_optional_fonts.py.")
    else:
        print("Font HanNomB.ttf: OK (fallback tùy chọn).")
else:
    print("Font HanNomB.ttf: không có; bỏ qua fallback lớp 2 (không bắt buộc).")

if errors:
    for error in errors:
        print(f"LỖI: {error}")
    raise SystemExit(1)
print("Kiểm tra asset bắt buộc: thành công.")
