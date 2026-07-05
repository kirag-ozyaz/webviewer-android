@echo off
chcp 65001 >nul
setlocal

echo.
echo ========================================
echo  WebViewer - установка компонентов
echo ========================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Установка не завершена. Смотрите docs\SETUP.md
    pause
    exit /b 1
)

echo.
pause
exit /b 0
