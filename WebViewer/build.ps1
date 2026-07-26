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
if ($exitCode -ne 0) {
    exit $exitCode
}

Write-Host ""
Write-Host "APK:" -ForegroundColor Green
Get-ChildItem (Join-Path $projectRoot "bin\Release\net8.0-android\*.apk") | ForEach-Object {
    Write-Host $_.FullName
}
