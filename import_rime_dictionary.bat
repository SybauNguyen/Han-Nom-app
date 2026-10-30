@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if errorlevel 1 (
  where python >nul 2>nul
  if errorlevel 1 (
    echo Khong tim thay Python. Hay cai Python 3 va them vao PATH.
    pause
    exit /b 1
  )
  python scripts\import_rime_nom_viet.py --limit 5000
) else (
  py -3 scripts\import_rime_nom_viet.py --limit 5000
)
if errorlevel 1 (
  echo Nhap tu dien that bai. Kiem tra mang va file dictionary.json hien tai.
  pause
  exit /b 1
)
echo Hoan tat. Bay gio chay flutter clean, flutter pub get, flutter run.
pause
