using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;
using Uno.Designer;

namespace RainForest
{
	public class CameraOpacityAdjustingNode : Node
	{
		public float Opacity { get; set; }

		public float3 Position { get; set; }

		[Uno.Designer.Range(100.0f, 1000.0f)]
		public float HeightThreshold { get; set; }

		[Uno.Designer.Range(100.0f, 1000.0f)]
		public float HeightSpeedFactor { get; set; }
		
		public CameraOpacityAdjustingNode()
		{
			Update += Updated;
		}

		void Updated(object sender, SceneEventArgs args)
		{
			Opacity = Math.Min(1.0f, (Position.Z - HeightThreshold) / HeightSpeedFactor);
		}
	}
}