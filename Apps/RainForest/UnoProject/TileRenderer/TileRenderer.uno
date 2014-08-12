using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Drawing.Batching;
using Uno.Designer;


namespace RainForest
{
	public enum RenderTarget
	{
		Both,
		OnlyTile,
		OnlyWireframe
	}

	// This class creates the batches for a specific GetTileType, based on GetModels, and renders them through DrawTile
	public abstract class TileRenderer : Entity
	{
		[Group("Debug")]
		public bool RenderWireframe { get; set; }

		[Group("Debug")]
		public bool RenderTile { get; set; }

		public TileManager TileManager { get; set; }

		// Stores the TileMeshBatchers for every LOD, where the LOD is equal to the size of the tile, not
		// the actual TileManager LOD (which is obtainable by taking log2(size) - 3).
		private Dictionary<int, TileMeshBatcher> lodModelBatches;

		public Dictionary<int, TileMeshBatcher> Batches
		{
			get
			{
				BuildBatches();
				return lodModelBatches;
			}
		}

		protected abstract Model[] GetModels();

		protected abstract TileType GetTileType();

		public void BuildBatches()
		{
			if(TileManager == null || lodModelBatches != null) return;

			lodModelBatches = new Dictionary<int, TileMeshBatcher>();

			// Generate all the batches
			// 8x8 and 16x16 is stored in a single batch just for simplicity.
			// the subsequent sizes (32x32, 64x64) uses the previous model
			// i.e. 32x32 is 2*2 of the 16x16 model.
			for(int size = 8; size <= 128; size *= 2)
			{
				var tileBatch = new TileMeshBatcher();

				var index = (int) (Math.Log(size) / Math.Log(2.0f)) - 3;

				if(size <= 16)
				{
					tileBatch.AddMesh(GetModels()[index].GetDrawable(0).Mesh, new Tile(int2(0), size, GetTileType()));
				}
				else
				{
					// We take the better detailed models and construct a 2x2 batched tile
					// from them.

					size /= 2;
					for(int y = 0; y < 2; y++)
					{
						for(int x = 0; x < 2; x++)
						{
							tileBatch.AddMesh(	GetModels()[index - 1].GetDrawable(0).Mesh,
												new Tile(int2(x * size, y * size), size,
												GetTileType())
											);
						}
					}

					// We then put it at the correct place
					size *= 2;
				}

				lodModelBatches.Add(size, tileBatch);
			}
		}

		protected override void OnDraw(DrawContext dc)
		{
			if(TileManager == null) return;

			foreach(var tile in TileManager.Tiles)
			{
				if(tile.Type == TileType.Water || tile.Type != GetTileType()) continue;

				if(RenderTile)
				{
					DrawTile(tile);
				}

				if(RenderWireframe)
				{
					draw DefaultShading, Uno.Drawing.Primitives.Quad
					{
						Size: float2(tile.Size);
						DiffuseColor: tile.Color * (1.0f - (tile.Size / 80.0f - 1.0f));
						LineWidth: 2.0f;
						Translation: Transform.Position + float3(tile.Position, 0.0f);
						PrimitiveType: Uno.Graphics.PrimitiveType.LineStrip;
					};
				}
			}
		}

		protected abstract void DrawTile(Tile tile);
	}
}