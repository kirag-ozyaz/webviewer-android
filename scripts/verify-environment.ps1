# Проверка компонентов сборки (без установки)
# Запуск: .\scripts\verify-environment.ps1

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "common.ps1")

Write-Host "Проверка окружения сборки WebViewer" -ForegroundColor Cyan
Write-Host ""

$status = Get-BuildEnvironmentStatus
$allOk = Show-BuildEnvironmentStatus -Status $status

Write-Host ""
if ($allOk) {
    Write-Host "Все компоненты установлены." -ForegroundColor Green
    exit 0
}

Write-Host "Не хватает компонентов. Запустите setup.bat или setup.ps1" -ForegroundColor Red
exit 1
