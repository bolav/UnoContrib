using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

using Uno.Physics.Box2D;

namespace AngryBlocks
{
	public abstract class PhysicsEntity : Node
	{
		protected Body Body { get; set; }

		public float2 Position
		{
			get { return Body.Position; }
			set { Body.Position = value; }
		}

		public float Rotation
		{
			get { return Math.RadiansToDegrees(Body.Rotation); }
			set { Body.Rotation = Math.DegreesToRadians(value); }
		}

		public BodyType BodyType
		{
			get { return Body.GetBodyType(); }
			set { Body.SetType(value); }
		}

		public float MaxImpulse
		{
			get { return (float) Body.GetFixtureList().GetUserData(); }
			set { Body.GetFixtureList().SetUserData(value); }
		}

		public PhysicsEntity()
		{
			var bodyDef = new BodyDef();
			bodyDef.type = BodyType.Static;
			bodyDef.position = float2(0);

			Body = World.Current.CreateBody(bodyDef);

			var fixtureDef = new FixtureDef();
			fixtureDef.shape = GetShape();
			fixtureDef.density = 0.1f;
			fixtureDef.friction = 0.95f;
			fixtureDef.userData = 20.0f;

			Body.CreateFixture(fixtureDef);
		}

		protected abstract Shape GetShape();


	}
}