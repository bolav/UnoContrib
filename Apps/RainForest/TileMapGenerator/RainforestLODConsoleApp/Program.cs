using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using RainForestTileResourceGenerator;
using System.Collections.Concurrent;

namespace RainforestLODConsoleApp
{
    class Program
    {

        private static BitmapImage _mapImageSource;

        // Application to build LOD files based on a Raw map.
        public static void Main(string[] args)
        {
            if (args.Length < 1)
            {
                args = new string[3];

                Console.Write("Enter map name: ");
                args[0] = Console.ReadLine();

                Console.Write("Enter Max LOD: ");
                args[1] = Console.ReadLine();

            }

            var mapFilename = args[0];
            var map = File.ReadAllBytes(mapFilename);

            var numPixelWidth = (int) Math.Sqrt(map.Length);

            _mapImageSource = map.ConvertToBitmap(numPixelWidth).ToImageSource();
            
            int levelOfDetail = Convert.ToInt32(args[1]);
            
            Console.WriteLine("Processing {0} for Max LOD {1}", mapFilename, levelOfDetail);

            foreach (var index in Enumerable.Range(0, levelOfDetail))
            {
                GenerateLODFile(index);
            }

            Console.WriteLine("Done....");
            Console.ReadKey();
        }

        private static void GenerateLODFile(int lod)
        {
            string fileName = lod + ".lod";
            Console.WriteLine("Generating file: " + fileName);

            // Open file for writing
            FileStream file = File.OpenWrite(fileName);

            // Calculate LOD of map
            var rainforestLodSimplifier = new RainforestLodSimplifier(_mapImageSource, lod + 1);
            Dictionary<Int32Rect, byte> lodDict = rainforestLodSimplifier.CalculateLod();

            // Merge these together!
            var concurrentDictionary = new ConcurrentDictionary<Int32Rect, byte>();
            Parallel.ForEach(lodDict, (entry) => 
            {
                byte mapValue = ConvertMapValueToTile(entry.Value);
                byte combinedValue = mapValue;

                concurrentDictionary[entry.Key] = combinedValue;
            });

            Console.WriteLine();

            // Write our special format to the file
            var lodFileFormatWriter = new LODFileFormatWriter();
            lodFileFormatWriter.Write(file, concurrentDictionary.ToDictionary(c => c.Key, c => c.Value));

            file.Close();

            Console.WriteLine("Done generating: " + fileName);
            Console.WriteLine();
        }

        private static byte ConvertMapValueToTile(byte value)
        {
            switch (value)
            {
                case RainforestLodSimplifier.GrassColorId:
                    return 1;
                case RainforestLodSimplifier.MountainColorId:
                    return 3;
                case RainforestLodSimplifier.WaterColorId:
                    return 0;
                default:
                    return 2; // Dead forest
            }
        }
    }
}
