using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Content;
using Uno.Content.Models;

namespace BlockGame
{
	class GameCamera : Fuse.Entities.Scene
	{
		public static readonly GameCamera Instance = new GameCamera();

		//public float ZFar = 10000;
		//public float FovDegrees = 60;
		public float Aspect;

		public GameCamera()
		{
			//this.Transform.Position = float3(0,0,0);
			//this.Transform.LookAt(float3(0,0,0), float3(0,0,1));
			//this.ZFar = 10000;
			//this.FovDegrees = 60;
			Components.Add(new Transform());
			Components.Add(new Frustum());
			this.Transform.Position = float3(0,0,0);
			this.Transform.LookAt(float3(0,0,0), float3(0,0,1));
			this.Frustum.FovDegrees = 60;
			this.Frustum.ZFar = 10000;
		}
		
		protected override void OnInitialize()
		{
			base.OnInitialize();
		}

		
		public void Update()
		{

		}

		float ShakeTime = 0;
		float ShakeAmount = 0;

		public void FixedUpdate()
		{
			///*

			if(ShakeAmount > 0)
			{
				ShakeAmount -= (float)Application.Current.FixedInterval;
			}else{
				ShakeAmount = 0;
			}
			
			this.Transform.Position = float3(1400, PlayerPedal.Instance.Transform.Position.Y *0.3f,0);
			this.Transform.LookAt(float3(0,0,0), float3(0,0,1));
			this.Aspect = Application.Current.GraphicsContext.Viewport.Size.Ratio;
			ShakeCamera();
			this.Transform.Position = Math.Lerp(this.Transform.Position, float3(0,-1500,1000), (float)Application.Current.FixedInterval *2);
			//*/
		}

		public void ShakeTheCamera(float amount)
		{
			ShakeAmount = amount;
		}

		void ShakeCamera()
		{
			float3 newPosition = this.Transform.Position;
			newPosition.X += Math.Sin(Math.Sin((float)Application.Current.FixedTime*50))*10 * ShakeAmount;
			newPosition.Y += Math.Sin(Math.Sin((float)Application.Current.FixedTime*50))*10 * ShakeAmount;
			newPosition.Z += Math.Sin(Math.Sin((float)Application.Current.FixedTime*50))*10 * ShakeAmount;
			this.Transform.Position = newPosition;
		}
	}
}