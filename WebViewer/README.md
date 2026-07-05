# WebViewer — мобильное приложение .NET MAUI

Приложение открывает указанный сайт во встроенном WebView на Android.

## Документация

| Файл | Содержание |
|------|------------|
| [docs/SETUP.md](../docs/SETUP.md) | **Полная установка** (setup.bat, winget, Android SDK) |
| [docs/DEPENDENCIES.md](../docs/DEPENDENCIES.md) | Какие библиотеки и компоненты нужны |
| [docs/BUILD_WITHOUT_VS.md](../docs/BUILD_WITHOUT_VS.md) | Сборка APK без Visual Studio |

## Быстрый старт

1. Установите [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
2. Запустите из корня `X:\Project\APK`:

```cmd
setup.bat
```

3. Соберите APK:

```cmd
build.bat
```

Или всё сразу: `setup-and-build.bat`

## Требования

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- Рабочая нагрузка MAUI Android: `dotnet workload install maui-android`
- **JDK 17** (например [Microsoft OpenJDK 17](https://learn.microsoft.com/java/openjdk/download))
- **Android SDK API 34** — установите через [Android Studio](https://developer.android.com/studio) → SDK Manager

> **Visual Studio 2017 не поддерживает .NET MAUI.** Нужен **Visual Studio 2022** (17.8+) с workload «Разработка мобильных приложений на .NET», либо сборка из командной строки через `dotnet` / `build.ps1`.

## Настройка сайта

Откройте `AppConfig.cs` и измените URL:

```csharp
public const string StartUrl = "https://ваш-сайт.ru";
```

Поддерживаются `https://` и `http://` (для HTTP включён cleartext-трафик в AndroidManifest).

## Сборка APK

```powershell
cd WebViewer
.\build.ps1
```

Или вручную:

```powershell
dotnet build -f net8.0-android -c Release
```

APK будет здесь:

```
bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk
```

## Установка на телефон

1. Включите «Режим разработчика» и «Отладку по USB» на Android.
2. Подключите телефон и выполните:

```powershell
dotnet build -f net8.0-android -t:Run
```

Или скопируйте APK на телефон и установите вручную.

## Структура

| Файл | Назначение |
|------|------------|
| `AppConfig.cs` | URL сайта |
| `MainPage.xaml` | WebView на весь экран |
| `MainPage.xaml.cs` | Загрузка сайта и индикатор |
