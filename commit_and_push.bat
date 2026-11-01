@echo off
chcp 65001 >nul
echo ========================================================
echo   DANG COMMIT VA PUSH CODE LEN GITHUB
echo ========================================================

cd /d "D:\Hán Nôm ts"

echo [1/2] Luu cac thay doi vao Git...
git add .
git commit -m "refactor: Modularize architecture into screens and widgets + feat: Multilingual TTS & Calligraphy canvas"

echo [2/2] Push len GitHub...
git push -u origin HEAD

echo.
echo ========================================================
echo   HOAN TAT!
echo ========================================================
pause
