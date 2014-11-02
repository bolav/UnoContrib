using Uno;
using Uno.Collections;
using Fuse;

public partial class RubeScene
{
    public RubeScene()
    {
        InitializeUX();
    }
	
	public event KeyPressedHandler KeyPressed;
	protected override void OnKeyPressed(KeyPressedArgs args)
	{
		if (KeyPressed != null) KeyPressed(this, args);
	}
	
}

