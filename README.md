# webviewer-android

Android-приложение на [.NET MAUI](https://dotnet.microsoft.com/apps/maui), которое открывает заданный веб-сайт на весь экран во встроенном WebView.

**Суть:** обёртка веб-приложения в APK. Пользователь видит «приложение», внутри — ваш сайт, без браузера, вкладок и адресной строки.

## Зачем

| Задача | Решение |
|--------|---------|
| Раздать внутренний портал сотрудникам | APK вместо «откройте ссылку в Chrome» |
| Есть веб-система, нет мобильного клиента | Быстрый Android-клиент без отдельной вёрстки |
| Сервер с самоподписанным SSL | Флаг `IgnoreSslCertificateErrors` в конфиге |
| Сборка без Visual Studio | `setup.bat` + `build.bat` или GitHub Actions |

> Это не полноценное нативное приложение, а тонкая оболочка вокруг WebView. Если сайт уже нормально работает в мобильном браузере — WebViewer даст тот же контент в виде APK.

## Возможности

- Один стартовый URL — в `WebViewer/AppConfig.cs`
- Полноэкранный WebView и индикатор загрузки
- `https://` и `http://`
- Опциональный обход ошибок SSL-сертификата
- Автоустановка JDK, Android SDK и MAUI workload (`setup.bat`)
- CI: проверка компонентов, доустановка, сборка APK

## Быстрый старт

**Требуется:** [**.NET 8 SDK**](https://dotnet.microsoft.com/download/dotnet/8.0) (остальное поставит `setup.bat`).

```cmd
git clone https://github.com/kirag-ozyaz/webviewer-android.git
cd webviewer-android

setup.bat
build.bat
```

Или одной командой: `setup-and-build.bat`

**APK после сборки:**

```
WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk
```

## Настройка

Файл [`WebViewer/AppConfig.cs`](WebViewer/AppConfig.cs):

```csharp
public const string StartUrl = "https://example.com/app";

// true — игнорировать ошибки SSL (только для тестов / доверенных серверов)
public const bool IgnoreSslCertificateErrors = false;
```

После изменений пересоберите: `build.bat`.

## Структура репозитория

```
webviewer-android/
├── WebViewer/          # Исходники MAUI-приложения
├── docs/               # Подробная документация
├── scripts/            # Общие скрипты (проверка окружения, CI)
├── setup.bat           # Установка JDK, SDK, workload
├── build.bat           # Сборка APK
└── .github/workflows/  # CI на GitHub Actions
```

## Документация

| Документ | Описание |
|----------|----------|
| [docs/SETUP.md](docs/SETUP.md) | Полная установка компонентов |
| [docs/DEPENDENCIES.md](docs/DEPENDENCIES.md) | Зависимости и требования |
| [docs/BUILD_WITHOUT_VS.md](docs/BUILD_WITHOUT_VS.md) | Сборка, установка на телефон, ошибки |
| [WebViewer/README.md](WebViewer/README.md) | Детали по коду приложения |

## CI

При push и pull request в `main` запускается [GitHub Actions](.github/workflows/ci.yml):

1. Проверка установленных компонентов
2. Доустановка недостающих ([`scripts/ensure-components.ps1`](scripts/ensure-components.ps1))
3. Сборка Release APK → артефакт **webviewer-apk** во вкладке Actions

## Требования

| Компонент | Назначение |
|-----------|------------|
| .NET 8 SDK | Компиляция |
| `maui-android` workload | Сборка под Android |
| JDK 17 | Android toolchain |
| Android SDK API 34 | Платформа и build-tools |

Visual Studio 2022 **не обязательна** — достаточно командной строки.

## Установка на телефон

Скопируйте APK на устройство и установите, либо через USB:

```powershell
cd WebViewer
dotnet build -f net8.0-android -t:Run
```

Подробнее: [docs/BUILD_WITHOUT_VS.md](docs/BUILD_WITHOUT_VS.md).
