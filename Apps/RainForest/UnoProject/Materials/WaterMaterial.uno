using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	public class WaterMaterial : Material
	{
		apply DefaultShading;

		[Color]
		public float3 WaterColor{get; set;}

		[Color]
		public float3 SpecularColor{get; set;}



		WorldNormal : Vector.Normalize(prev +

				float3(
					Math.Sin((float)Application.Current.FixedTime *0.3f + 1654) *0.2f,
					Math.Sin(-(float)Application.Current.FixedTime *0.3f+.413f)*0.2f,
					Math.Sin((float)Application.Current.FixedTime *0.3f)*0.2f
				));
		PixelColor : float4(WaterColor + Specular.XYZ,1);

	}
}