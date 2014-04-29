using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	public class MapMaterial : Material
	{
		public float3 LightCubeOffset { get; set; }

		[Color]
		public float3 TintColor{get; set;}
		public float ColormapFactor { get; set; }

		[Group("Dead Forest")]
		public float3 DeadForestCenter { get; set; }
		
		[Group("Dead Forest")]
		public float2 DeadForestAngles { get; set; }

		apply DefaultShading;
		// Color map
		texture2D colorMap : import Texture2D("../Assets/colorMapTransparent.png");
		float4 colorFromMap: sample(colorMap, WorldPosition.XY / 1024.0f, SamplerState.TrilinearClamp)  * Math.Min(1-TexCoord1.Y,1);

		// Model rendering
		float4 OcclusionColor : float4(.4f,.4f,.8f,1);
		textureCube ambientCube: import TextureCube("../Assets/AmbientColorMap2.png");
		float4 sampleAmbient : sample(ambientCube, float3(WorldNormal.X + LightCubeOffset.X, WorldNormal.Y + LightCubeOffset.Y, WorldNormal.Z + LightCubeOffset.Z), new SamplerState(TextureFilter.Linear,TextureFilter.Nearest, TextureAddressMode.Clamp));
		PixelColor : float4(((VertexColor.XYZ * (sampleAmbient.XYZ*1.4f) * ColormapFactor) * (TintColor * Math.Min(1-TexCoord1.Y,1))),1);

		float3 centerToPoint: DeadForestCenter - pixel WorldPosition;
		float angle: Math.RadiansToDegrees(Math.Atan2(centerToPoint.Y, centerToPoint.X));
		float3 burnedColor: (angle > DeadForestAngles.X && angle < DeadForestAngles.Y) ? float3(1.0f, 0.0f, 0.0f) : float3(1.0f, 1.0f, 1.0f);
		PixelColor: float4(burnedColor * prev.XYZ, prev.W);
	}
}