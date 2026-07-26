@echo off
chcp 65001 >nul
setlocal

echo.
echo ========================================
echo  WebViewer - сборка APK
echo ========================================
echo.

:: Проверка наличия .env файла
if not exist "%~dp0.env" (
    echo [ОШИБКА] Файл .env не найден в корне проекта!
    echo Пожалуйста, создайте файл .env и укажите APP_START_URL и APP_IGNORE_SSL
    echo.
    pause
    exit /b 1
)

echo [OK] Файл .env найден. Запуск сборки...
echo.

:: Запуск PowerShell скрипта
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0WebViewer\build.ps1"

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Сборка не удалась. Проверьте логи выше.
    pause
    exit /b 1
)

echo.
echo [УСПЕХ] Сборка завершена!
pause
exit /b 0