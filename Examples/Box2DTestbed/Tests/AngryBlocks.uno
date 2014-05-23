using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

using Uno.Physics.Box2D;

using TowerBuilder.Box2DMath;

namespace TowerBuilder
{
	public class AngryBlocks : TestBed
	{
		Body floorBody, cannonBody;

		private List<Body> bodies = new List<Body>();
		private List<Body> bodiesToDelete = new List<Body>();

		private ContactListener contactListener;

		protected override void OnInitializeTestBed()
		{
			World.Gravity = float2(0, -10.0f);
			World.ContactListener = contactListener = new ContactListener(this);

			bodies.Clear();
			bodiesToDelete.Clear();

			CreateFloor();
			CreateCannon();
		}

		void CreateFloor()
		{
			var bodyDef = new BodyDef();
			bodyDef.position = float2(0, -40.0f);

			floorBody = World.CreateBody(bodyDef);

			var shape = new PolygonShape();
			shape.SetAsBox(100.0f, 10.0f);

			var fixtureDef = new FixtureDef();
			fixtureDef.shape = shape;
			fixtureDef.density = 1.0f;

			floorBody.CreateFixture(fixtureDef);
		}

		void CreateCannon()
		{
			var bodyDef = new BodyDef();
			bodyDef.position = float2(-60.0f, -27.5f);

			cannonBody = World.CreateBody(bodyDef);

			var shape = new PolygonShape();
			shape.SetAsBox(5.0f, 2.0f);

			var fixtureDef = new FixtureDef();
			fixtureDef.shape = shape;
			fixtureDef.density = 1.0f;

			cannonBody.CreateFixture(fixtureDef);
		}
		
		protected override void OnUpdate()
		{
			base.OnUpdate();
			
			float2 pos = MousePosWorld - cannonBody.Position;
			cannonBody.Rotation = Math.Atan2(pos.Y, pos.X);
		}
		
		protected override void OnDraw()
		{
			base.OnDraw();
			
			World.DebugDraw.DrawSegment(MousePosWorld, cannonBody.Position, float4(1, 1, 0, 1), float2(0));
		}

		public class ContactListener : IContactListener
		{
			private AngryBlocks b;
			public ContactListener(AngryBlocks b)
			{
				this.b = b;
			}

			public void BeginContact(Contact contact)
			{
				
			}

        	public void EndContact(Contact contact)  {}
			public void PreSolve(Contact contact, ref Manifold manifold) {}
			public void PostSolve(Contact contact, ref ContactImpulse impulse) {}
		}

	}
}