@echo off
chcp 65001 >nul
setlocal

echo.
echo ========================================
echo  WebViewer - сборка APK
echo ========================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0WebViewer\build.ps1"

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Сборка не удалась. Сначала запустите setup.bat
    pause
    exit /b 1
)

echo.
pause
exit /b 0
