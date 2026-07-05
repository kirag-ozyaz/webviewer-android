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

		if (AppConfig.IgnoreSslCertificateErrors)
			platformView.SetWebViewClient(new IgnoreSslWebViewClient(this));
	}

	private sealed class IgnoreSslWebViewClient : MauiWebViewClient
	{
		public IgnoreSslWebViewClient(WebViewHandler handler) : base(handler)
		{
		}

		public override void OnReceivedSslError(AWebView? view, SslErrorHandler? handler, SslError? error)
		{
			handler?.Proceed();
		}
	}
}
#endif
