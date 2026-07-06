namespace WebViewer;

public partial class MainPage : ContentPage
{
	public MainPage()
	{
		InitializeComponent();
	}

	protected override async void OnAppearing()
	{
		base.OnAppearing();
		await Task.Delay(300);
		LoadStartUrl();
	}

	private void LoadStartUrl()
	{
#if ANDROID
		Android.Util.Log.Info("WebViewer", $"Loading start URL: {AppConfig.StartUrl}");
#endif
		SiteWebView.Source = new UrlWebViewSource { Url = AppConfig.StartUrl };
	}

	private void OnNavigating(object? sender, WebNavigatingEventArgs e)
	{
#if ANDROID
		Android.Util.Log.Info("WebViewer", $"Navigating: {e.Url}");
#endif
		LoadingIndicator.IsVisible = true;
		LoadingIndicator.IsRunning = true;
	}

	private async void OnNavigated(object? sender, WebNavigatedEventArgs e)
	{
#if ANDROID
		Android.Util.Log.Info("WebViewer", $"Navigated: {e.Url} - {e.Result}");
#endif
		LoadingIndicator.IsVisible = false;
		LoadingIndicator.IsRunning = false;

		if (e.Result != WebNavigationResult.Success)
		{
			await DisplayAlert("Ошибка", "Не удалось загрузить страницу. Проверьте интернет-соединение.", "OK");
			return;
		}

#if ANDROID
		try
		{
			var title = await SiteWebView.EvaluateJavaScriptAsync("document.title");
			var bodyLength = await SiteWebView.EvaluateJavaScriptAsync("document.body ? document.body.innerText.length.toString() : 'no-body'");
			Android.Util.Log.Info("WebViewer", $"Page JS: title={title}, bodyLength={bodyLength}");
		}
		catch (Exception ex)
		{
			Android.Util.Log.Warn("WebViewer", $"Page JS check failed: {ex.Message}");
		}
#endif
	}
}
