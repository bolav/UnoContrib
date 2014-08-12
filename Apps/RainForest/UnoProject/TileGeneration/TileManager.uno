using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Designer;

namespace RainForest
{
	/**
	* Tile Manager Node
	*
	* Contains the settings for the various levels of details.
	* The 8 lod levels are hardcoded because we can't supply
	* an array of values at the current time in RS.
	*
	* Also, attempts at using a List<> did not succeed.
	*
	* The LOD number corresponds to the file. LOD7 is the highest detailed
	* level of detail, and the size of this file if you check in the explorer
	* is also the largest (lod_7.cake).
	*/
	public class TileManager : Node
	{
		public Entity Camera { get; set; }

		public List<Tile> Tiles = new List<Tile>();

		public float LOD0 { get; set; }
		public float LOD1 { get; set; }
		public float LOD2 { get; set; }
		public float LOD3 { get; set; }
		public float LOD4 { get; set; }
		public float LOD5 { get; set; }
		public float LOD6 { get; set; }
		public float LOD7 { get; set; }

		private float[] LODArrays
		{
			get
			{
				return new float[] { LOD7, LOD6, LOD5, LOD4, LOD3, LOD2, LOD1, LOD0 };
			}
		}

		public bool FrustumCulling
		{
			get { return TileListGenerator.FrustrumCulling; }
			set { TileListGenerator.FrustrumCulling = value; }
		}

		private TileListGenerator tileListGenerator;

		public TileManager()
		{
			LOD0 = LOD1 = LOD2 = LOD3 = 0.0f;
			LOD4 = 500;
			LOD5 = 40;
			LOD6 = 20;
			LOD7 = 8;
		}

		protected override void OnInitialize()
		{
			debug_log "On initialize called";
			base.OnInitialize();

			debug_log "TileListGenerator magic";
			tileListGenerator = new TileListGenerator(
				new RainforestTileLodMapLoader(),
				LODArrays,
				Camera
			);
		}


		protected override void OnDraw(DrawContext dc)
		{
			if (Camera == null) return;

			if(tileListGenerator == null)
			{
				OnInitialize();
			}

			tileListGenerator.LodDistances = LODArrays;
			tileListGenerator.Camera = Camera;

			Tiles.Clear();

			tileListGenerator.GenerateTiles(Tiles, dc.Aspect);
		}
	}
}