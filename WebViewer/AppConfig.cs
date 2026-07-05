namespace WebViewer;

public static class AppConfig
{
    /// <summary>
    /// Адрес сайта, который открывается при запуске приложения.
    /// Измените на нужный URL перед сборкой.
    /// </summary>
    public const string StartUrl = "https://95.68.245.5:8338/lm";

    /// <summary>
    /// Игнорировать ошибки SSL-сертификата (самоподписанный, просроченный, неверное имя и т.п.).
    /// true — не проверять сертификат, false — стандартная проверка Android.
    /// </summary>
    public const bool IgnoreSslCertificateErrors = true;
}
