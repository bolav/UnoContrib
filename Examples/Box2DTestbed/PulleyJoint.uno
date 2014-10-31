using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;
using Uno.Physics.Box2D;

using TowerBuilder.Box2DMath;
namespace TowerBuilder
{
	public class PulleyJoint : TestBed
	{
		Body body1, body2;

		public float FloorHeight = -30;
		public float FloorWidth = 40;

		public float PulleyHeight = 4.0f;
		public float PulleyWidth = 1.0f;

		public float AnchorX = 15.0f;
		public float AnchorWireLength = 22.0f;
		public float AnchorYOffset = 0.0f;

		protected override void OnInitializeTestBed()
		{
	        var bd = new BodyDef();
	        var ground = World.CreateBody(bd);

	        var edge = new EdgeShape();
	        edge.Set(float2(-FloorWidth, FloorHeight), float2(FloorWidth, FloorHeight));

	        ground.CreateFixture(edge, 0.0f);

	        var circle = new CircleShape();
	        circle._radius = 2.0f;

	        circle._p = float2(-AnchorX,AnchorYOffset + PulleyHeight + AnchorWireLength);
	        ground.CreateFixture(circle, 0.0f);

	        circle._p = float2(AnchorX, AnchorYOffset + PulleyHeight + AnchorWireLength);
	        ground.CreateFixture(circle, 0.0f);

	        var shape = new PolygonShape();
	        shape.SetAsBox(PulleyWidth, PulleyHeight);

	        bd = new BodyDef();
	        bd.type = BodyType.Dynamic;

	        bd.position = float2(-AnchorX, AnchorYOffset);
	        body1 = World.CreateBody(bd);
	        body1.CreateFixture(shape, 5.0f);

	        bd.position = float2(AnchorX, AnchorYOffset);
	        body2 = World.CreateBody(bd);
	        body2.CreateFixture(shape, 5.0f);

	        var pulleyDef = new PulleyJointDef();
	        var anchor1 = float2(-AnchorX, AnchorYOffset + PulleyHeight);
	        var anchor2 = float2(AnchorX, AnchorYOffset + PulleyHeight);
	        var groundAnchor1 = float2(-AnchorX, AnchorYOffset + PulleyHeight + AnchorWireLength);
	        var groundAnchor2 = float2(AnchorX, AnchorYOffset + PulleyHeight + AnchorWireLength);
	        pulleyDef.Initialize(body1, body2, groundAnchor1, groundAnchor2, anchor1, anchor2, 1.5f);

	        World.CreateJoint(pulleyDef);
		}

	}
}