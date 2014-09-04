using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace Glasses
{
	public class TexQuad : Node
	{
		public texture2D Texture{get;set;}

		protected override void OnDraw(DrawContext dc)
		{
			draw Uno.Drawing.Primitives.Quad
			{
				DepthTestEnabled: false;
				PixelColor: sample( Texture, TexCoord );
			};

			base.OnDraw(dc);
		}
	}
}