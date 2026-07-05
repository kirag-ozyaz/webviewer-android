namespace WebViewer;

public partial class MainPage : ContentPage
{
	public MainPage()
	{
		InitializeComponent();
	}

	protected override void OnAppearing()
	{
		base.OnAppearing();
		SiteWebView.Source = AppConfig.StartUrl;
	}

	private void OnNavigating(object? sender, WebNavigatingEventArgs e)
	{
		LoadingIndicator.IsVisible = true;
		LoadingIndicator.IsRunning = true;
	}

	private void OnNavigated(object? sender, WebNavigatedEventArgs e)
	{
		LoadingIndicator.IsVisible = false;
		LoadingIndicator.IsRunning = false;

		if (e.Result != WebNavigationResult.Success)
		{
			DisplayAlert("Ошибка", "Не удалось загрузить страницу. Проверьте интернет-соединение.", "OK");
		}
	}
}
