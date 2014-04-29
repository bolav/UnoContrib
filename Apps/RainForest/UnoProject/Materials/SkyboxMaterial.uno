using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Designer;

namespace RainForest
{
	public class SkyboxMaterial : Material
	{
		apply DefaultShading;

		[Color]
		public float3 Color1 { get; set; }

		[Color]
		public float3 Color2 { get; set; }

		PixelColor: float4(Math.Lerp(Color1, Color2, WorldNormal.Z), 1);

		CullFace: Uno.Graphics.PolygonFace.None;
	}
}