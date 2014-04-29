# Rainforest Tile Generator

This is a C# application that is used in company with the RainForest Uno/Realtime studio demo.

The purpose of the applications is to generate the Level of Detail files (.lod) used by the LOD engine. It does this using `RainforestLODLib`.

There is two applications useful for the user. `RainforestLODConsoleApp` takes a map and a integer value stating the number of LODs to generate.

`TestRenderer` renders a RAW image. This is the format used by `RainforestLODLib` to generate level of detail maps.

`RainforestLODLib` implements the same subdivision algorithm used in the normal Uno/RS application and also provides implementing classes for the tile type map.

## Running the applications
Open it in Visual Studio (2012+) like a normal solution. You have to set some local user settings correct in order to launch the application.

### For `RainforestLODConsoleApp` and `TestRenderer` 
Change the Debug working directory to `RainForestTileResourceGenerator\RainForestTileResourceGenerator\` (this is the folder where map256.raw exists).

### For `RainforestLODConsoleApp` 
Set the Command Line Arguments to:
```
map256.raw 8
```

## Extending the application for your use-case
This application was very focused on our particular usecase - Generating LOD files based on tile type. It is however not too difficult to extend.

### Change the file format
See `LODFileFormatWriter.cs`

### Change the tile types
See `RainforestLodSimplifier.cs` and `BitmapLodSimplifier.cs`