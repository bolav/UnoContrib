using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;

namespace AngryBlocks
{
	public class Box2DMath
	{
		public static float Box2DToUno(float meters)
		{
			return 	meters * 0.025f;
		}

		public static float2 Box2DToUno(float2 meters)
		{
			return 	meters * 0.025f;
		}

		public static float3 Box2DToUno(float3 meters)
		{
			return 	meters * 0.025f;
		}

		public static float UnoToBox2D(float units)
		{
			return units * 40.0f;
		}

		public static float2 UnoToBox2D(float2 units)
		{
			return units * 40.0f;
		}

		public static float3 UnoToBox2D(float3 units)
		{
			return units * 40.0f;
		}
	}
}