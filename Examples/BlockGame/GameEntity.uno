using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Geometry;
using Uno.Content;
using Uno.Content.Models;
using Fuse.Entities;

namespace BlockGame
{
	class GameEntity
	{
		public Transform Transform = new Transform();
		public Box Collider = new Box(float3(0,0,0), float3(0,0,0));

		public GameEntity()
		{
			Transform.Position = float3(0,0,0);
		}

		// returns a Box aligned with location/rotation/scale of the entity
		public Box GetTransformedCollider()
		{
			return Box.Transform(Collider, Transform.Absolute);
		}

		public virtual void Draw() { }
		public virtual void Update() { }
		public virtual void FixedUpdate() { }
	}
}