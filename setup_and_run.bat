@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Khong tim thay lenh flutter. Hay cai Flutter SDK va them flutter\bin vao PATH.
  pause
  exit /b 1
)

echo Kiem tra Nom Na Tong v5.18 (font chu Han-Nom)...
powershell -NoProfile -ExecutionPolicy Bypass -File "scripts\download_nom_natong.ps1"
if errorlevel 1 (
  echo CANH BAO: khong tai duoc font Nom Na Tong. App van tiep tuc voi font CJK cua he thong.
)

if not exist "android" (
  echo Tao cau truc nen tang Android, Web va Windows lan dau...
  set "BACKUP=%TEMP%\han_viet_duo_backup_%RANDOM%"
  mkdir "!BACKUP!" >nul 2>nul
  xcopy "lib" "!BACKUP!\lib\" /E /I /Y >nul
  copy /Y "pubspec.yaml" "!BACKUP!\pubspec.yaml" >nul
  flutter create --platforms=android,web,windows --project-name=han_viet_duo .
  if errorlevel 1 (
    echo Flutter khong tao duoc cau truc nen tang. Hay kiem tra flutter doctor.
    pause
    exit /b 1
  )
  xcopy "!BACKUP!\lib" "lib\" /E /I /Y >nul
  copy /Y "!BACKUP!\pubspec.yaml" "pubspec.yaml" >nul
  rmdir /S /Q "!BACKUP!" >nul 2>nul
)

rem Register HanNomB only when the optional font file exists.
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
  %PYTHON_LAUNCHER% scripts\verify_local_assets.py
  if errorlevel 1 goto :failed
) else (
  echo Khong tim thay Python. Bo qua buoc kiem tra asset; hay dam bao dictionary.json va font da co san.
)

echo Lam sach build cu de nhan asset/font moi...
call flutter clean
if errorlevel 1 goto :failed

flutter pub get
if errorlevel 1 goto :failed

flutter run
exit /b 0

:failed
echo Co loi khi chuan bi tai nguyen hoac build. Hay doc log o phia tren.
pause
exit /b 1
