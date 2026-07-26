@echo off
chcp 65001 >nul
setlocal

echo.
echo ========================================
echo  WebViewer - Сборка APK
echo ========================================
echo.

:: 1. Проверка .env
if not exist "%~dp0.env" (
    echo [ОШИБКА] Файл .env не найден в корне проекта!
    echo Создайте файл .env с параметрами APP_START_URL и APP_IGNORE_SSL
    pause
    exit /b 1
)

:: 2. Быстрая проверка компонентов (1-2 секунды, если всё установлено)
echo [1/3] Проверка установленных компонентов...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\ensure-components.ps1"

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Не удалось подготовить компоненты.
    pause
    exit /b 1
)

:: 3. Сборка APK
echo.
echo [2/3] Сборка проекта...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0WebViewer\build.ps1"

if errorlevel 1 (
    echo.
    echo [ОШИБКА] Сборка не удалась.
    pause
    exit /b 1
)

echo.
echo [3/3] Готово! APK находится в папке WebViewer\bin\Release\
echo ========================================
pause
exit /b 0