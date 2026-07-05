# Сборка WebViewer APK для Android
# Требуется: setup.bat (один раз) или docs/SETUP.md

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

Set-Location $projectRoot
dotnet build -f net8.0-android -c Release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "APK:" -ForegroundColor Green
    Get-ChildItem "bin\Release\net8.0-android\*.apk" | ForEach-Object { Write-Host $_.FullName }
}
