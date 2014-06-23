using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace BlockGame
{
	class TargetBlock : GameEntity
	{
		public static readonly List<TargetBlock> TargetBlocks = new List<TargetBlock>();

		public static void ResetAll()
		{
			foreach (var targetBlock in TargetBlocks) targetBlock.IsActive = true;
		}

		apply ShadingBlock;
		apply Model("Data/targetBlock.FBX");

		bool isActive = true;
		public bool IsActive
		{
			get { return isActive; }
			set
			{
				if (value != isActive)
				{
					isActive = value;
					if (!isActive)
					{
						App.IncrementScore();

						bool allKnockedDown = true;
						foreach (var targetBlock in TargetBlocks)
						{
							if (targetBlock.IsActive)
							{
								allKnockedDown = false;
								break;
							}
						}
						if (allKnockedDown) ResetAll();
					}
				}
			}
		}

		public static TargetBlock Create(float3 location)
		{
			var ret = new TargetBlock(location);
			TargetBlocks.Add(ret);
			return ret;
		}

		TargetBlock(float3 location)
		{
			Transform.Position = location;
			Collider.Maximum = float3(26,65,23);
			Collider.Minimum = float3(-26,-65,-23);
		}

		public void Deactivate()
		{
			IsActive = false;
		}

		public override void Draw()
		{
			draw this
			{
				Camera: GameCamera.Instance;
				ReflectionAmount : 0.5f;
				PixelColor : prev * Math.Lerp(float4(.45f,.45f,.45f,1),(float4(Vector.Normalize(WorldPosition),1) + 0.5f),DeactivateLerp);
				Translation: this.Transform.Position;
			};
		}

		float DeactivateLerp = 1;

		public override void FixedUpdate()
		{
			if (IsActive)
			{
				DeactivateLerp = Math.Lerp(DeactivateLerp,1, (float)Application.Current.FixedInterval * 1);
				Transform.Position = Math.Lerp(Transform.Position, float3(0, Transform.Position.Y, Transform.Position.Z), (float)Application.Current.FixedInterval * 5);
			}
			else
			{
				DeactivateLerp = Math.Lerp(DeactivateLerp,0, (float)Application.Current.FixedInterval * 5);
				Transform.Position = Math.Lerp(Transform.Position, float3(-520, Transform.Position.Y, Transform.Position.Z), (float)Application.Current.FixedInterval * 12);
			}
		}
	}
}