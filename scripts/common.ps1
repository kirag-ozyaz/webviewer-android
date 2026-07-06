function Find-JdkHome {
    $candidates = @(
        "${env:ProgramFiles}\Microsoft\jdk-17*",
        "${env:ProgramFiles}\Android\Android Studio\jbr",
        "${env:ProgramFiles}\Java\jdk-17*"
    )

    foreach ($pattern in $candidates) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
        if ($found -and (Test-Path (Join-Path $found.FullName "bin\java.exe"))) {
            return $found.FullName
        }
    }

    return $null
}

function Set-AndroidBuildEnvironment {
    param(
        [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    )

    $env:ANDROID_HOME = $SdkRoot
    $env:ANDROID_SDK_ROOT = $SdkRoot

    $jdk = Find-JdkHome
    if ($jdk) {
        $env:JAVA_HOME = $jdk
    }

    return [PSCustomObject]@{
        AndroidHome = $env:ANDROID_HOME
        JavaHome    = $env:JAVA_HOME
    }
}

function Get-DotNet8SdkVersion {
    $sdks = & dotnet --list-sdks 2>$null
    if (-not $sdks) { return $null }

    foreach ($line in $sdks) {
        if ($line -match '^(8\.\d+\.\d+)') {
            return $Matches[1]
        }
    }

    return $null
}

function Test-DotNet8Installed {
    return [bool](Get-DotNet8SdkVersion)
}

function Refresh-DotNetPath {
    $dotnetPath = Join-Path $env:ProgramFiles "dotnet"
    if ((Test-Path $dotnetPath) -and ($env:Path -notlike "*$dotnetPath*")) {
        $env:Path = "$dotnetPath;$env:Path"
    }
}

function Test-WingetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Show-ManualInstallAlert {
    param(
        [string]$ComponentName,
        [string]$Url,
        [string]$Details
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " НЕ УДАЛОСЬ УСТАНОВИТЬ: $ComponentName" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    if ($Details) { Write-Host $Details }
    Write-Host "Скачайте и установите вручную:" -ForegroundColor Yellow
    Write-Host $Url
    Write-Host "После установки перезапустите setup.bat" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
}

function Install-WindowsExe {
    param(
        [string]$InstallerPath,
        [string[]]$Arguments
    )

    $proc = Start-Process -FilePath $InstallerPath -ArgumentList $Arguments -Wait -PassThru
    if ($proc.ExitCode -notin 0, 3010) {
        throw "Установщик завершился с кодом $($proc.ExitCode)"
    }
}

function Install-DotNet8SdkDirect {
    $meta = Invoke-RestMethod -Uri "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/8.0/releases.json" -UseBasicParsing
    $version = $meta."latest-sdk"
    if (-not $version) {
        throw "Не удалось определить последнюю версию .NET 8 SDK"
    }

    $url = "https://builds.dotnet.microsoft.com/dotnet/Sdk/$version/dotnet-sdk-$version-win-x64.exe"
    $installer = Join-Path $env:TEMP "dotnet-sdk-$version-win-x64.exe"

    Write-Host "Скачивание .NET 8 SDK $version..."
    Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
    Write-Host "Запуск установщика..."
    Install-WindowsExe -InstallerPath $installer -Arguments @("/install", "/quiet", "/norestart")
}

function Install-DotNet8Sdk {
    $installed = $false

    if (Test-WingetAvailable) {
        Write-Host "Установка .NET 8 SDK через winget..."
        & winget install Microsoft.DotNet.SDK.8 `
            --accept-package-agreements `
            --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
        } else {
            Write-Warning "winget не сработал, пробуем прямое скачивание..."
        }
    } else {
        Write-Warning "winget не найден, скачиваем .NET 8 SDK напрямую..."
    }

    if (-not $installed) {
        try {
            Install-DotNet8SdkDirect
        } catch {
            Show-ManualInstallAlert `
                -ComponentName ".NET 8 SDK" `
                -Url "https://dotnet.microsoft.com/download/dotnet/8.0" `
                -Details $_.Exception.Message
            throw "Не удалось установить .NET 8 SDK автоматически"
        }
    }

    Refresh-DotNetPath
    $version = Get-DotNet8SdkVersion
    if (-not $version) {
        Show-ManualInstallAlert `
            -ComponentName ".NET 8 SDK" `
            -Url "https://dotnet.microsoft.com/download/dotnet/8.0" `
            -Details ".NET 8 SDK установлен, но не найден в dotnet --list-sdks. Перезапустите терминал."
        throw ".NET 8 SDK установлен, но не найден. Перезапустите терминал и запустите setup.ps1 снова."
    }
    return $version
}

function Install-OpenJdk17Direct {
    $url = "https://aka.ms/download-jdk/microsoft-jdk-17-windows-x64.msi"
    $installer = Join-Path $env:TEMP "microsoft-jdk-17.msi"

    Write-Host "Скачивание Microsoft OpenJDK 17..."
    Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
    Write-Host "Запуск установщика..."
    Install-WindowsExe -InstallerPath "msiexec.exe" -Arguments @("/i", $installer, "/quiet", "/norestart")
}

function Install-OpenJdk17 {
    $installed = $false

    if (Test-WingetAvailable) {
        Write-Host "Установка через winget..."
        & winget install Microsoft.OpenJDK.17 `
            --accept-package-agreements `
            --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
        } else {
            Write-Warning "winget не сработал, пробуем прямое скачивание..."
        }
    } else {
        Write-Warning "winget не найден, скачиваем OpenJDK 17 напрямую..."
    }

    if (-not $installed) {
        try {
            Install-OpenJdk17Direct
        } catch {
            Show-ManualInstallAlert `
                -ComponentName "Microsoft OpenJDK 17" `
                -Url "https://learn.microsoft.com/java/openjdk/download" `
                -Details $_.Exception.Message
            throw "Не удалось установить Microsoft OpenJDK 17 автоматически"
        }
    }

    $jdk = Find-JdkHome
    if (-not $jdk) {
        Show-ManualInstallAlert `
            -ComponentName "Microsoft OpenJDK 17" `
            -Url "https://learn.microsoft.com/java/openjdk/download" `
            -Details "JDK установлен, но не найден в стандартных путях. Перезапустите терминал."
        throw "JDK установлен, но не найден. Перезапустите терминал и запустите setup.ps1 снова."
    }

    return $jdk
}

function Test-DotNet8 {
    $version8 = Get-DotNet8SdkVersion
    if ($version8) {
        return $version8
    }

    $defaultVersion = (& dotnet --version 2>$null)
    if (-not $defaultVersion) {
        throw ".NET SDK не найден. Установите .NET 8: https://dotnet.microsoft.com/download/dotnet/8.0"
    }

    Write-Warning ".NET $defaultVersion найден, но .NET 8 SDK отсутствует"
    return $defaultVersion
}

function Test-MauiAndroidWorkload {
    $list = & dotnet workload list 2>$null | Out-String
    return $list -match "maui-android"
}

function Accept-AndroidSdkLicenses {
    param(
        [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    )

    $licensesDir = Join-Path $SdkRoot "licenses"
    New-Item -ItemType Directory -Force -Path $licensesDir | Out-Null

    # Стандартные хэши лицензий Android SDK (используются в CI и Docker-образах Google).
    $licenseFiles = @{
        "android-sdk-license"             = "24333f8a63b6825ea9c5514f83c2829b004d1fee"
        "android-sdk-preview-license"     = "84831b9409646a918e30173c6237ccde"
        "android-googletv-license"        = "601085b94cd77f0b54ff86406957099ebe79c4c6"
        "google-gdk-license"              = "33b6a2b64607f11b759f320ef9dff4ae5c47d5a5"
        "intel-android-extra-license"     = "d975f751698a77b662f1254ddbeac390df846aa0"
        "mips-android-sysimage-license"   = "e9acab5b5fbb560a72cfaecce894cb6f6bc8b82a"
        "android-sdk-arm-dbt-license"     = "859f31769664b585750ebe337abede4a145c4ee334ab10638f1ade45b6e9aab8"
    }

    foreach ($entry in $licenseFiles.GetEnumerator()) {
        Set-Content -Path (Join-Path $licensesDir $entry.Key) -Value $entry.Value -Encoding ascii -NoNewline
    }
}

function Install-AndroidSdkPackages {
    param(
        [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    )

    $sdkmanager = Join-Path $SdkRoot "cmdline-tools\latest\bin\sdkmanager.bat"
    if (-not (Test-Path $sdkmanager)) {
        throw "sdkmanager не найден: $sdkmanager"
    }

    Accept-AndroidSdkLicenses -SdkRoot $SdkRoot

    Write-Host "Установка platform-tools, android-34, build-tools 34.0.0..."
    & $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "sdkmanager завершился с ошибкой $LASTEXITCODE"
    }
}

function Test-AndroidSdkReady {
    param([string]$SdkRoot = (Join-Path $env:LOCALAPPDATA "Android\Sdk"))

    $platform34 = Join-Path $SdkRoot "platforms\android-34"
    $buildTools = Get-ChildItem (Join-Path $SdkRoot "build-tools") -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "^34\." } |
        Select-Object -First 1

    return (Test-Path $platform34) -and ($null -ne $buildTools)
}

function Get-BuildEnvironmentStatus {
    param(
        [string]$SdkRoot = (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    )

    $dotnetVersion = Get-DotNet8SdkVersion
    $dotnetOk = [bool]$dotnetVersion
    if (-not $dotnetOk) {
        try {
            $dotnetVersion = (& dotnet --version 2>$null)
            if (-not $dotnetVersion) {
                $dotnetVersion = "не найден"
            }
        } catch {
            $dotnetVersion = $_.Exception.Message
        }
    }

    $jdkHome = Find-JdkHome
    $mauiOk = Test-MauiAndroidWorkload
    $androidOk = Test-AndroidSdkReady -SdkRoot $SdkRoot
    $platformToolsOk = Test-Path (Join-Path $SdkRoot "platform-tools\adb.exe")

    return [PSCustomObject]@{
        DotNetVersion   = $dotnetVersion
        DotNetOk        = $dotnetOk
        MauiAndroidOk   = $mauiOk
        JdkHome         = $jdkHome
        JdkOk           = [bool]$jdkHome
        AndroidSdkOk    = $androidOk
        PlatformToolsOk = $platformToolsOk
        SdkRoot         = $SdkRoot
        AllOk           = ($dotnetOk -and $mauiOk -and [bool]$jdkHome -and $androidOk -and $platformToolsOk)
    }
}

function Show-BuildEnvironmentStatus {
    param(
        [Parameter(Mandatory = $true)]
        $Status
    )

    $items = @(
        @{ Name = ".NET 8 SDK ($($Status.DotNetVersion))"; Ok = $Status.DotNetOk },
        @{ Name = "maui-android workload"; Ok = $Status.MauiAndroidOk },
        @{ Name = "JDK 17 ($($Status.JdkHome))"; Ok = $Status.JdkOk },
        @{ Name = "Android SDK API 34 ($($Status.SdkRoot))"; Ok = $Status.AndroidSdkOk },
        @{ Name = "platform-tools"; Ok = $Status.PlatformToolsOk }
    )

    foreach ($item in $items) {
        $mark = if ($item.Ok) { "OK" } else { "MISSING" }
        $color = if ($item.Ok) { "Green" } else { "Red" }
        Write-Host "[$mark] $($item.Name)" -ForegroundColor $color
    }

    return $Status.AllOk
}

function Save-UserEnvironment {
    param(
        [string]$JavaHome,
        [string]$AndroidHome = (Join-Path $env:LOCALAPPDATA "Android\Sdk")
    )

    [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $AndroidHome, "User")
    [System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $AndroidHome, "User")

    if ($JavaHome) {
        [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $JavaHome, "User")
    }

    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $toAdd = @(
        (Join-Path $AndroidHome "platform-tools")
    )
    if ($JavaHome) {
        $toAdd += (Join-Path $JavaHome "bin")
    }

    foreach ($entry in $toAdd) {
        if ($entry -and ($userPath -notlike "*$entry*")) {
            if ($userPath) { $userPath += ";" }
            $userPath += $entry
        }
    }

    if ($userPath) {
        [System.Environment]::SetEnvironmentVariable("Path", $userPath, "User")
    }
}
