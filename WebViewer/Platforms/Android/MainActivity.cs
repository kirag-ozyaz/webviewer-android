using Android.App;
using Android.Content.PM;
using Android.Graphics;
using Android.Net.Http;
using Android.OS;
using Android.Webkit;
using AWebView = Android.Webkit.WebView;

namespace WebViewer;

[Activity(Label = "\u041A\u0430\u0440\u0442\u0430 \u0423\u043B\u044C\u0413\u042D\u0421", Theme = "@style/Maui.SplashTheme", MainLauncher = true, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation | ConfigChanges.UiMode | ConfigChanges.ScreenLayout | ConfigChanges.SmallestScreenSize | ConfigChanges.Density)]
public class MainActivity : Activity
{
	private AWebView? _webView;

	protected override void OnCreate(Bundle? savedInstanceState)
	{
		base.OnCreate(savedInstanceState);

		_webView = new AWebView(this);
		_webView.SetBackgroundColor(Android.Graphics.Color.White);
		_webView.SetWebViewClient(new TrustingWebViewClient());
		_webView.SetWebChromeClient(new WebChromeClient());

		var settings = _webView.Settings;
		settings.JavaScriptEnabled = true;
		settings.DomStorageEnabled = true;
		settings.DatabaseEnabled = true;
		settings.LoadWithOverviewMode = true;
		settings.UseWideViewPort = true;
		settings.MixedContentMode = MixedContentHandling.AlwaysAllow;
		settings.SetSupportZoom(true);
		settings.BuiltInZoomControls = true;
		settings.DisplayZoomControls = false;

		SetContentView(_webView);
		_webView.LoadUrl(AppConfig.StartUrl);
	}

	public override void OnBackPressed()
	{
		if (_webView?.CanGoBack() == true)
		{
			_webView.GoBack();
			return;
		}

		base.OnBackPressed();
	}

	protected override void OnDestroy()
	{
		_webView?.Destroy();
		_webView = null;
		base.OnDestroy();
	}

	private sealed class TrustingWebViewClient : WebViewClient
	{
		public override void OnReceivedSslError(AWebView? view, SslErrorHandler? handler, SslError? error)
		{
			handler?.Proceed();
		}

		public override void OnPageStarted(AWebView? view, string? url, Bitmap? favicon)
		{
			base.OnPageStarted(view, url, favicon);
		}

		public override void OnPageFinished(AWebView? view, string? url)
		{
			base.OnPageFinished(view, url);
		}
	}
}
