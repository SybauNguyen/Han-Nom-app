@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo === Han-Viet Duo: lam sach build cho Flutter Web ===
echo Truoc khi tiep tuc, hay dung app dang chay bang Ctrl+C trong terminal cu.
echo Script nay khong xoa tien do hoc trong trinh duyet.
echo.
where flutter >nul 2>nul
if errorlevel 1 (
  echo Khong tim thay Flutter SDK. Hay cai Flutter va them flutter\bin vao PATH.
  pause
  exit /b 1
)

echo [1/6] Kiem tra/tai font Nom Na Tong v5.18...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\download_nom_natong.ps1"
if errorlevel 1 goto :failed

set "PYTHON_LAUNCHER="
where py >nul 2>nul
if not errorlevel 1 set "PYTHON_LAUNCHER=py -3"
if not defined PYTHON_LAUNCHER (
  where python >nul 2>nul
  if not errorlevel 1 set "PYTHON_LAUNCHER=python"
)
if defined PYTHON_LAUNCHER (
  %PYTHON_LAUNCHER% scripts\configure_optional_fonts.py
  if errorlevel 1 goto :failed
  echo [2/6] Kiem tra file JSON va font...
  %PYTHON_LAUNCHER% scripts\verify_local_assets.py
  if errorlevel 1 goto :failed
) else (
  echo Khong co Python: bo qua script kiem tra. Kiem tra thu cong cac file assets/data/dictionary.json va assets/fonts/NomNaTong-Regular.ttf.
  if not exist "assets\data\dictionary.json" goto :failed
  if not exist "assets\fonts\NomNaTong-Regular.ttf" goto :failed
)

echo [3/6] Xoa build cu...
call flutter clean
if errorlevel 1 goto :failed

echo [4/6] Tai dependencies...
call flutter pub get
if errorlevel 1 goto :failed

echo [5/6] Chay bo kiem thu Flutter...
call flutter test
if errorlevel 1 goto :failed

echo [6/6] Khoi dong tren Microsoft Edge...
call flutter run -d edge
if errorlevel 1 goto :failed
exit /b 0

:failed
echo Co loi trong qua trinh chuan bi/chay app. Hay doc log o phia tren.
pause
exit /b 1
