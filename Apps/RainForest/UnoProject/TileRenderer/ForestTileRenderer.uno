using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	public class ForestTileRenderer : TileRenderer
	{
		[Group("Material")]
		public float3 LightCubeOffset { get; set; }

		[Group("Material")]
		public float ColormapFactor { get; set; }

		[Group("Blending")]
		[Range(0, 10000, 3)]
		public float FadeStart { get; set; }

		[Group("Blending")]
		[Range(0, 100, 3)]
		public float FadeSpeed { get; set; }

		[Group("Blending")]
		[Range(0, 1, 3)]
		public float CamFadeRadius { get; set; }

		[Group("Blending")]
		[Range(0, 1, 3)]
		public float CamFadeSpeed { get; set; }

		[Group("Dead Forest")]
		public float3 DeadForestCenter { get; set; }

		[Group("Dead Forest")]
		public float2 DeadForestAngles { get; set; }

		private const int MaxTileHeight = 15;

		private Model[] treeModels = new []
		{
			import Model("../Assets/trees8x8.FBX"),
			import Model("../Assets/trees16x16.FBX"),
			import Model("../Assets/trees32x32.FBX"),
			import Model("../Assets/trees32x32.FBX")
		};

		protected override Model[] GetModels()
		{
			return treeModels;
		}

		protected  override TileType GetTileType()
		{
			return TileType.Forest;
		}

		protected override void DrawTile(Tile tile)
		{
			// Tiles go downwards, not upwards
			if(tile.Size > 64) return;

			foreach(var batch in Batches[tile.Size].Batches)
			{
				draw  DefaultShading, batch
				{
					// This rotates the object by its center based on its instance index (stored in Attrib0.W)
					float2 RotationPoint: req(Attrib0 as float4) Attrib0.XY;
					float RotationFactor: req(Attrib0 as float4) Attrib0.W;

					float4x4 RotationMat: Matrix.Mul(Matrix.Translation(float3(-RotationPoint, 0)),
												Matrix.RotationZ((float) (Math.PI / 2.0f * RotationFactor)),
												Matrix.Translation(float3(RotationPoint, 0)));

					Translation: prev + float3(tile.Position, 1.0f);
					RotationMatrix: RotationMat;

					// Color map
					texture2D colorMap : import Texture2D("../Assets/colorMapTransparent.png");
					float4 colorFromMap: sample(colorMap, WorldPosition.XY / 8.0f / 256.0f, SamplerState.NearestWrap);

					// Model rendering
					float4 OcclusionColor : float4(.4f,.4f,.8f,1);
					textureCube ambientCube: import TextureCube("../Assets/AmbientColorMap.png");
					float4 sampleAmbient : sample(ambientCube, float3(WorldNormal.X + LightCubeOffset.X, WorldNormal.Y + LightCubeOffset.Y, WorldNormal.Z + LightCubeOffset.Z), new SamplerState(TextureFilter.Linear,TextureFilter.Nearest, TextureAddressMode.Clamp));
					PixelColor : (VertexColor * (sampleAmbient*1.2f) * (Math.Min(colorFromMap + ColormapFactor,1))) * ((TexCoord1.X*1.4f) + OcclusionColor);

					BlendEnabled: true;
					BlendSrc : BlendOperand.SrcAlpha;
					BlendDst : BlendOperand.OneMinusSrcAlpha;

					// Fading
					float camDist: Vector.Length(CameraPosition - WorldPosition);
					float distanceFade:  Math.Clamp(1.0f - (camDist - FadeStart) * FadeSpeed, 0, 1);
					PixelColor: float4(prev.XYZ, distanceFade);

					// Dead forest
					float3 centerToPoint: DeadForestCenter - prev WorldPosition;
					float angle: Math.RadiansToDegrees(Math.Atan2(centerToPoint.Y, centerToPoint.X));

					WorldPosition: float3(prev.XY, (angle > DeadForestAngles.X && angle < DeadForestAngles.Y) ? -40.0f : prev.Z);
				};
			}
		}
	}
}
