using Uno;
using Uno.Scenes;
using RainForest;

public partial class RainforestScene
{
	public RainforestScene()
	{
		InitializeUX();
	}	
	
	/**
	* The following code is ran when the scene is initialized in a
	* runtime environment (i.e. not designer).
	*
	* It will preload all batches and push them to the GPU so that we avoid
	* experiencing lag when the user moves through the application.
	*
	* In JavaScript you can also overwrite the console.log method and display a
	* loading screen until you've received a "BATCH_OK" message.
	*/
	protected override void OnInitialize()
	{
		debug_log("Init done, loading batches");

		PreloadTileBatches();

		debug_log("BATCH_OK");
	}


	private void PreloadTileBatches()
	{
		var tileRenderers = new TileRenderer[]
		{
			ForestTileRenderer1
		};

		foreach(var tileRenderer in tileRenderers)
		{
			tileRenderer.TileManager = TileManager1;
			tileRenderer.BuildBatches();

			var batches = tileRenderer.Batches;
			foreach(var batch in batches)
			{
				batch.Value.Flush();
			}

			debug_log tileRenderer.GetType() + " batch initialized";
		}
	}
}
