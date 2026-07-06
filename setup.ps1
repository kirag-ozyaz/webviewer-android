# Полная установка компонентов для сборки WebViewer (без Visual Studio)
# Запуск: .\setup.ps1
#         .\setup.ps1 -Build   — установить всё и сразу собрать APK

param(
    [switch]$Build,
    [switch]$SkipWorkload,
    [switch]$SkipJdk,
    [switch]$SkipAndroidSdk,
    [switch]$Ci
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Root = $PSScriptRoot
$Common = Join-Path $Root "scripts\common.ps1"
. $Common

$SdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$CmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "==> $Text" -ForegroundColor Cyan
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

Write-Host "WebViewer — установка компонентов сборки" -ForegroundColor Green
Write-Host "Корень проекта: $Root"

# ---------------------------------------------------------------------------
Write-Step "1/6 Проверка .NET 8 SDK"
if (Test-DotNet8Installed) {
    $dotnetVersion = Get-DotNet8SdkVersion
    Write-Host ".NET 8 SDK: $dotnetVersion"
} else {
    $defaultDotnet = & dotnet --version 2>$null
    if ($defaultDotnet) {
        Write-Host "Найден .NET $defaultDotnet, устанавливаем .NET 8 SDK..."
    } else {
        Write-Host ".NET SDK не найден, устанавливаем .NET 8 SDK..."
    }
    $dotnetVersion = Install-DotNet8Sdk
    Write-Host ".NET 8 SDK установлен: $dotnetVersion"
}

# ---------------------------------------------------------------------------
if (-not $SkipWorkload) {
    Write-Step "2/6 Рабочая нагрузка MAUI Android"
    if (Test-MauiAndroidWorkload) {
        Write-Host "maui-android уже установлен"
    } else {
        Write-Host "Установка (может занять несколько минут)..."
        & dotnet workload install maui-android --skip-manifest-update
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Повтор через workload repair..."
            & dotnet workload repair
            & dotnet workload install maui-android --skip-manifest-update
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Не удалось установить maui-android"
        }
    }
} else {
    Write-Step "2/6 Рабочая нагрузка MAUI Android — пропущено"
}

# ---------------------------------------------------------------------------
if (-not $SkipJdk) {
    Write-Step "3/6 JDK 17 (Microsoft OpenJDK)"
    $jdk = Find-JdkHome
    if ($jdk) {
        Write-Host "JDK уже установлен: $jdk"
    } else {
        $jdk = Install-OpenJdk17
        Write-Host "JDK установлен: $jdk"
    }
    $env:JAVA_HOME = $jdk
} else {
    Write-Step "3/6 JDK 17 — пропущено"
    $jdk = Find-JdkHome
    if ($jdk) { $env:JAVA_HOME = $jdk }
}

# ---------------------------------------------------------------------------
if (-not $SkipAndroidSdk) {
    Write-Step "4/6 Android SDK (cmdline-tools, API 34, build-tools)"
    Ensure-Directory $SdkRoot

    $sdkmanager = Join-Path $SdkRoot "cmdline-tools\latest\bin\sdkmanager.bat"
    if (-not (Test-Path $sdkmanager)) {
        Write-Host "Скачивание Android cmdline-tools..."
        $zipPath = Join-Path $env:TEMP "cmdline-tools.zip"
        $extractPath = Join-Path $env:TEMP "android-cmdline"

        Invoke-WebRequest -Uri $CmdlineToolsUrl -OutFile $zipPath -UseBasicParsing
        if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
        Ensure-Directory $extractPath

        # tar надёжнее Expand-Archive для большого zip
        & tar -xf $zipPath -C $extractPath
        Ensure-Directory (Join-Path $SdkRoot "cmdline-tools\latest")
        Copy-Item (Join-Path $extractPath "cmdline-tools\*") (Join-Path $SdkRoot "cmdline-tools\latest\") -Recurse -Force
        Write-Host "cmdline-tools установлены"
    } else {
        Write-Host "cmdline-tools уже есть"
    }

    if (-not (Test-AndroidSdkReady -SdkRoot $SdkRoot)) {
        if (-not $env:JAVA_HOME) {
            throw "JAVA_HOME не задан. Сначала установите JDK (шаг 3)."
        }

        Write-Host "Принятие лицензий Android SDK..."
        # sdkmanager ожидает отдельное подтверждение на каждую лицензию.
        # Передаём много строк 'y', а не одну строку 'yyyy...'.
        $licenseAnswers = 1..50 | ForEach-Object { "y" }
        $licenseAnswers | & $sdkmanager --licenses 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Не удалось принять лицензии Android SDK (код $LASTEXITCODE)"
        }

        Write-Host "Установка platform-tools, android-34, build-tools 34.0.0..."
        $licenseAnswers | & $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "sdkmanager завершился с ошибкой $LASTEXITCODE"
        }
    } else {
        Write-Host "Android SDK API 34 уже установлен"
    }
} else {
    Write-Step "4/6 Android SDK — пропущено"
}

# ---------------------------------------------------------------------------
Write-Step "5/6 Переменные окружения"
$envInfo = Set-AndroidBuildEnvironment -SdkRoot $SdkRoot

if ($Ci) {
    Write-Host "CI-режим: переменные только для текущего процесса"
} else {
    Save-UserEnvironment -JavaHome $envInfo.JavaHome -AndroidHome $SdkRoot
    Write-Host "PATH обновлён (platform-tools, java\bin) в User-переменных"
}

Write-Host "ANDROID_HOME = $($envInfo.AndroidHome)"
Write-Host "JAVA_HOME    = $($envInfo.JavaHome)"

# ---------------------------------------------------------------------------
Write-Step "6/6 Проверка окружения"

if ($envInfo.JavaHome) {
    & (Join-Path $envInfo.JavaHome "bin\java.exe") -version
} else {
    Write-Warning "JAVA_HOME не найден"
}

$status = Get-BuildEnvironmentStatus -SdkRoot $SdkRoot
$allOk = Show-BuildEnvironmentStatus -Status $status

if (-not $allOk) {
    Write-Warning "Не все компоненты установлены. Смотрите docs/SETUP.md"
    exit 1
}

Write-Host ""
Write-Host "Установка завершена." -ForegroundColor Green
if (-not $Ci) {
    Write-Host "Перезапустите терминал, чтобы PATH подхватился из User-переменных."
}

if ($Build) {
    Write-Step "Сборка APK"
    & (Join-Path $Root "WebViewer\build.ps1")
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Дальше:" -ForegroundColor Yellow
Write-Host "  cd WebViewer"
Write-Host "  .\build.ps1"
Write-Host "или двойной клик: build.bat"
