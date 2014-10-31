using Uno;
using Uno.Collections;
using Uno.Graphics;
using Fuse.Designer;
using Uno.Content;
using Uno.Content.Models;
using Fuse;
using Uno.Physics.Box2D;

using TowerBuilder.Box2DMath;

namespace TowerBuilder
{
	public abstract class TestBed : Node
	{

		protected World World
		{
			get { return PhysicsWorld.World; }
		}

		[Group("World")]
		public float2 Gravity
		{
			get { return World.Gravity; }
			set { World.Gravity = value; }
		}

		private MouseJoint mouseJoint;
		private Body mouseJointGroundBody;

		private float2 mousePosWorld;
		protected float2 MousePosWorld { get { return mousePosWorld; } }

		public void ResetWorld()
		{
			OnInitialize();
		}

		public override float2 ParentToLocal(float2 f) {
			return f;
		}
		public override float2 LocalToParent(float2 f) {
			return f;
		}
		public override void Draw(DrawContext dc) {
			TowerBuilder.PhysicsWorld.World.DrawDebugData();
		}

		protected override void OnInitialize()
		{
			debug_log "On Initialize";
			PhysicsWorld.World = new World(float2(0, -10.0f), false);
			World.DebugDraw = new TowerDebugDrawer();
			World.DebugDraw.AppendFlags(DebugDrawFlags.Shape);
			World.DebugDraw.AppendFlags(DebugDrawFlags.Joint);

			mouseJointGroundBody = World.CreateBody(new BodyDef());

			OnInitializeTestBed();
			Update += OnUpdate;

			base.OnInitialize();
		}

		protected abstract void OnInitializeTestBed();



		double _interval = 1.0 / 60.0;
		double _lockTimer = 0;
		protected void OnUpdate (object sender, Uno.EventArgs args) {
			while (_lockTimer < Application.Current.FrameTime) {
				FixedUpdate();
				_lockTimer += _interval;
			}
		}

		protected void FixedUpdate()
		{
			if(World == null) return;

			if(!defined(Designer)) {
				World.Step((float) _interval,(int) 4, 4);
			}
				
			float2 pos = Input.PointerCoord;
			pos *= DrawContext.Current.Aspect;
			float2 center = DrawContext.Current.VirtualResolution / 2;

			float2 posClip = (pos - center) / center;

			posClip.X *= DrawContext.Current.Aspect;
			posClip.Y *= -1.0f;
			mousePosWorld = Box2DMath.UnoToBox2D(posClip);

			if(Input.IsPointerPressed() && mouseJoint == null)
			{
				startMouseJoint();
			}

			if(Input.IsPointerPressed() && mouseJoint != null)
			{
				mouseJoint.SetTarget(mousePosWorld);
			}

			if(!Input.IsPointerPressed() && mouseJoint != null)
			{
				endMouseJoint();
			}
			
		}

		float2 point;
		Fixture fixture;
		private void startMouseJoint()
		{
			// Make a small box.
		    var aabb = new AABB();
		    var d = 0.01f;
		    aabb.lowerBound = float2(mousePosWorld.X - d, mousePosWorld.Y - d);
		    aabb.upperBound =float2(mousePosWorld.X + d, mousePosWorld.Y + d);

			fixture = null;
			point = mousePosWorld;
		    // Query the world for overlapping shapes.
		    World.QueryAABB(AABBCallback, ref aabb);
		}

		private bool AABBCallback(FixtureProxy proxy)
		{
			debug_log "Called AABB callback - " + proxy;

			if(proxy.fixture.GetBody().GetBodyType() == BodyType.Static)
				return true;
			if(!proxy.fixture.TestPoint(point))
				return true;

			var body = proxy.fixture.GetBody();
	        var md = new MouseJointDef();
			md.bodyA = mouseJointGroundBody;
			md.bodyB = body;
			md.target = mousePosWorld;
			md.maxForce = 1000 * body.GetMass();
			md.collideConnected = true;

	        mouseJoint = (MouseJoint) World.CreateJoint(md);
	        body.SetAwake(true);

			return false;
		}

		private void endMouseJoint()
		{
			World.DestroyJoint(mouseJoint);
			mouseJoint = null;
		}

		protected void OnDraw()
		{
			// protected override void OnDraw()
			World.DrawDebugData();
			
			// base.OnDraw();
		}
	}
}