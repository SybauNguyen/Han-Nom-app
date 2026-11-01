@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================================
echo   KHOI CHAY UNG DUNG HAN-VIET DUO
echo ========================================================

set "FLUTTER_CMD=D:\flutter\bin\flutter.bat"
if not exist "%FLUTTER_CMD%" (
  where flutter >nul 2>nul
  if not errorlevel 1 (
    set "FLUTTER_CMD=flutter"
  ) else (
    echo Khong tim thay Flutter tai D:\flutter\bin
    pause
    exit /b 1
  )
)

echo Tim thay Flutter: %FLUTTER_CMD%
echo.

echo [1/3] Kiem tra runner nen tang...
if not exist "web\index.html" (
  call "%FLUTTER_CMD%" create --platforms=web,windows --project-name=han_viet_duo .
)

echo.
echo [2/3] Cai dat thu vien (pub get)...
call "%FLUTTER_CMD%" pub get

echo.
echo [3/3] Dang khoi chay ung dung...
echo Hay chon thiet bi de chay:
echo [1] Chay tren Google Chrome
echo [2] Chay tren Microsoft Edge
echo [3] Chay tren Windows Desktop
echo.
set /p "CHOICE=Nhap lua chon cua ban (1, 2 hoac 3, mac dinh 1): "

if "%CHOICE%"=="2" (
  call "%FLUTTER_CMD%" run -d edge
) else if "%CHOICE%"=="3" (
  call "%FLUTTER_CMD%" run -d windows
) else (
  call "%FLUTTER_CMD%" run -d chrome
)

echo.
echo ========================================================
echo   Lenh da ket thuc.
echo ========================================================
pause
