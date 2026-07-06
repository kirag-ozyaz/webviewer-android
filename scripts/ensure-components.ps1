# Проверка компонентов и доустановка недостающих (для CI и локальной проверки)
# Запуск: .\scripts\ensure-components.ps1
#         .\scripts\ensure-components.ps1 -Build

param(
    [switch]$Build
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$SetupScript = Join-Path $Root "setup.ps1"
$BuildScript = Join-Path $Root "WebViewer\build.ps1"

. (Join-Path $PSScriptRoot "common.ps1")

function Test-Environment {
    Write-Host "Проверка компонентов..." -ForegroundColor Cyan
    Write-Host ""
    $status = Get-BuildEnvironmentStatus
    $allOk = Show-BuildEnvironmentStatus -Status $status
    Write-Host ""
    return $allOk
}

if (-not (Test-Environment)) {
    Write-Host "Установка недостающих компонентов..." -ForegroundColor Yellow
    Write-Host ""
    & $SetupScript -Ci
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    if (-not (Test-Environment)) {
        Write-Error "После установки не все компоненты доступны."
        exit 1
    }
}

Write-Host "Окружение готово к сборке." -ForegroundColor Green

if ($Build) {
    Write-Host ""
    & $BuildScript
    exit $LASTEXITCODE
}

exit 0
