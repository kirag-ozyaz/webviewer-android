# Сборка WebViewer без Visual Studio

Visual Studio **не требуется**.

> **Полный цикл установки всех компонентов** (JDK, Android SDK, MAUI workload, bat-файлы):  
> **[SETUP.md](SETUP.md)**

## Автоматически (рекомендуется)

```cmd
cd X:\Project\APK
setup.bat
build.bat
```

Или одной командой: `setup-and-build.bat`

---

## Ручная сборка (если setup уже выполнен)

### Способ 1 — скрипт (проще)

```powershell
.\build.ps1
```

Скрипт сам выставит `ANDROID_HOME` и попытается найти `JAVA_HOME`.

### Способ 2 — вручную

```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"

dotnet build -f net8.0-android -c Release
```

### Способ 3 — Debug-сборка (быстрее, для тестов)

```powershell
dotnet build -f net8.0-android -c Debug
```

---

## Где лежит APK

После успешной **Release**-сборки:

```
WebViewer/bin/Release/net8.0-android/
```

Типичные имена файлов:

```
com.companyname.webviewer-Signed.apk
com.companyname.webviewer.apk
```

Найти все APK:

```powershell
Get-ChildItem -Recurse bin\Release\net8.0-android\*.apk
```

---

## Установка на телефон без Studio

### Через USB (adb)

1. На телефоне: **Настройки → О телефоне → 7 раз на «Номер сборки»** → включите **Режим разработчика**.
2. Включите **Отладку по USB**.
3. Подключите телефон, выполните:

```powershell
adb devices
adb install -r "bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"
```

### Запуск прямо с ПК (если телефон подключён)

```powershell
dotnet build -f net8.0-android -t:Run -c Debug
```

### Вручную

Скопируйте `.apk` на телефон (USB, облако, мессенджер) и откройте файл. Разрешите установку из неизвестных источников, если система спросит.

---

## Изменить сайт перед сборкой

Откройте `WebViewer/AppConfig.cs`:

```csharp
public const string StartUrl = "https://ваш-сайт.ru";
```

Сохраните файл и пересоберите проект.

---

## Частые ошибки

### `XA5300: Не удалось найти каталог пакета SDK для Android`

**Причина:** не установлен Android SDK или не задан путь.

**Решение:**

```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
dotnet build -f net8.0-android -c Release -p:AndroidSdkDirectory="$env:ANDROID_HOME"
```

---

### `Java SDK directory could not be found` / ошибки Java

**Причина:** не установлен JDK или не задан `JAVA_HOME`.

**Решение:**

```powershell
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"
java -version
```

---

### `Installed Android SDK API level XX is lower than required 34`

**Причина:** в SDK Manager не установлена платформа API 34.

**Решение:** Android Studio → SDK Manager → установить **Android 14 (API 34)**.

Или через cmdline-tools:

```powershell
sdkmanager "platforms;android-34" "build-tools;34.0.0"
```

---

### `dotnet workload install maui` падает на iOS

**Причина:** полный workload `maui` тянет iOS-компоненты.

**Решение:** ставьте только Android:

```powershell
dotnet workload install maui-android
```

---

### Ошибка подписи APK

Для локальной установки обычно достаточно `-Signed.apk` из папки `bin`.  
Для публикации в Google Play нужен собственный keystore — это отдельная настройка, для теста на своём телефоне не требуется.

---

## Краткая шпаргалка (всё в одном блоке)

```powershell
# Один раз
dotnet workload install maui-android

# Каждая сборка
cd X:\Project\APK\WebViewer
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"
dotnet build -f net8.0-android -c Release

# Установка на телефон
adb install -r "bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"
```

---

## Связанные файлы

| Файл | Описание |
|------|----------|
| [SETUP.md](SETUP.md) | Полная установка компонентов (setup.bat) |
| [DEPENDENCIES.md](DEPENDENCIES.md) | Список библиотек и компонентов |
| `../setup.bat` | Автоустановка |
| `../build.bat` | Автосборка |
| `WebViewer/build.ps1` | Скрипт сборки |
| `WebViewer/WebViewer.csproj` | NuGet-зависимости |
| `WebViewer/AppConfig.cs` | URL сайта |
