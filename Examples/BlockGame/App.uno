using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Geometry;
using Uno.Scenes;
using Uno.Scenes.Primitives;
using Uno.Content;
using Uno.Content.Models;
using Uno.Content.Fonts;

namespace BlockGame
{
    class App : Uno.Application
    {
		static private int Score = 0;
		static public void IncrementScore() { Score += 1; }
		static public void ResetScore() { Score = 0; }

		TextRenderer renderer = new TextRenderer(500, new SpriteFontShader());
		BitmapFont font = import SpriteFont("Data/Molot.otf", 30);

		List<GameEntity> entities = new List<GameEntity>();

		public override void Load()
		{
			// Create TargetBlocks at locations with spacing
			for (int y = 2; y < 6; y++)
			{
				for (int x = -4; x < 5; x++)
				{
					var targetBlock = TargetBlock.Create(float3(0,x*150,y*70));
					entities.Add(targetBlock);
				}
			}

			entities.Add(PlayerPedal.Instance);
			entities.Add(Ball.Instance);
		}

		public override void Update()
		{
			GameCamera.Instance.Update();
		}

		public override void FixedUpdate()
		{
			foreach (var entity in entities) entity.FixedUpdate();

			GameCamera.Instance.FixedUpdate();
		}

		apply ShadingBlock;

        public override void Draw()
        {
			ClearColor = float4(0,0,0,1);

			foreach (var entity in entities) entity.Draw();

			draw this
			{
				Camera: GameCamera.Instance;
				apply Model("Data/roomModel.FBX");
				PixelColor : prev * float4(.35f,.35f,.35f,1);
			};

			draw this
			{
				Camera: GameCamera.Instance;
				apply Model("Data/roomDecor.FBX");
				ReflectionAmount : 0.3f;
				PixelColor : prev * float4(.45f,.45f,.45f,1);
			};

			renderer.Begin(font);
			renderer.WriteString(float2(Application.Current.GraphicsContext.Viewport.Size.X * 0.5f,100), Score.ToString());
			renderer.End();
        }
    }
}