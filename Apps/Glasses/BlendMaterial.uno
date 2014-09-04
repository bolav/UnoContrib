using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Scenes.Designer;

namespace Glasses
{
	public class BlendMaterial : Material
	{
		apply DefaultShading;

		public BlendOperand BlendDst {get; set;}
		public BlendOperand BlendSrc {get; set;}

		public override bool IsBatchable{ get{ return false; } }

		public Texture2D DiffuseMap {get; set;}

		BlendEnabled : true;

		PixelColor : float4(DiffuseMapColor.XYZ,1);


	}
}