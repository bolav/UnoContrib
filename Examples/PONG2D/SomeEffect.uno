using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content;
using Uno.Content.Models;

namespace PONG2D
{
	[ComponentOf("Uno.Scenes.Entity")]
	public class SomeEffect : Component
	{
		protected override void OnDraw()
		{
			base.OnDraw();
			
			for (int x = 0; x < 10; x++)
			for (int y = 0; y < 10; y++)
			{
				draw DefaultShading, Uno.Scenes.Primitives.Sphere
				{
					Radius: 3f;
					Translation: float3(x * Transform.Scaling.X  * 2f, y * Transform.Scaling.Y * 2f, Math.Cos(y * 0.4f + x * 0.4f + (float)Time) * 40.0f) + Transform.Position;
					DiffuseColor: float3(x * 0.15f, Math.Sin(x * 0.4f + y * 0.4f + (float)Time) * 0.1f, y * 0.15f);
					Scale: Transform.Scaling;
				};
			}
		}
	}
}