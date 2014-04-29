using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	public enum TileType
	{
		Water, Forest, WTF /* What a terrible failure... */
	}

	public class Tile
	{
		public int2 Position { get; set; }

		public int Size { get; set;}

		public TileType Type { get; set; }

		public Recti Rectangle
		{
			get
			{
				return new Recti(Position, int2(Size));
			}
			set
			{
				Position = value.Position;
				Size = value.Size.X;
			}
		}

		public float3 Color
		{
			get
			{
				switch (Type)
				{
					case TileType.Water : 		// blue
						return float3(0, 0, 1);
					case TileType.Forest : 		// green
						return float3(0, 1, 0);
					default:					// hot pink
						return float3(1, 0, 1);
				}
			}
		}

		public Tile()
		{
		}

		public Tile(int2 position, int size, TileType type)
		{
			Position = position;
			Size = size;
			Type = type;
		}

		public override string ToString()
		{
			return "Tile[position=(" + Position + "),size=" + Size + ",type=" + Type + "]";
		}

	}
}