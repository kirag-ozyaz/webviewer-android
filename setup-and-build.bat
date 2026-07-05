@echo off
chcp 65001 >nul
setlocal

echo.
echo ========================================
echo  WebViewer - установка и сборка APK
echo ========================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Build

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Смотрите docs\SETUP.md
    pause
    exit /b 1
)

echo.
pause
exit /b 0
