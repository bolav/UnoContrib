using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	public class CameraState
	{
		public float3 Position { get; set; }

		public float Radius { get; set; }
		public float RotationSpeed { get; set; }

		public float3 Target { get; set; }

		public float3 Sample(float time)
		{
			return Position + float3(
				Math.Cos(time * RotationSpeed) * Radius,
				Math.Sin(time * RotationSpeed) * Radius,
				0);
		}
	}
}
