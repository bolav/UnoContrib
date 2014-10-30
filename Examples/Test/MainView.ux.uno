using Fuse.Shapes;
using Fuse.Entities;
using Fuse.Time;
using Fuse;
using Uno.Collections;
using Uno.Math;
using Fuse.Triggers;
using Uno.Physics.Box2D;


public partial class MainView
{

	protected override void OnDraw (Fuse.DrawContext dc) {
		base.OnDraw(dc);
	// protected override void OnDraw () {
		// base.OnDraw();
		World.Current.DrawDebugData();
	}

	Body body;
	public MainView()
	{
		InitializeUX();
		Update += OnUpdate;

		var bodyDef = new BodyDef();
		bodyDef.position = float2(0, -10.0f);
		var groundBody = World.Current.CreateBody(bodyDef);
		var groundBox = new PolygonShape();
		groundBox.SetAsBox(50.0f, 10.0f);
		groundBody.CreateFixture(groundBox, 0.0f);
		
		var bodyDef2 = new BodyDef();
		bodyDef2.type = BodyType.Dynamic;
		bodyDef2.position = float2(0.0f, 50.0f);
		body = World.Current.CreateBody(bodyDef2);
		var shape = new CircleShape();
		shape._radius = 2.0f;
		// var dynamicBox = new PolygonShape();
		// dynamicBox.SetAsBox(1.0f, 1.0f);
		
		var fixtureDef = new FixtureDef();
		fixtureDef.shape = shape;
		fixtureDef.density = 1.0f;
		fixtureDef.friction = 0.3f;
		body.CreateFixture(fixtureDef);

		World.Current.DebugDraw = new AngryBlocks.DebugRenderer();
		World.Current.DebugDraw.AppendFlags(DebugDrawFlags.Shape);
		World.Current.DebugDraw.AppendFlags(DebugDrawFlags.Joint);
	}
	
	double _interval = 1.0 / 60.0;
	double _lockTimer = 0;	
	// protected virtual void OnUpdate() {
	public void OnUpdate (object o1, Uno.EventArgs args) {
		while (_lockTimer < Time.FrameTime) {
			FixedUpdate();
			_lockTimer += _interval;
		}
	}

	public void FixedUpdate () {
		World.Current.Step((float) _interval,(int) 4, 4);
		InvalidateVisual();
		debug_log body.GetPosition() + " a:" + body.GetAngle();
	}
}