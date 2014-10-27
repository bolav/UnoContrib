using Uno;
using Uno.Collections;
using Fuse;
using Experimental.Net.Http;

using Fuse.Shapes;

public class App : Fuse.App
{
	public App()
	{
		Style = new Outracks.UIThemes.MobileBlue.MobileBlueStyle();
		ClearColor = float4(1f, 1f, 1f, 1f);
		RootNode = new MainView();
	}
}