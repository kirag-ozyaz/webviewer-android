#if ANDROID
using Android.Net.Http;
using Android.Webkit;
using Microsoft.Maui.Handlers;
using Microsoft.Maui.Platform;
using AWebView = Android.Webkit.WebView;

namespace WebViewer;

public partial class IgnoreSslWebViewHandler : WebViewHandler
{
	protected override void ConnectHandler(AWebView platformView)
	{
		base.ConnectHandler(platformView);
		Android.Util.Log.Info("WebViewer", "IgnoreSslWebViewHandler connected");

		var settings = platformView.Settings;
		settings.JavaScriptEnabled = true;
		settings.DomStorageEnabled = true;
		settings.DatabaseEnabled = true;
		settings.SetSupportZoom(true);
		settings.BuiltInZoomControls = true;
		settings.DisplayZoomControls = false;
		settings.LoadWithOverviewMode = true;
		settings.UseWideViewPort = true;
		settings.MixedContentMode = MixedContentHandling.AlwaysAllow;
		platformView.SetBackgroundColor(Android.Graphics.Color.White);

		if (AppConfig.IgnoreSslCertificateErrors)
			platformView.SetWebViewClient(new IgnoreSslWebViewClient(this));

		platformView.Post(() =>
		{
			Android.Util.Log.Info("WebViewer", $"Native reload after handler setup: {AppConfig.StartUrl}");
			platformView.LoadUrl(AppConfig.StartUrl);
		});
	}

	private sealed class IgnoreSslWebViewClient : MauiWebViewClient
	{
		private readonly WebViewHandler _handler;

		public IgnoreSslWebViewClient(WebViewHandler handler) : base(handler)
		{
			_handler = handler;
		}

		public override void OnReceivedSslError(AWebView? view, SslErrorHandler? handler, SslError? error)
		{
			Android.Util.Log.Warn("WebViewer", $"SSL error ignored: {error}");
			handler?.Proceed();
		}

		public override void OnPageStarted(AWebView? view, string? url, Android.Graphics.Bitmap? favicon)
		{
			Android.Util.Log.Info("WebViewer", $"Native page started: {url}");
			base.OnPageStarted(view, url, favicon);
		}

		public override void OnPageFinished(AWebView? view, string? url)
		{
			Android.Util.Log.Info("WebViewer", $"Native page finished: {url}");
			base.OnPageFinished(view, url);
		}

		public override void OnReceivedError(AWebView? view, IWebResourceRequest? request, WebResourceError? error)
		{
			base.OnReceivedError(view, request, error);

			if (request?.IsForMainFrame != true)
				return;

			var description = error?.Description ?? "Неизвестная ошибка";
			MainThread.BeginInvokeOnMainThread(async () =>
			{
				if (_handler.VirtualView is Microsoft.Maui.Controls.WebView webView &&
				    webView.Window?.Page is Page page)
				{
					await page.DisplayAlert("Ошибка загрузки", description, "OK");
				}
			});
		}
	}
}
#endif
