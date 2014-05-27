using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content;
using Uno.Content.Models;
using Uno.UI;

namespace PONG2D
{
	public class Ball : Node
	{
		Image _ballImage;

		[Inline]
		public Image BallImage
		{
			get { return _ballImage; }
			set
			{
				if (_ballImage != value)
				{
					_ballImage = value;
					ReSpwanBall();
				}

			}
		}

		public Rect BallRectangle
		{
			get { return new Rect(BallImage.Position, float2(BallImage.Width, BallImage.Height)); }
			set
			{
				BallImage.Position += value.Position;
				BallImage.Width = value.Size.X;
				BallImage.Height = value.Size.Y;
			}
		}

		public float2 BallVelocity
		{
			get;
			set;
		}
		
		public float2 Resolution
		{
			get { return Context.VirtualResolution; }
		}
		
		public Ball()
		{
			
		}

		public void ReSpwanBall()
		{
			var center = Context.VirtualResolution * 0.5f;
			BallImage.Position = float2(center.X - BallRectangle.Size.X, center.Y - BallRectangle.Size.Y);
		}

		protected override void OnUpdate()
		{
			base.OnUpdate();
			if (BallImage != null)
			{
				BallImage.Position += BallVelocity;
				if (BallRectangle.Position.X > (Resolution.X - BallImage.Width) ||
					BallRectangle.Position.X < 0)
				{
					ReSpwanBall();
				}
				
				if (BallRectangle.Position.Y > (Resolution.Y - BallImage.Height) ||
					BallRectangle.Position.Y < 0)
				{
					BallVelocity = float2(BallVelocity.X, BallVelocity.Y * -1f);
				}
			}

		}

	}
}