# ==========================================
# Чтение переменных из .env файла
# ==========================================
$rootDir = Split-Path -Path $PSScriptRoot -Parent
$envFile = Join-Path -Path $rootDir -ChildPath ".env"

$startUrl = "https://example.com"
$ignoreSsl = "true"

if (Test-Path $envFile) {
    Write-Host "Загрузка переменных из .env..." -ForegroundColor Cyan
    
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        
        $parts = $_ -split '=', 2
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim()
            $value = $parts[1].Trim()
            $value = $value -replace '^"(.*)"$', '$1'
            $value = $value -replace "^'(.*)'$", '$1'
            
            if ($key -eq "APP_START_URL") { $startUrl = $value }
            if ($key -eq "APP_IGNORE_SSL") { $ignoreSsl = $value }
            
            Write-Host "  -> $key = $value" -ForegroundColor DarkGray
        }
    }
    Write-Host "Переменные загружены." -ForegroundColor Green
} else {
    Write-Host "ВНИМАНИЕ: Файл .env не найден. Используются значения по умолчанию." -ForegroundColor Yellow
}

# ==========================================
# Генерация файла GeneratedConfig.cs
# ==========================================
$generatedFile = Join-Path -Path $PSScriptRoot -ChildPath "GeneratedConfig.cs"

$generatedContent = @"
// Этот файл автоматически генерируется при сборке. НЕ редактируйте вручную!
namespace WebViewer
{
    public static class GeneratedConfig
    {
        public const string StartUrl = "$startUrl";
        public const bool IgnoreSslCertificateErrors = $ignoreSsl;
    }
}
"@

Set-Content -Path $generatedFile -Value $generatedContent -Encoding UTF8
Write-Host "Сгенерирован файл: GeneratedConfig.cs" -ForegroundColor Green
Write-Host "  StartUrl: $startUrl" -ForegroundColor DarkGray
Write-Host "  IgnoreSsl: $ignoreSsl" -ForegroundColor DarkGray

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

# Проверьте, был ли APK создан (независимо от exit code)
$apkPath = Join-Path $projectRoot "bin\Release\net8.0-android"
# Убедимся, что папка существует
if (-not (Test-Path $apkPath)) {
    Write-Error "Папка APK не найдена: $apkPath"
    exit 1
}

$apkFiles = Get-ChildItem -Path $apkPath -Filter "*.apk" -ErrorAction SilentlyContinue

if ($apkFiles.Count -gt 0) {
    # APK создан - это успех, даже если есть warnings
    Write-Host "[V] APK создан успешно!" -ForegroundColor Green
} else {
    # APK не создан - это реальная ошибка
    Write-Host "[X] Ошибка сборки! APK не создан. Код: $exitCode" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "APK:" -ForegroundColor Green

# ==========================================
# Поиск и переименование APK с правильной обработкой
# ==========================================
$apkOutputFileName = "map_ulges.apk"
$targetPath = Join-Path $apkPath $apkOutputFileName


# Ищем APK с типовым именем
$apkFile = Get-ChildItem -Path $apkPath -Filter "*-Signed.apk" -ErrorAction SilentlyContinue | 
    Select-Object -First 1

if (-not $apkFile) {
    Write-Error "APK файл не найден в: $apkPath"
    exit 1
}

Write-Host ""
Write-Host "APK:" -ForegroundColor Green
Write-Host "  Найден: $($apkFile.Name)" -ForegroundColor DarkGray

# Удаляем старый целевой файл если существует
if (Test-Path $targetPath) {
    Remove-Item -Path $targetPath -Force -ErrorAction Stop
}

# Переименовываем в нужное имя
Rename-Item -Path $apkFile.FullName -NewName $apkOutputFileName -Force -ErrorAction Stop

Write-Host "  ✓ Переименован в: $apkOutputFileName" -ForegroundColor Green
Write-Host ""
Write-Host "Финальный APK:" -ForegroundColor Green
Write-Host $targetPath -ForegroundColor Cyan

exit 0