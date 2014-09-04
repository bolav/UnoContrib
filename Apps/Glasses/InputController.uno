using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace Glasses
{
	public class InputController : Component
	{
		float spinAmount;
		float2 prevPos = float2(0,0);
		float2 deltaPos = float2(0,0);

		bool ButtonDown = false;
		
		public InputController()
		{
			Update += Updated;
		}

		protected override void OnHitTest(HitTestContext htc)
		{
			htc.Hit(Entity);
		}
		
		protected override void OnPointerDown(Uno.Scenes.PointerDownArgs args)
		{
			base.OnPointerDown(args);
			prevPos = args.PointCoord;
			ButtonDown = true;
			touchTime = (float)Application.Current.FrameTime;
		}

		protected override void OnPointerMove(Uno.Scenes.PointerMoveArgs args)
		{
			base.OnPointerMove(args);
			if (ButtonDown)
			{
				deltaPos = args.PointCoord - prevPos;
				prevPos = args.PointCoord;
				lerpSpeed = deltaPos.X;
			}
		}

		protected override void OnPointerUp(Uno.Scenes.PointerUpArgs args)
		{
			base.OnPointerUp(args);
			ButtonDown = false;
			releaseTime = (float)Application.Current.FrameTime;
		}

		float lerpSpeed;

		float touchTime = 0f;
		float releaseTime = -8f;
		protected void Updated(object sender, SceneEventArgs args)
		{
			if (!ButtonDown && ((float)Application.Current.FrameTime - releaseTime) > 8f) lerpSpeed = 4f;	// autorotate if noone has touched it for a while
			else lerpSpeed = Math.Lerp(lerpSpeed, 0, (float)Application.Current.FrameInterval * 0.3f);
			Transform.RotationDegrees = Transform.RotationDegrees + float3(0,0,lerpSpeed * (float)Application.Current.FrameInterval * 10f);
		}
	}
}
