
using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content.Models;

namespace RainForest
{
	public class CameraController : Node
	{
		public List<CameraState> States { get; private set; }

		[Range(0,2)]
		public float StateFader { get; set; }

		public Entity Camera { get; set; }

		public CameraController()
		{
			States = new List<CameraState>();
			
			Update += Updated;
		}

		public float Time
		{
			get { return (float) Uno.Application.Current.FrameTime; }
		}

		[Range(0.15f, 0.5f, 3)]
		public float TargetBias { get; set; }

		[Range(0.15f, 0.5f, 3)]
		public float PositionBias { get; set; }

		void Updated(object sender, SceneEventArgs args)
		{
			// Camera.Transform.RotationDegrees = float3(0);
			Camera.Transform.Position = CameraPosition;

			var newTarget = new Transform();
			newTarget.Position = CameraTarget;

			Camera.Transform.LookAt(newTarget, float3(0,0,1));
		}

		public float3 CameraTarget
		{
			get
			{
				var position = float3(0);

				for (int i = 0; i < States.Count; i++)
				{
					var weight = Math.Clamp(1.0f - Math.Abs(StateFader + TargetBias - i), 0, 1);
					position += States[i].Target * weight;
				}

				return position;
			}
		}

		public float3 CameraPosition
		{
			get
			{
				var p = float3(0);
				for (int i = 0; i < States.Count; i++)
				{
					var weight = Math.Clamp(1.0f - Math.Abs(StateFader + PositionBias - i), 0, 1);
					p += States[i].Sample(Time) * weight;
				}

				return p;
			}
		}
	}
}