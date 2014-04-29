using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Geometry;
using Uno.Geometry.Collision;
using RainForest.LODMathUtils;

namespace RainForest
{
	/**
	* Tile List Generator
	*
	* Generates a list of tiles using the LOD engine.
	*
	* The Lod Engine will subdivide the rectangle down to as small as it sees fit, based
	* on the LodDistances float array.
	*
	* It will also (if FrustumCulling is enabled) only subdivide down to rectangles inside
	* the specified Camera frustum. This will allow you to render more tiles, because you
	* only render those inside the Camera frustum.
	*/
	public class TileListGenerator
	{

		private Tile[][] tileLodMap;

		public float[] LodDistances { get; set; }

		public int MapSize { get; set; }

		private Recti MapSizeRecti
		{
			get
			{
				return new Recti(0, 0, MapSize, MapSize);
			}
		}

		public Entity Camera { get; set; }

		public TileListGenerator(ITileLodMapLoader mapLoader, float[] lodDistances, Entity camera)
		{
			tileLodMap = mapLoader.GetAllLodTiles();
			LodDistances = lodDistances;
			Camera = camera;
			MapSize = 2048;
		}

		public static bool FrustrumCulling = true;

		public void GenerateTiles(List<Tile> tiles)
		{
			Uno.Scenes.Frustum frustumComponent = Camera.Components.Get<Uno.Scenes.Frustum>();
			assert frustumComponent != null;

			var frustumGeometry = frustumComponent.FrustumGeometry;

			GenerateTiles(0, MapSizeRecti, frustumGeometry, tiles);
		}

		private void GenerateTiles(int depth, Recti currentRectangle, Uno.Geometry.Frustum frustum, List<Tile> tiles)
		{
			int3 rectangleCenter = int3(
				currentRectangle.Position.X + (currentRectangle.Size.X / 2),
				currentRectangle.Position.Y + (currentRectangle.Size.Y / 2),
				0
			);

			var frustumIntersectsRecti = FrustumContainsRecti(frustum, currentRectangle);

			float3 cameraToClosestPoint;
			float cameraToClosestPointDistance;
			CalculateShortestDistanceVectorToPoint(Camera.Transform.AbsolutePosition, currentRectangle, out cameraToClosestPoint, out cameraToClosestPointDistance);

			bool tileShouldBeDivided = TileShouldBeDivided(cameraToClosestPointDistance, depth);

			if (frustumIntersectsRecti && tileShouldBeDivided || !FrustrumCulling && tileShouldBeDivided)
			{
				var halfSize = currentRectangle.Size.X / 2;

				var rects = new[]
				{
					new Recti(int2(currentRectangle.Position.X, currentRectangle.Position.Y), int2(halfSize)),
					new Recti(int2(currentRectangle.Position.X, rectangleCenter.Y), int2(halfSize)),
					new Recti(int2(rectangleCenter.X, currentRectangle.Position.Y), int2(halfSize)),
					new Recti(int2(rectangleCenter.X, rectangleCenter.Y), int2(halfSize)),
				};

				int counter = 1;

				var newDepth = depth + 1;

				foreach (var rect in rects)
				{
					GenerateTiles(newDepth, rect, frustum, tiles);
				}
			}
			else if (frustumIntersectsRecti || !FrustrumCulling)
			{
				AddTile(currentRectangle, depth, tiles);
			}
		}

		private void AddTile(Recti currentRectangle, int depth, List<Tile> tiles)
		{
				var dX = currentRectangle.Right / currentRectangle.Size.X - 1;
				var dY = currentRectangle.Bottom / currentRectangle.Size.X - 1;
				var tileArray = tileLodMap[Math.Max(0, depth - 1)];
				var size = (int) Math.Sqrt(tileArray.Length);

				var tile = tileArray[dX * size + dY];

				tile.Rectangle = currentRectangle;

				tiles.Add(tile);
		}

		private bool TileShouldBeDivided(float distanceSquared, int depth)
		{
			for(int lod = 0; lod < LodDistances.Length; lod++)
			{
				if(distanceSquared < LodDistances[lod])
				{
					return depth < (LodDistances.Length - lod);
				}
			}

			return false;
		}
	}
}