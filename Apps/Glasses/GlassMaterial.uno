using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Designer;

namespace UIGlassDemo
{
	public class GlassMaterial : Material
	{
		apply DefaultShading;

		public BlendOperand BlendDst {get; set;}
		public BlendOperand BlendSrc {get; set;}

		public Texture2D DiffuseMap {get; set;}

		BlendEnabled : true;

		public override bool IsBatchable{ get{ return false; } }


		[Color]
		public float3 SubstractColor{get; set;}

		TextureCube reflection : import TextureCube("Assets/cube_product.jpg");

		WorldNormal : prev;
		ReflectedViewDirection : prev;

		TexCoord : prev;

		float4 reflectionMap : sample(reflection, ReflectedViewDirection, SamplerState.TrilinearClamp);

		DepthTestEnabled : true;

		PixelColor :  float4(SubstractColor + reflectionMap.XYZ,reflectionMap.X + 0.3f);

	}
}