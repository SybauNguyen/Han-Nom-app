@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================================
echo   DONG BO & PUSH TOAN BO CODE MOI LEN GITHUB
echo ========================================================
echo.

git add .
git status
echo.
set /p "MSG=Nhap noi dung commit (Nhan Enter de dung mac dinh): "
if "%MSG%"=="" (
  set "MSG=feat: Them 4 tinh nang moi: Video Admob nap tim, But thuan hoat hoa, 3D Flashcard Anki va Mini-game 60s"
)

git commit -m "%MSG%"
echo.
echo Dang day len GitHub (origin main)...
git push origin main

echo.
echo ========================================================
echo   HOAN TAT! Code moi da duoc dong bo len GitHub!
echo ========================================================
pause
