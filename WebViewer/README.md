# WebViewer

> Главная страница репозитория: [README.md](../README.md)

**WebViewer** — Android-приложение на [.NET MAUI](https://dotnet.microsoft.com/apps/maui), которое открывает заданный веб-сайт на весь экран во встроенном WebView.

По сути это **обёртка веб-приложения в APK**: пользователь видит обычное «приложение», а внутри работает ваш сайт — без браузера, вкладок и адресной строки.

## Зачем это нужно

| Сценарий | Как помогает WebViewer |
|----------|------------------------|
| Внутренний корпоративный портал | Раздать сотрудникам APK вместо «откройте ссылку в Chrome» |
| Веб-система на сервере без мобильного клиента | Быстро получить Android-приложение без отдельной разработки UI |
| Тестовый / staging-сервер с самоподписанным SSL | Можно отключить проверку сертификата одним флагом |
| Сборка без Visual Studio | Весь цикл — через `setup.bat` и `build.bat` или GitHub Actions |

Приложение **не заменяет** полноценное нативное приложение: это тонкая оболочка вокруг WebView. Если сайт уже хорошо работает в мобильном браузере — WebViewer даст тот же контент в виде APK.

## Что умеет

- Открывает один URL при запуске (настраивается в `AppConfig.cs`)
- Полноэкранный WebView с индикатором загрузки
- Поддержка `https://` и `http://`
- Опциональный обход ошибок SSL-сертификата (`IgnoreSslCertificateErrors`)
- Сборка APK из командной строки — Visual Studio не обязательна
- CI на GitHub: проверка и доустановка компонентов, сборка артефакта

## Быстрый старт

1. Установите [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
2. Из **корня репозитория** (папка выше `WebViewer/`):

```cmd
setup.bat
build.bat
```

Или одной командой: `setup-and-build.bat`

3. APK появится здесь:

```
WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk
```

## Настройка

Все параметры — в `AppConfig.cs`:

```csharp
// Адрес, который открывается при запуске
public const string StartUrl = "https://example.com/app";

// true — игнорировать ошибки SSL (самоподписанный, IP вместо имени и т.п.)
// false — стандартная проверка Android
public const bool IgnoreSslCertificateErrors = false;
```

После изменения URL или флагов пересоберите APK (`build.bat`).

> **Безопасность:** `IgnoreSslCertificateErrors = true` снижает защищённость соединения. Используйте только для тестовых или доверенных внутренних серверов.

## Сборка

```powershell
cd WebViewer
.\build.ps1
```

Или вручную:

```powershell
dotnet build -f net8.0-android -c Release
```

## Установка на телефон

**Через USB (отладка):**

```powershell
cd WebViewer
dotnet build -f net8.0-android -t:Run
```

**Вручную:** скопируйте APK на телефон и установите (может понадобиться разрешить установку из неизвестных источников).

## Требования

| Компонент | Назначение |
|-----------|------------|
| .NET 8 SDK | Компиляция проекта |
| `maui-android` workload | Сборка под Android |
| JDK 17 | Требуется инструментам Android SDK |
| Android SDK API 34 | Платформа и build-tools |

Установка автоматизирована: `setup.bat` из корня репозитория.

Visual Studio 2022 **не обязательна** — достаточно CLI. Если используете VS, нужен workload «.NET Multi-platform App UI».

## Структура проекта

| Файл | Назначение |
|------|------------|
| `AppConfig.cs` | URL и флаг SSL |
| `MainPage.xaml` | WebView на весь экран |
| `MainPage.xaml.cs` | Загрузка страницы, индикатор, сообщение об ошибке |
| `Platforms/Android/IgnoreSslWebViewHandler.cs` | Обход SSL при `IgnoreSslCertificateErrors = true` |
| `build.ps1` | Сборка APK с авто-поиском JDK/SDK |

## Документация

| Файл | Содержание |
|------|------------|
| [docs/SETUP.md](../docs/SETUP.md) | Полная установка компонентов |
| [docs/DEPENDENCIES.md](../docs/DEPENDENCIES.md) | Список зависимостей |
| [docs/BUILD_WITHOUT_VS.md](../docs/BUILD_WITHOUT_VS.md) | Сборка, установка на телефон, типичные ошибки |

## CI / GitHub

При push и pull request в `main` запускается workflow `.github/workflows/ci.yml`:

1. Проверка установленных компонентов
2. Доустановка недостающих (`scripts/ensure-components.ps1`)
3. Сборка Release APK и загрузка артефакта

Репозиторий: [github.com/kirag-ozyaz/webviewer-android](https://github.com/kirag-ozyaz/webviewer-android)

## Лицензия

Уточните лицензию в репозитории при публикации.
