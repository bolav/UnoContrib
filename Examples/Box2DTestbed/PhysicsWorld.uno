using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;

using Uno.Physics.Box2D;

namespace TowerBuilder
{
	public static class PhysicsWorld
	{
		public static World World = new World(float2(0, -10.0f), false);
	}
}