# Подключение телефона, установка и отладка APK

Практическая шпаргалка для проверки `WebViewer` на реальном Android-телефоне: подключение по USB, установка APK, просмотр логов, снятие скриншотов, запись экрана и очистка приложения.

Команды ниже рассчитаны на Windows PowerShell из корня проекта:

```powershell
cd X:\Project\APK
```

## Что нужно заранее

- Установлены компоненты проекта: `.NET 8 SDK`, `maui-android`, JDK 17 и Android SDK. Обычно достаточно один раз выполнить `setup.bat`.
- Телефон Android подключён по USB.
- На телефоне включены параметры разработчика и USB-отладка.
- Команда `adb` доступна из терминала. Если `adb` не найден, используйте полный путь:

```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" version
```

Дальше в документе используется короткая команда `adb`. Если она не работает, заменяйте её на:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```

## Включить USB-отладку на телефоне

1. Откройте на телефоне **Настройки**.
2. Перейдите в **О телефоне**.
3. Нажмите 7 раз на **Номер сборки**, пока Android не включит режим разработчика.
4. Вернитесь в настройки и откройте **Параметры разработчика**.
5. Включите **Отладка по USB**.
6. Подключите телефон кабелем к ПК.
7. На телефоне подтвердите окно **Разрешить отладку по USB**.

Проверка подключения:

```powershell
adb devices
```

Ожидаемый вид:

```text
List of devices attached
R58N1234567    device
```

Если вместо `device` написано `unauthorized`, разблокируйте телефон и подтвердите разрешение USB-отладки. Если устройства нет в списке, переподключите кабель и перезапустите ADB:

```powershell
adb kill-server
adb start-server
adb devices
```

## Собрать APK

Рекомендуемый способ из корня проекта:

```powershell
.\build.bat
```

APK после Release-сборки:

```text
WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk
```

Если нужно быстро найти все APK:

```powershell
Get-ChildItem -Recurse .\WebViewer\bin -Filter *.apk
```

## Установить APK на телефон

Установка или обновление уже установленного приложения:

```powershell
adb install -r ".\WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"
```

Если Android ругается на downgrade версии:

```powershell
adb install -r -d ".\WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"
```

Если подпись APK изменилась и обновление невозможно, удалите старую версию и установите заново:

```powershell
adb uninstall com.companyname.webviewer
adb install ".\WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"
```

## Запустить приложение

Самый простой способ открыть установленное приложение:

```powershell
adb shell monkey -p com.companyname.webviewer 1
```

Если `adb` не прописан в `PATH`, используйте полный путь из Android SDK:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb shell monkey -p com.companyname.webviewer 1
```

Остановить приложение:

```powershell
adb shell am force-stop com.companyname.webviewer
```

Очистить данные приложения, кеш WebView и локальное состояние:

```powershell
adb shell pm clear com.companyname.webviewer
```

## Установить и запустить Debug-сборку одной командой

Если телефон подключён, можно собрать Debug и сразу отправить приложение на устройство:

```powershell
cd .\WebViewer
dotnet build -f net8.0-android -t:Run -c Debug
cd ..
```

Для финальной проверки всё равно лучше использовать Release APK через `.\build.bat`.

## Смотреть логи приложения

В коде используются Android-логи с тегом `WebViewer`. Для чистой проверки сначала очистите лог, запустите приложение и смотрите только важные сообщения:

```powershell
adb logcat -c
adb shell monkey -p com.companyname.webviewer 1
adb logcat "WebViewer:I" "chromium:I" "AndroidRuntime:E" "*:S"
```

Полезные сообщения в логах:

- `Loading start URL` — приложение начало открывать URL из `WebViewer\AppConfig.cs`.
- `Navigating` и `Navigated` — события навигации MAUI WebView.
- `Page JS` — проверка, что страница загрузилась и JavaScript доступен.
- `SSL error ignored` — Android получил ошибку SSL, но приложение её пропустило.
- `AndroidRuntime:E` — критические падения приложения.

Сохранить лог в файл:

```powershell
adb logcat -c
adb shell monkey -p com.companyname.webviewer 1
adb logcat -d "WebViewer:I" "chromium:I" "AndroidRuntime:E" "*:S" > .\webviewer-log.txt
```

Если нужен поток логов только текущего процесса:

```powershell
$appPid = adb shell pidof com.companyname.webviewer
adb logcat --pid=$appPid
```

## Проверить сайт из телефона

Текущий стартовый адрес задаётся в `WebViewer\AppConfig.cs`:

```csharp
public const string StartUrl = "https://95.68.245.5:8338/lm/";
```

Быстрая проверка, открывается ли адрес обычным браузером телефона:

```powershell
adb shell am start -a android.intent.action.VIEW -d "https://95.68.245.5:8338/lm/"
```

Если сайт открывается в браузере, но не в приложении, смотрите `adb logcat` и настройки WebView/SSL. Если сайт не открывается и в браузере, проблема обычно в сети, VPN, доступности сервера или сертификате.

## Снять скриншот с телефона

Надёжный способ для Windows: сначала сохранить файл на телефоне, потом забрать на ПК.

```powershell
adb shell screencap -p /sdcard/webviewer-screen.png
adb pull /sdcard/webviewer-screen.png .\webviewer-screen.png
adb shell rm /sdcard/webviewer-screen.png
```

Файл появится в корне проекта:

```text
webviewer-screen.png
```

Скриншот с датой в имени:

```powershell
$name = "webviewer-screen-{0}.png" -f (Get-Date -Format "yyyyMMdd-HHmmss")
adb shell screencap -p /sdcard/$name
adb pull /sdcard/$name ".\$name"
adb shell rm /sdcard/$name
```

## Записать экран

Запуск записи:

```powershell
adb shell screenrecord /sdcard/webviewer-record.mp4
```

Остановите запись сочетанием `Ctrl+C`, затем заберите файл:

```powershell
adb pull /sdcard/webviewer-record.mp4 .\webviewer-record.mp4
adb shell rm /sdcard/webviewer-record.mp4
```

Ограничить запись 30 секундами:

```powershell
adb shell screenrecord --time-limit 30 /sdcard/webviewer-record.mp4
adb pull /sdcard/webviewer-record.mp4 .\webviewer-record.mp4
adb shell rm /sdcard/webviewer-record.mp4
```

## Быстрый цикл проверки после изменений

```powershell
cd X:\Project\APK

# 1. Собрать APK
.\build.bat

# 2. Установить на телефон
adb install -r ".\WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"

# 3. Очистить старый лог и запустить приложение
adb logcat -c
adb shell monkey -p com.companyname.webviewer 1

# 4. Смотреть логи
adb logcat "WebViewer:I" "chromium:I" "AndroidRuntime:E" "*:S"
```

## Частые проблемы

### `adb` не найден

Android SDK установлен, но `platform-tools` не добавлен в `PATH`.

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

### Устройство `unauthorized`

Разблокируйте телефон, подтвердите окно RSA-ключа для USB-отладки и повторите:

```powershell
adb kill-server
adb start-server
adb devices
```

### `INSTALL_FAILED_UPDATE_INCOMPATIBLE`

На телефоне стоит версия с другой подписью. Удалите её:

```powershell
adb uninstall com.companyname.webviewer
adb install ".\WebViewer\bin\Release\net8.0-android\com.companyname.webviewer-Signed.apk"
```

### Белый экран или сайт не загрузился

Проверьте:

- URL в `WebViewer\AppConfig.cs`.
- Доступность сайта с самого телефона.
- Логи `WebViewer`, `chromium` и `AndroidRuntime`.
- Флаг `IgnoreSslCertificateErrors` в `WebViewer\AppConfig.cs`.
- Наличие интернета, VPN или доступа к внутренней сети.

### Ошибка SSL

Для текущего проекта можно временно разрешить обход SSL:

```csharp
public const bool IgnoreSslCertificateErrors = true;
```

После изменения пересоберите APK и установите заново. Для публичного или production-сценария лучше исправить сертификат на сервере.

## Полезные команды ADB

```powershell
# Список устройств
adb devices

# Информация об Android-версии
adb shell getprop ro.build.version.release

# Проверить, установлен ли пакет
adb shell pm list packages | Select-String "webviewer"

# Остановить приложение
adb shell am force-stop com.companyname.webviewer

# Очистить данные приложения
adb shell pm clear com.companyname.webviewer

# Удалить приложение
adb uninstall com.companyname.webviewer

# Сделать скриншот
adb shell screencap -p /sdcard/webviewer-screen.png
adb pull /sdcard/webviewer-screen.png .\webviewer-screen.png
adb shell rm /sdcard/webviewer-screen.png
```

## Связанные файлы проекта

- `WebViewer\AppConfig.cs` — стартовый URL и флаг обхода SSL.
- `WebViewer\Platforms\Android\IgnoreSslWebViewHandler.cs` — настройки Android WebView и обработка SSL-ошибок.
- `WebViewer\MainPage.xaml.cs` — события загрузки страницы и логи `WebViewer`.
- `WebViewer\WebViewer.csproj` — идентификатор приложения `com.companyname.webviewer`.
- `build.bat` — сборка Release APK из корня проекта.
