using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace RainForest
{
	/**
	* ITileMapLoader
	*
	* Defines the interface that is used by TileListGenerator to generate
	* tiles based on the tile type.
	*/
	public interface ITileLodMapLoader
	{
		Tile[][] GetAllLodTiles();
	}
}