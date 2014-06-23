using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Geometry;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace BlockGame
{
	class Ball : GameEntity
	{
		public static readonly Ball Instance = new Ball(float3(0,0,-200));

		enum BallState
		{
			Resting,
			Moving,
			Dead
		}
		BallState CurrentState = BallState.Resting;

		const float PedalAccel = 80;
		const float MinSpeed = 1000;
		const float MaxSpeed = 5000;
		const int StartingHealth = 3;

		private int Health = StartingHealth;
		private float3 MoveDirection = float3(0);

		private float speed = MinSpeed;
		public float Speed
		{
			get { return speed; }
			set { speed = Math.Clamp(value, MinSpeed, MaxSpeed); }
		}

		Ball(float3 location)
		{
			Transform.Position = location;
			MoveDirection = float3(0,0,1);
		}

		Uno.Geometry.Sphere CollisionSphere = new Uno.Geometry.Sphere(float3(0,0,0),25);

		// returns a Sphere aligned with location/rotation/scale of the entity
		public Uno.Geometry.Sphere GetTransformedCollisionSphere()
		{
			return Uno.Geometry.Sphere.Transform(CollisionSphere, Transform.Absolute);
		}

		apply ShadingBlock;
		apply Uno.Scenes.Primitives.Sphere;
		Radius : 25;

		public override void Draw()
		{
			if(CurrentState != BallState.Dead)
			{
				draw this
				{
					Camera: GameCamera.Instance;
					Translation: this.Transform.Position;
					ReflectionAmount : 1;
				};
			}

			//Draws the indicator dot to the left
			draw this
			{
				PixelColor : float4(.3f,.4f,.7f,1);
				Camera: GameCamera.Instance;
				//World : this.Transform.Absolute;
				BlendEnabled : true;
				WorldPosition : float3(prev.X,-790,prev.Z);
				Translation: this.Transform.Position;
			};

			//Draws the indicator dot to the right
			draw this
			{
				PixelColor : float4(.3f,.4f,.7f,1);
				Camera: GameCamera.Instance;
				BlendEnabled : true;
				WorldPosition : float3(prev.X,prev.Y,449);
				Translation: this.Transform.Position;
			};

			//Draws the indicator dot above
			draw this
			{
				PixelColor : float4(.3f,.4f,.7f,1);
				Camera: GameCamera.Instance;
				BlendEnabled : true;
				WorldPosition : float3(prev.X,790,prev.Z);
				Translation: this.Transform.Position;
			};
		}

		public override void FixedUpdate()
		{
			switch (CurrentState)
			{
				case BallState.Resting: RestingState(); break;
				case BallState.Moving: MoveState(); break;
				case BallState.Dead: DieState(); break;
			}
		}

		void RestingState()
		{
			Transform.Position = PlayerPedal.Instance.Transform.Position + float3(0,0,50);
		}

		void MoveState()
		{
			MoveBall();
			CheckAndHandleCollisionWithTargetBlocks();
			CheckAndHandleCollisionWithPlayerPedal();
			CheckAndHandleCollisionWithLevelWalls();
		}

		void MoveBall()
		{
			// Checks to see if the ball is close to being horizontal,
			// at which point it will start moving the ball in a downwards direction.
			if (Vector.Dot(MoveDirection, float3(0,0,1)) > -0.5f && Vector.Dot(MoveDirection, float3(0,0,1)) < 0.5f)
				MoveDirection = Math.Lerp(MoveDirection, float3(0,0,-1), (float)Application.Current.FixedInterval *0.5f);

			// Adds MoveDirection and Speed to the current location of the ball.
			Transform.Position += (Vector.Normalize(MoveDirection) * (float)Application.Current.FixedInterval * Speed * float3(0,1,1));
		}

		void DieState()
		{
			if (--Health <= 0)
			{
				Health = StartingHealth;
				TargetBlock.ResetAll();
				App.ResetScore();
			}

			ResetBall();
		}

		public void ReleaseBall()
		{
			if (CurrentState == BallState.Resting) CurrentState = BallState.Moving;
		}

		public void ResetBall()
		{
			CurrentState = BallState.Resting;
			Speed = 600;
			MoveDirection = float3(0,0,1);
		}

		// Checks to see if Ball is colliding with any of the TargetBlocks,
		// handles it by finding the Normal surface the ball hits and reflects the MoveDirection based on it.
		void CheckAndHandleCollisionWithTargetBlocks()
		{
			for (int i = 0; i < TargetBlock.TargetBlocks.Count; i++)
			{
				if (Uno.Geometry.Collision.BoxIntersectsSphere(TargetBlock.TargetBlocks[i].GetTransformedCollider(), GetTransformedCollisionSphere()) && TargetBlock.TargetBlocks[i].IsActive)
				{
					TargetBlock.TargetBlocks[i].Deactivate();
					float Horizontal = TargetBlock.TargetBlocks[i].GetTransformedCollider().Center.Z < GetTransformedCollisionSphere().Center.Z ? -1.0f : 1.0f;
					float Vertical = TargetBlock.TargetBlocks[i].GetTransformedCollider().Center.Y < GetTransformedCollisionSphere().Center.Y ? -1.0f : 1.0f;

					float3 Normal = float3(0,Horizontal,Vertical)*0.5f;

					if (this.GetTransformedCollisionSphere().Center.Y > TargetBlock.TargetBlocks[i].GetTransformedCollider().Minimum.Y
						&& GetTransformedCollisionSphere().Center.Y < TargetBlock.TargetBlocks[i].GetTransformedCollider().Maximum.Y)
					{
						Normal = float3(0,0,Horizontal);
					}
					else if (this.GetTransformedCollisionSphere().Center.Z > TargetBlock.TargetBlocks[i].GetTransformedCollider().Minimum.Z
							 && GetTransformedCollisionSphere().Center.Y < TargetBlock.TargetBlocks[i].GetTransformedCollider().Maximum.Z)
					{
						Normal = float3(0,Vertical,0);
					}

					MoveDirection = Vector.Reflect(Vector.Normalize(MoveDirection), Vector.Normalize(Normal));
					GameCamera.Instance.ShakeTheCamera(0.3f);
				}
			}
		}

		// Checks to see if Ball is colliding with any of the PlayerPedal, handles it by getting the normal from the center of the pedal with a slight bias towards upwards movement to offset its length
		void CheckAndHandleCollisionWithPlayerPedal()
		{
			float3 NormalBias = float3(0,0,0.5f);

			if (Uno.Geometry.Collision.BoxIntersectsSphere(PlayerPedal.Instance.GetTransformedCollider(), GetTransformedCollisionSphere()))
			{
				if (this.GetTransformedCollisionSphere().Center.Z > PlayerPedal.Instance.GetTransformedCollider().Center.Z) // Check to see if the ball isn't under the pedal
				{
					float3 Normal = Vector.Normalize(PlayerPedal.Instance.GetTransformedCollider().Center - GetTransformedCollisionSphere().Center);
					MoveDirection = Vector.Normalize(-Normal + NormalBias);
					Speed += PedalAccel;
				}
			}
		}

		void CheckAndHandleCollisionWithLevelWalls()
		{
			Collision.PlaneIntersectionType LeftWall = Collision.PlaneIntersectsSphere(new Plane(float3(0,-800,0), float3(0,1,0)), GetTransformedCollisionSphere());
			Collision.PlaneIntersectionType RightWall = Collision.PlaneIntersectsSphere(new Plane(float3(0,800,0), float3(0,-1,0)), GetTransformedCollisionSphere());
			Collision.PlaneIntersectionType TopWall = Collision.PlaneIntersectsSphere(new Plane(float3(0,0,450), float3(0,0,-1)), GetTransformedCollisionSphere());
			Collision.PlaneIntersectionType BottomWall = Collision.PlaneIntersectsSphere(new Plane(float3(0,0,-800), float3(0,0,-1)), GetTransformedCollisionSphere());

			if (LeftWall == Collision.PlaneIntersectionType.Intersecting)
			{
				MoveDirection = Vector.Reflect(Vector.Normalize(MoveDirection), float3(0,1,0));
				GameCamera.Instance.ShakeTheCamera(0.6f);
			}

			if (RightWall == Collision.PlaneIntersectionType.Intersecting)
			{
				MoveDirection = Vector.Reflect(Vector.Normalize(MoveDirection), float3(0,-1,0));
				GameCamera.Instance.ShakeTheCamera(0.6f);
			}

			if (TopWall == Collision.PlaneIntersectionType.Intersecting)
			{
				MoveDirection = Vector.Reflect(Vector.Normalize(MoveDirection), float3(0,0,-1));
				GameCamera.Instance.ShakeTheCamera(0.6f);
			}

			if (BottomWall == Collision.PlaneIntersectionType.Intersecting)
			{
				CurrentState = BallState.Dead;
				GameCamera.Instance.ShakeTheCamera(1.4f);
			}
		}
	}
}