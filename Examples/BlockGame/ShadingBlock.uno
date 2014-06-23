using Uno;
using Uno.Graphics;
using Uno.Geometry;
using Uno.Scenes;


namespace BlockGame
{
	public block ShadingBlock
	{
		apply DefaultShading;

		Texture2D BRDFTexture : import Texture2D("Data/brdf2.jpg");
		textureCube MyTexCube: import TextureCube("Data/cube_product.jpg");

		float ReflectionAmount : 0;

		float4 cubeColor: sample(MyTexCube, ReflectedViewDirection);
		float NdotL : Vector.Dot(Normal, Vector.Normalize(LightDirection));
		float NdotE : Vector.Dot(Normal, Vector.Normalize(ViewDirection));
		float diff : (NdotL * 0.3f) + 0.5f;
		float2 brdfUV : float2(NdotE * .8f, diff);
		float4 BRDF : sample(BRDFTexture, brdfUV);

		PixelColor : BRDF + (cubeColor * ReflectionAmount);
	}
}

