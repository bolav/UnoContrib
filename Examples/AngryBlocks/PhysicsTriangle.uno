using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;
using Uno.Physics.Box2D;

namespace AngryBlocks
{
	public class PhysicsTriangle : PhysicsEntity
	{
		public float2 Dimensions
		{
			get { return (Body.GetFixtureList().GetShape() as PolygonShape)._vertices[2]; }
			set 
			{ 
				var shape = (Body.GetFixtureList().GetShape() as PolygonShape);
				if(value.X > 0)
				{
					shape.Set(new float2[] { float2(0,0), float2(value.X, 0), float2(0, value.Y) }, 3); 
				} else {
					shape.Set(new float2[] { float2(value.X * -1.0f, 0), float2(value.X * -1.0f, value.Y), float2(0,0) }, 3); 
				}
			}
		}

		protected override Uno.Physics.Box2D.Shape GetShape()
		{
			var shape = new PolygonShape();
			shape.Set(new float2[] { float2(0,0), float2(0, 1), float2(1, 0) }, 3);
			return shape;
		}
		
		public override void Draw(Fuse.DrawContext dc)
		{
			if(Body.GetFixtureList() == null) return;

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