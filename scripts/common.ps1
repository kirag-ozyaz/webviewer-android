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

function Test-DotNet8 {
    $version = (& dotnet --version 2>$null)
    if (-not $version) {
        throw ".NET SDK не найден. Установите .NET 8: https://dotnet.microsoft.com/download/dotnet/8.0"
    }
    if (-not $version.StartsWith("8.")) {
        Write-Warning ".NET $version найден, рекомендуется .NET 8.x"
    }
    return $version
}

function Test-MauiAndroidWorkload {
    $list = & dotnet workload list 2>$null | Out-String
    return $list -match "maui-android"
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

    $dotnetVersion = $null
    $dotnetOk = $false
    try {
        $dotnetVersion = Test-DotNet8
        $dotnetOk = $dotnetVersion.StartsWith("8.")
    } catch {
        $dotnetVersion = $_.Exception.Message
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
