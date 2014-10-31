using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;
using Uno.Physics.Box2D;
using Fuse;

namespace AngryBlocks
{
	public class AngryBlocks : Fuse.Element
	{
		Body floorBody, cannonBody, cannonBall;

		private List<Body> bodiesToDestroy = new List<Body>();

		private float2 mousePosWorld;
		protected float2 MousePosWorld { get { return mousePosWorld; } }

		public AngryBlocks()
		{
			CreateFloor();
			CreateCannon();

			World.Current.DebugDraw = new DebugRenderer();
			World.Current.DebugDraw.AppendFlags(DebugDrawFlags.Shape);
			World.Current.DebugDraw.AppendFlags(DebugDrawFlags.Joint);
			World.Current.ContactListener = new DestroyContactListener(this);

			Update += OnUpdate;
		}

		void CreateFloor()
		{
			var bodyDef = new BodyDef();
			bodyDef.position = float2(0, -40.0f);

			floorBody = World.Current.CreateBody(bodyDef);

			var shape = new PolygonShape();
			shape.SetAsBox(100.0f, 10.0f);

			var fixtureDef = new FixtureDef();
			fixtureDef.shape = shape;
			fixtureDef.density = 1.0f;
			fixtureDef.friction = 0.9f;

			floorBody.CreateFixture(fixtureDef);
		}

		private void CreateCannon()
		{
			var bodyDef = new BodyDef();
			bodyDef.position = float2(-60.0f, -27.5f);
			bodyDef.userData = 1;

			cannonBody = World.Current.CreateBody(bodyDef);

			var shape = new PolygonShape();
			shape.SetAsBox(5.0f, 2.0f);

			var fixtureDef = new FixtureDef();
			fixtureDef.shape = shape;
			fixtureDef.density = 1.0f;

			cannonBody.CreateFixture(fixtureDef);
		}

		private void FireBall()
		{
			debug_log "Fire ball!";
			var ball = CreateBall();

			var direction = MousePosWorld - cannonBody.Position;
			var directionNormalized = Vector.Normalize(direction);
			var force = Vector.Length(direction) * 75.0f + 500;
			debug_log "Length: " + Vector.Length(direction) + ", Force: " + force;

			ball.ApplyForce(directionNormalized * force, ball.GetWorldCenter());
		}

		private Body CreateBall()
		{
			var bodyDef = new BodyDef();
			bodyDef.type = BodyType.Dynamic;

			var direction = Vector.Normalize(MousePosWorld - cannonBody.Position);
			bodyDef.position = cannonBody.Position + direction * 8.0f;

			var body = World.Current.CreateBody(bodyDef);

			var fixtureDef = new FixtureDef();

			var shape = new PolygonShape();
			shape.SetAsBox(1.0f, 1.0f);

			fixtureDef.shape = shape;
			fixtureDef.density = 0.9f;
			fixtureDef.friction = 0.1f;
			fixtureDef.userData = 1000000.0f;

			body.CreateFixture(fixtureDef);

			return cannonBall = body;
		}

		double _interval = 1.0 / 60.0;
		double _lockTimer = 0;
		protected void OnUpdate (object sender, Uno.EventArgs args) {
			while (_lockTimer < Application.Current.FrameTime) {
				FixedUpdate();
				_lockTimer += _interval;
				InvalidateVisual();
			}
		}

		protected void FixedUpdate()
		{

			if(!defined(Designer)) {
				World.Current.Step((float) _interval,(int) 4, 4);

				foreach(var body in bodiesToDestroy)
				{
					World.Current.DestroyBody(body);
				}
				bodiesToDestroy.Clear();
			}

			UpdateMousePosition();

			float2 pos = MousePosWorld - cannonBody.Position;
			cannonBody.Rotation = Math.Atan2(pos.Y, pos.X);

			if(Input.IsPointerPressedTriggered())
			{
				FireBall();
			}

		}

		private void UpdateMousePosition()
		{
			float2 pos = FromAbsolute(Input.PointerCoord);
			float2 center = DrawContext.Current.VirtualResolution / 2;

			float2 posClip = (pos - center) / center;
			posClip.X *= DrawContext.Current.Aspect;
			posClip.Y *= -1.0f;
			mousePosWorld = Box2DMath.UnoToBox2D(posClip);
		}

		protected override void OnDraw(DrawContext dc)
		{
			World.Current.DrawDebugData();
			World.Current.DebugDraw.DrawSegment(MousePosWorld, cannonBody.Position, float4(1, 1, 0, 1), float2(0));
		}

		public class DestroyContactListener : IContactListener
		{
			private AngryBlocks b;

			public DestroyContactListener(AngryBlocks blocks)
			{
				b = blocks;
			}

			public void BeginContact(Contact contact) {}
	        public void EndContact(Contact contact) {}
	        public void PreSolve(Contact contact, ref Manifold oldManifold) {}
	        public void PostSolve(Contact contact, ref ContactImpulse impulse)
			{
				var fixtureA = contact.GetFixtureA();
				var fixtureB = contact.GetFixtureB();
				
				if(	fixtureA.GetBody().GetBodyType() != BodyType.Dynamic ||
					fixtureB.GetBody().GetBodyType() != BodyType.Dynamic)
				{
					return;
				}

				CheckCollision(impulse, fixtureA);
				CheckCollision(impulse, fixtureB);
			}
			
			private void CheckCollision(ContactImpulse impulse, Fixture fixture)
			{
				if(!IsCannonBall(fixture) && NormalImpulseExceedsObjectMaxImpulse(impulse, fixture))
				{
					b.bodiesToDestroy.Add(fixture.GetBody());
				}	
			}
			
			private bool IsCannonBall(Fixture fixture)
			{
				return fixture.GetBody() == b.cannonBall;	
			}
			
			private bool NormalImpulseExceedsObjectMaxImpulse(ContactImpulse impulse, Fixture fixture)
			{
				return impulse.normalImpulses[0] > (float) fixture.GetUserData();	
			}
		}


	}
}