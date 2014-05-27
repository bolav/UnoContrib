using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Designer;
using Uno.Content;
using Uno.Content.Models;

namespace PONG2D
{
	public class Devider : Node
	{
		
		public float2 DeviderSize { get; set; }
		
		public float DeviderOffset { get; set; }
		
		[Range(0,100)]
		public int DeviderCount { get; set; }
		
		[Color]
		public float4 DeviderColor { get; set; }
		
		float2 center = Context.VirtualResolution * 0.5f;
		
		protected override void OnDraw()
		{
			base.OnDraw();
			
			for (int i = 0; i < DeviderCount; i++)
			{
				Uno.Drawing.RoundedRectangle.Draw(float2(center.X - DeviderSize.X * 0.5f, (DeviderSize.Y + DeviderOffset) * i), DeviderSize, DeviderColor, 0f);
			}
			
		}

		
	}
}