using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Geometry;
using Uno.Geometry.Collision;
using Uno.Designer;

namespace RainForest
{
	public class LODMathUtils
	{
		/**
		* This value is used to tweak the rectangles' height. We do this because the 3D
		* models aren't perfectly flat.
		*/
		internal static float2 FrustumHeightThresholds = float2(0.0f, 5.0f);

		public static bool FrustumContainsRecti(Uno.Geometry.Frustum frustum, Recti rectangle)
		{
			var min = float3(rectangle.Left, rectangle.Top,FrustumHeightThresholds.X );
			var max = float3(rectangle.Right, rectangle.Bottom, FrustumHeightThresholds.Y  );

			var box = new Uno.Geometry.Box(min, max);

			return FrustumContainsBox(frustum, box) != Collision.ContainmentType.Disjoint;
		}

		public static void CalculateShortestDistanceVectorToPoint(float3 point, Recti rectangle, out float3 closestDistanceVector, out float closestDistance)
		{
			var a = float3(rectangle.Right, rectangle.Bottom, 0);
			var b = float3(rectangle.Left, rectangle.Bottom, 0);
			var c = float3(rectangle.Left, rectangle.Top, 0);
			var d = float3(rectangle.Right, rectangle.Top, 0);

			var t1 = new Triangle(a, b, c);
			var t2 = new Triangle(a, c, d);

			float3 closest1, closest2;

			Collision.ClosestPointOnTriangleToPoint(t1, point, out closest1);
			Collision.ClosestPointOnTriangleToPoint(t2, point, out closest2);

			var distanceToPoint1 = Vector.Length(closest1 - point );
			var distanceToPoint2 = Vector.Length(closest2 - point);

			if(distanceToPoint1 > distanceToPoint2)
			{
				// distanceToPoint2 is the smallest of the two
				closestDistance = distanceToPoint2;
				closestDistanceVector = closest2;
			}
			else
			{
				// distanceToPoint2 is the smallest of the two
				closestDistance = distanceToPoint1;
				closestDistanceVector = closest1;
			}
		}
	}
}