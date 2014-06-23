using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace BlockGame
{
	class PlayerPedal : GameEntity
	{
		public static readonly PlayerPedal Instance = new PlayerPedal();

		const float MoveSpeed = 2000;
		const float AccelerationSpeed = 4;
		const float ReverseAccelerationSpeed = 20;

		bool MovingLeft = false;
		bool MovingRight = false;

		private float movementEasing = 0;
		public float MovementEasing
		{
			set { movementEasing = Math.Clamp(value,-1,1); }
			get { return movementEasing; }
		}

		public PlayerPedal()
		{
			Transform.Position = float3(0,0,-600);
			Collider.Minimum = float3(25,-147,-19);
			Collider.Maximum = float3(-25,147,19);

			Application.Current.Window.KeyDown += OnKeyDown;
			Application.Current.Window.KeyUp += OnKeyUp;
		}

		void OnKeyDown(object sender, Uno.Platform.KeyEventArgs args)
		{
			if(args.Key == Uno.Platform.Key.Left || args.Key == Uno.Platform.Key.A) MovingLeft = true;
			if(args.Key == Uno.Platform.Key.Right || args.Key == Uno.Platform.Key.D) MovingRight = true;
			if(args.Key == Uno.Platform.Key.Space) Ball.Instance.ReleaseBall();
		}

		void OnKeyUp(object sender, Uno.Platform.KeyEventArgs args)
        {
            if(args.Key == Uno.Platform.Key.Left || args.Key == Uno.Platform.Key.A) MovingLeft = false;
			if(args.Key == Uno.Platform.Key.Right || args.Key == Uno.Platform.Key.D) MovingRight = false;
        }

		apply ShadingBlock;

		public override void Draw()
		{
			draw this
			{
				Camera: GameCamera.Instance;
				apply Model("Data/playerPadel.FBX");
				ReflectionAmount : 1;
				Translation: this.Transform.Position;
			};
		}

		public override void FixedUpdate()
		{
			 Move();
		}

		void Move()
		{
			if(MovingLeft || MovingRight)
			{
				if(MovingLeft) MovementEasing -= MovementEasing < 0 ? (float)Application.Current.FixedInterval * AccelerationSpeed : (float)Application.Current.FixedInterval * ReverseAccelerationSpeed;
				if(MovingRight) MovementEasing += MovementEasing > 0 ? (float)Application.Current.FixedInterval * AccelerationSpeed : (float)Application.Current.FixedInterval * ReverseAccelerationSpeed;
			}
			else
				MovementEasing = Math.Lerp(MovementEasing, 0, (float)Application.Current.FixedInterval * 20);

			Transform.Position = float3(Transform.Position.X,Math.Clamp(Transform.Position.Y + (MovementEasing * (float)Application.Current.FixedInterval * MoveSpeed),-650,650), Transform.Position.Z);

			//Resets the SpeedEasing if the player pedal is at either of the edges.
			if(Transform.Position.Y == -650 || Transform.Position.Y == 650)
				MovementEasing = 0;
		}
	}
}