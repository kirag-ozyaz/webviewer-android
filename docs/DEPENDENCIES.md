# Зависимости проекта WebViewer

Список всего, что нужно установить для разработки и сборки приложения .NET MAUI (Android).

---

## 1. Системные требования

| Компонент | Минимальная версия | Назначение |
|-----------|-------------------|------------|
| ОС | Windows 10/11 (64-bit) | Сборка Android APK |
| RAM | 8 ГБ (рекомендуется 16 ГБ) | MAUI + Android SDK |
| Место на диске | ~10–15 ГБ | SDK, workload, кэш NuGet |

---

## 2. Обязательное ПО (не NuGet)

Эти компоненты **не прописаны в `.csproj`**, но без них сборка не пройдёт.

### .NET 8 SDK

- Скачать: https://dotnet.microsoft.com/download/dotnet/8.0
- Проверка:

```powershell
dotnet --version
# Ожидается: 8.0.x
```

### Рабочая нагрузка MAUI Android

Устанавливается через `dotnet` (Visual Studio не обязательна):

```powershell
dotnet workload install maui-android
```

Проверка:

```powershell
dotnet workload list
# Должна быть строка: maui-android
```

В состав workload входят (ставятся автоматически):

| Пакет | Версия (пример) | Назначение |
|-------|-----------------|------------|
| Microsoft.Maui.Sdk | 8.0.3 | SDK MAUI |
| Microsoft.Android.Sdk.Windows | 34.0.x | Сборка под Android |
| Microsoft.NETCore.App.Runtime.Mono.android-* | 8.0.x | Runtime для Android |

### JDK 17 (Java)

> **Важно:** это **не** язык программирования проекта. Код приложения написан на **C#**.  
> JDK нужен только **инструментам сборки Android** — без него `dotnet build` выдаёт ошибку `XA5300: Не удалось найти каталог пакета SDK для Java`.

Почему Java нужна при сборке C# MAUI под Android:

| Этап сборки | Кто использует Java |
|-------------|---------------------|
| Компиляция Android-ресурсов | Android SDK (aapt2, d8, zipalign) |
| Сборка APK/AAB | Gradle / Xamarin.Android toolchain |
| Подпись приложения | jarsigner / apksigner |

**Писать код на Java для этого проекта не нужно.**

#### Установка

**Автоматически (рекомендуется):** запустите [`setup.bat`](../setup.bat) из корня проекта.

**Вручную через winget:**

```powershell
winget install Microsoft.OpenJDK.17 `
    --accept-package-agreements `
    --accept-source-agreements
```

**cmd (одна строка):**

```cmd
winget install Microsoft.OpenJDK.17 --accept-package-agreements --accept-source-agreements
```

**Или вручную:** https://learn.microsoft.com/java/openjdk/download

**Или** JBR из Android Studio: `C:\Program Files\Android\Android Studio\jbr`

> Полный цикл всех компонентов: [SETUP.md](SETUP.md)

#### Переменная окружения

После установки Microsoft OpenJDK 17 путь обычно такой:

```powershell
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.19.10-hotspot"
```

Проверка:

```powershell
& "$env:JAVA_HOME\bin\java.exe" -version
# openjdk version "17.0.x"
```

### Android SDK

- Установить [Android Studio](https://developer.android.com/studio) → **SDK Manager**
- Обязательные компоненты:

| Компонент | Версия |
|-----------|--------|
| Android SDK Platform | **API 34** (Android 14) |
| Android SDK Build-Tools | 34.x |
| Android SDK Command-line Tools | latest |

Путь по умолчанию:

```
C:\Users\<ИМЯ>\AppData\Local\Android\Sdk
```

Переменные окружения:

```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
```

> В `WebViewer/WebViewer.csproj` путь к SDK подставляется автоматически, если папка `%LOCALAPPDATA%\Android\Sdk` существует.

---

## 3. NuGet-пакеты проекта

Указаны в `WebViewer/WebViewer.csproj`. При `dotnet restore` / `dotnet build` скачиваются автоматически.

### Прямые зависимости (явно в проекте)

| Пакет | Версия | Назначение |
|-------|--------|------------|
| `Microsoft.Maui.Controls` | 8.0.3 | UI-фреймворк MAUI, **WebView**, ActivityIndicator |
| `Microsoft.Maui.Controls.Compatibility` | 8.0.3 | Совместимость с legacy API |
| `Microsoft.Extensions.Logging.Debug` | 8.0.0 | Логирование в режиме отладки |

### Транзитивные зависимости (подтягиваются автоматически)

Основные группы, которые NuGet установит сам:

| Группа | Примеры пакетов | Назначение |
|--------|-----------------|------------|
| MAUI Core | `Microsoft.Maui.Core`, `Microsoft.Maui.Essentials`, `Microsoft.Maui.Graphics` | Ядро MAUI, платформенные API |
| .NET Extensions | `Microsoft.Extensions.Logging`, `Microsoft.Extensions.DependencyInjection`, `Microsoft.Extensions.Configuration` | DI, конфигурация, логи |
| Android / Xamarin | `Xamarin.AndroidX.*`, `Xamarin.Google.Android.Material`, `Xamarin.Kotlin.*` | Android-библиотеки под капотом MAUI |
| Google Android | `GoogleGson` | JSON на Android |
| Trimming | `Microsoft.NET.ILLink.Tasks` | Оптимизация размера сборки |

Полный список после первой сборки:

```
WebViewer/obj/project.assets.json
```

---

## 4. Framework references (встроены в SDK)

Не устанавливаются через NuGet — идут с .NET SDK и workload:

| Framework | Назначение |
|-----------|------------|
| `Microsoft.NETCore.App` | Базовая среда .NET 8 |
| `Microsoft.Android` | Android target framework (`net8.0-android`) |

Target framework проекта:

```
net8.0-android  →  net8.0-android34.0
```

---

## 5. Разрешения Android (не библиотеки)

В `WebViewer/Platforms/Android/AndroidManifest.xml`:

| Разрешение | Зачем |
|------------|-------|
| `INTERNET` | Загрузка сайта в WebView |
| `ACCESS_NETWORK_STATE` | Проверка сети |
| `usesCleartextTraffic="true"` | Поддержка `http://` сайтов |

---

## 6. Что НЕ нужно для этого проекта

| Компонент | Комментарий |
|-----------|-------------|
| Visual Studio 2017 / 2019 | MAUI не поддерживается |
| Visual Studio 2022 | Не обязательна, достаточно CLI |
| workload `maui` (полный) | Достаточно `maui-android` |
| workload iOS / Mac Catalyst | Проект собирается только под Android |
| Дополнительные NuGet для WebView | WebView входит в `Microsoft.Maui.Controls` |

---

## 7. Быстрая проверка окружения

```powershell
dotnet --version
dotnet workload list
java -version
echo $env:JAVA_HOME
echo $env:ANDROID_HOME
Test-Path "$env:LOCALAPPDATA\Android\Sdk\platforms\android-34"
```

Все команды должны выполниться без ошибок; последняя — вернуть `True`.
