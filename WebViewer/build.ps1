# ==========================================
# Чтение переменных из .env файла
# ==========================================
$envFile = Join-Path $PSScriptRoot "..\.env"

if (Test-Path $envFile) {
    Write-Host "Загрузка переменных из .env..." -ForegroundColor Cyan
    
    # Читаем файл построчно
    Get-Content $envFile | ForEach-Object {
        # Пропускаем пустые строки и комментарии
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        
        # Разделяем строку по знаку '='
        $parts = $_ -split '=', 2
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            
            # Убираем кавычки, если они есть
            $value = $value -replace '^"(.*)"$', '$1'
            $value = $value -replace "^'(.*)'$", '$1'
            
            # Устанавливаем переменную окружения для текущего процесса
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "  -> $key = $value" -ForegroundColor DarkGray
        }
    }
    Write-Host "Переменные окружения установлены." -ForegroundColor Green
} else {
    Write-Host "ВНИМАНИЕ: Файл .env не найден. Используются значения по умолчанию." -ForegroundColor Yellow
}

# ==========================================
# Остальная сборка (dotnet build и т.д.)
# ==========================================

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$common = Join-Path (Split-Path -Parent $projectRoot) "scripts\common.ps1"
. $common

$envInfo = Set-AndroidBuildEnvironment
if (-not $envInfo.JavaHome) {
    Write-Error "JAVA_HOME не найден. Сначала запустите setup.bat из корня проекта."
}

Write-Host "ANDROID_HOME: $($envInfo.AndroidHome)"
Write-Host "JAVA_HOME:    $($envInfo.JavaHome)"
Write-Host ""

$exitCode = Invoke-AndroidProjectBuild -ProjectRoot $projectRoot -Configuration Release
if ($exitCode -ne 0) {
    exit $exitCode
}

Write-Host ""
Write-Host "APK:" -ForegroundColor Green
Get-ChildItem (Join-Path $projectRoot "bin\Release\net8.0-android\*.apk") | ForEach-Object {
    Write-Host $_.FullName
}
