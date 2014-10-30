using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;
using Uno.Physics.Box2D;
using AngryBlocks.Box2DMath;
using Fuse.Designer;
using Fuse;

namespace AngryBlocks
{
	public class PhysicsBall : PhysicsEntity
	{
		public float Radius
		{
			get { return (Body.GetFixtureList().GetShape() as CircleShape)._radius; }
			set { (Body.GetFixtureList().GetShape() as CircleShape)._radius = value; }
		}

		protected override Uno.Physics.Box2D.Shape GetShape()
		{
			var shape = new CircleShape();
			shape._radius = 2.0f;
			return shape;
		}
		
		[Color]
		public float3 Color { get; set; }
		
		public PhysicsBall() : base()
		{
			Color = float3(1, 1, 0);
		}

		public void Draw(Fuse.DrawContext dc)
		{
			if(Body.GetFixtureList() == null) return;

			draw RenderBox2DAsQuad
			{
				Box2DBodyPosition: Position;
				Box2DBodyRotation: Rotation;
				Box2DQuadSize: float2(Radius * 2);
				
				BlendEnabled: true;
				BlendSrc: BlendOperand.SrcAlpha;
				BlendDst: BlendOperand.OneMinusSrcAlpha;
				
				float CircleIntensity: Math.Step(Vector.Length(pixel TexCoord - float2(0.5f)), 0.5f);
				
				PixelColor: float4(Color, CircleIntensity < 0.5f ? 0 : 1);
			};

		}
	}
}