// namespace WebViewer;

// public static class AppConfig
// {
//     /// <summary>
//     /// Адрес сайта, который открывается при запуске приложения.
//     /// Измените на нужный URL перед сборкой.
//     /// </summary>
//     public const string StartUrl = "https://95.68.245.5:8338/lm/";

//     /// <summary>
//     /// Игнорировать ошибки SSL-сертификата (самоподписанный, просроченный, неверное имя и т.п.).
//     /// true — не проверять сертификат, false — стандартная проверка Android.
//     /// </summary>
//     public const bool IgnoreSslCertificateErrors = true;
// }

using System;

namespace WebViewer
{
    public static class AppConfig
    {
        // Читаем URL из переменной окружения. Если её нет, используем заглушку.
        public static string StartUrl => 
            Environment.GetEnvironmentVariable("APP_START_URL") 
            ?? "https://example.com"; // Адрес по умолчанию для безопасности

        // Читаем флаг SSL. Если не задан, по умолчанию true (для обратной совместимости)
        public static bool IgnoreSslCertificateErrors => 
            bool.TryParse(Environment.GetEnvironmentVariable("APP_IGNORE_SSL"), out var result) 
            ? result 
            : true;
    }
}
