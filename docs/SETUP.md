# Полная установка компонентов сборки

Пошаговая инструкция и автоматические скрипты для Windows **без Visual Studio**.

> **Язык приложения — C#.** Java (JDK) нужна только сборщику Android, код на Java писать не надо.

---

## Быстрый старт (рекомендуется)

| Действие | Файл | Описание |
|----------|------|----------|
| Установить всё | [`setup.bat`](../setup.bat) | Двойной клик или из cmd |
| Установить + собрать APK | [`setup-and-build.bat`](../setup-and-build.bat) | Полный цикл |
| Только сборка | [`build.bat`](../build.bat) | После setup |

Из PowerShell:

```powershell
cd X:\Project\APK
.\setup.ps1           # только установка
.\setup.ps1 -Build    # установка + сборка APK
```

---

## Что нужно до запуска setup

Ничего обязательного вручную ставить не нужно.

`setup.bat` / `setup.ps1` теперь умеет автоматически:

- установить **.NET 8 SDK**
- установить **Microsoft OpenJDK 17**
- скачать **Android SDK cmdline-tools**
- принять лицензии Android SDK
- установить `platform-tools`, `platforms;android-34`, `build-tools;34.0.0`

Если `winget` не сработает, скрипт попробует **прямое скачивание** официального установщика. Если и это не получится, он выведет заметное сообщение со ссылкой на ручную установку.

---

## Полный цикл установки (вручную)

Если не используете bat-файлы — выполните команды по порядку.

### Шаг 1. .NET 8 SDK

**Автоматически через `setup.ps1`:**

- если .NET 8 уже установлен, скрипт использует его
- если установлен только .NET 9 или другой SDK, скрипт доустановит **.NET 8 SDK**
- если `winget` не сработает, будет использовано прямое скачивание официального установщика

**Ручная установка:** https://dotnet.microsoft.com/download/dotnet/8.0

Проверка:

```powershell
dotnet --list-sdks
# должна быть строка 8.0.x
```

---

### Шаг 2. MAUI Android workload

```powershell
dotnet workload install maui-android --skip-manifest-update
```

Если ошибка:

```powershell
dotnet workload repair
dotnet workload install maui-android --skip-manifest-update
```

Проверка:

```powershell
dotnet workload list
# должна быть строка: maui-android
```

> Не ставьте полный `maui` — он тянет iOS и часто падает на Windows.

---

### Шаг 3. JDK 17 (Microsoft OpenJDK)

**Через `setup.ps1`:**

- сначала установка через `winget`
- если `winget` не сработает, скрипт скачает официальный MSI Microsoft OpenJDK 17
- если автоустановка не получится, будет показана ссылка на ручную установку

**Вручную через winget:**

```powershell
winget install Microsoft.OpenJDK.17 `
    --accept-package-agreements `
    --accept-source-agreements
```

**Или в одну строку для cmd:**

```cmd
winget install Microsoft.OpenJDK.17 --accept-package-agreements --accept-source-agreements
```

**Или вручную:** https://learn.microsoft.com/java/openjdk/download

Проверка (путь может немного отличаться):

```powershell
& "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot\bin\java.exe" -version
```

---

### Шаг 4. Android SDK (cmdline-tools + API 34)

Папка SDK по умолчанию:

```
%LOCALAPPDATA%\Android\Sdk
```

#### 4.1. Скачать cmdline-tools

```powershell
$sdkRoot = "$env:LOCALAPPDATA\Android\Sdk"
$zipPath = "$env:TEMP\cmdline-tools.zip"
$url = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null
Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

$extract = "$env:TEMP\android-cmdline"
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
tar -xf $zipPath -C $extract

New-Item -ItemType Directory -Force -Path "$sdkRoot\cmdline-tools\latest" | Out-Null
Copy-Item "$extract\cmdline-tools\*" "$sdkRoot\cmdline-tools\latest\" -Recurse -Force
```

#### 4.2. Принять лицензии и установить платформу

```powershell
$env:JAVA_HOME = (Get-Item "C:\Program Files\Microsoft\jdk-17*").FullName
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$sdkmanager = "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat"

$answers = 1..50 | ForEach-Object { "y" }
$answers | & $sdkmanager --licenses
$answers | & $sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

Проверка:

```powershell
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platforms\android-34"
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
Test-Path "$env:LOCALAPPDATA\Android\Sdk\build-tools\34.0.0"
```

---

### Шаг 5. Переменные окружения (постоянно)

```powershell
$javaHome = (Get-Item "C:\Program Files\Microsoft\jdk-17*").FullName
$androidHome = "$env:LOCALAPPDATA\Android\Sdk"

[System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $androidHome, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $androidHome, "User")
```

Добавить в **PATH** (Параметры Windows → Переменные среды → Path → User):

```
%LOCALAPPDATA%\Android\Sdk\platform-tools
%JAVA_HOME%\bin
```

Перезапустите терминал.

---

### Шаг 6. Сборка APK

```powershell
cd X:\Project\APK\WebViewer
.\build.ps1
```

Или из корня:

```cmd
build.bat
```

APK:

```
WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk
```

---

## Скрипты проекта

| Файл | Назначение |
|------|------------|
| `setup.bat` | Запуск `setup.ps1` (удобно двойным кликом) |
| `setup.ps1` | Полная автоматическая установка |
| `setup-and-build.bat` | setup + сборка APK |
| `build.bat` | Только сборка |
| `WebViewer/build.ps1` | Сборка с авто-поиском JDK/SDK |
| `scripts/common.ps1` | Общие функции (JAVA_HOME, ANDROID_HOME) |

### Параметры setup.ps1

```powershell
.\setup.ps1                  # установить всё
.\setup.ps1 -Build           # установить и собрать APK
.\setup.ps1 -SkipWorkload    # пропустить maui-android
.\setup.ps1 -SkipJdk         # пропустить OpenJDK
.\setup.ps1 -SkipAndroidSdk  # пропустить Android SDK
```

---

## Чеклист после установки

```powershell
dotnet --list-sdks
dotnet workload list
java -version
echo $env:JAVA_HOME
echo $env:ANDROID_HOME
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platforms\android-34"
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```

Все пункты должны быть OK.

---

## Частые ошибки

| Ошибка | Решение |
|--------|---------|
| `dotnet` не найден | Запустите `setup.bat`; если автоустановка не сработает, используйте ссылку из сообщения скрипта |
| `XA5300` Java SDK | Запустите `setup.bat` или шаг 3 |
| `XA5300` Android SDK | Запустите `setup.bat` или шаг 4 |
| API level lower than 34 | Выполните шаг 4.2 и установите `platforms;android-34` |
| `winget` не найден | Это не критично: `setup.ps1` попробует прямое скачивание |
| `Accept? (y/N)` / license is not accepted | Примите лицензии через `sdkmanager --licenses` или повторно запустите обновлённый `setup.bat` |
| `maui` падает на iOS | Используйте только `maui-android` |

---

## Связанные документы

| Файл | Содержание |
|------|------------|
| [DEPENDENCIES.md](DEPENDENCIES.md) | Список библиотек и компонентов |
| [BUILD_WITHOUT_VS.md](BUILD_WITHOUT_VS.md) | Сборка, установка на телефон, ошибки |
