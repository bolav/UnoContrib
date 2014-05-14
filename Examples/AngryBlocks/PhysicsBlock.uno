using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Physics.Box2D;

namespace AngryBlocks
{
	public class PhysicsBlock : PhysicsEntity
	{
		public float2 Dimensions
		{
			get { return (Body.GetFixtureList().GetShape() as PolygonShape)._vertices[2]; }
			set { (Body.GetFixtureList().GetShape() as PolygonShape).SetAsBox(value.X, value.Y); }
		}

		protected override Uno.Physics.Box2D.Shape GetShape()
		{
			var shape = new PolygonShape();
			shape.SetAsBox(1.0f, 1.0f);
			return shape;
		}

		protected override void OnDraw()
		{
			if(Body.GetFixtureList() == null) return;

			base.OnDraw();
			/* Requires working rotation
			draw RenderBox2DAsQuad
			{
				Box2DBodyPosition: Position;
				Box2DBodyRotation: Body.Rotation;
				Box2DQuadSize: Dimensions * 2;
				PixelColor: float4(1, 0, 0, 1);
			};
			*/
		}
	}
}