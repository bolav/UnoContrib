using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	/**
	* Rainforest Tile Lod Map Loader
	*
	* Reads the .lod files stored in the Assets/MapLODs/ folder and
	* builds up a map with various levels of details.
	*
	* The .lod file format contains every tile in the map, in one particular
	* level of detail, determined from the filename.
	*
	* The lower the file number, the lower the resolution and as such the level
	* of detail. I.e. 2 looks worse then 6.
	*
	* Each tile is a single byte, and as such number of tiles is equal to the length
	* of the file.
	*
	* Every byte contains the following data:
	* [5 bit - height][3 bit - tile type]
	*
	*/
	public class RainforestTileLodMapLoader : ITileLodMapLoader
	{
		private List<Buffer> fileContents = new List<Buffer>();

		private Tile[][] tileArray;

		public RainforestTileLodMapLoader()
		{
			LoadFiles();
			BuildTileArray();
		}

		public Tile[][] GetAllLodTiles()
		{
			return tileArray;
		}

		private void LoadFiles()
		{
			// The three lowest LODs should be 2. This is because the level
			// of detail at this level is so low that any lower values then this will
			// end up with it just being water, and we don't render the water, we have
			// a seperate mesh for that.
			for(int i = 0; i < 3; i++)
			{
				fileContents.Add(import Buffer("../Assets/MapLODs/2.lod"));
			}

			fileContents.Add(import Buffer("../Assets/MapLODs/3.lod"));
			fileContents.Add(import Buffer("../Assets/MapLODs/4.lod"));
			fileContents.Add(import Buffer("../Assets/MapLODs/5.lod"));
			fileContents.Add(import Buffer("../Assets/MapLODs/6.lod"));
			fileContents.Add(import Buffer("../Assets/MapLODs/7.lod"));
		}

		private void BuildTileArray()
		{
			tileArray = new Tile[fileContents.Count][];

			for(var i = 0; i < fileContents.Count; i++)
			{
				tileArray[i] = ParseLodFile(fileContents[i]);
			}
		}

		private Tile[] ParseLodFile(Buffer buffer)
		{
			int numberOfTiles = buffer.SizeInBytes;

			Tile[] result = new Tile[numberOfTiles];

			for(int i = 0; i < numberOfTiles; i++)
			{
				byte val = buffer.GetByte(i);

				TileType tileType = GetTileType(val);

				// We could set the position and the size of the tile here. But,
				// since were not going to use that information, we just ignore it.
				//
				// This information will be filled in in the TileListGenerator
				result[i] = new Tile(int2(0), 0, tileType);
			}

			return result;
		}

		private TileType GetTileType(int val)
		{
			var id = val & 0x7;

			switch(id)
			{
				case 0:
					return TileType.Water;
				case 1:
					return TileType.Forest;
				default:
					return TileType.WTF;
			}
		}
	}
}