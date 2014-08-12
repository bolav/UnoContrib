using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Drawing.Primitives;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	public class Floor : Entity
	{
		[Range(0, 2048)]
		public float QuadSize { get; set; }

		[Range(0, 100)]
		public int TexCoordFactor { get; set; }

		private texture2D texture;

		public Floor()
		{
			texture = import Texture2D("../Assets/water_texture.jpg");
		}

		protected override void OnDraw()
		{
			draw DefaultShading, Quad
			{
				DiffuseMap: texture;
				TexCoord: prev * TexCoordFactor;
				Translation: Transform.Position;
				Size: float2(QuadSize);
			};
		}
	}
}
