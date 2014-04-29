using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media.Imaging;

namespace RainForestTileResourceGenerator
{
    /**
     * Rainforest Lod Simplifier
     * 
     * Merges the various grass color ids (0, 3, 6) together, and
     * translates all values to their correct values.
     */
    public class RainforestLodSimplifier : BitmapLodSimplifier
    {
        public const byte GrassColorId = 0;

        // Alterative Grass Color. Will be merged with GrassColorId.
        public const byte AltGrassColorId1 = 3;

        // Alternative grass color. Will be merged with GrassColorId.
        public const byte AltGrassColorId2 = 6;

        public const byte WaterColorId = 7;

        public const float WaterWeightCoefficient = 0.9f;

        public const byte MountainColorId = 5;

        public RainforestLodSimplifier(BitmapImage bitmapSource, int levelOfDetail) : 
            base(bitmapSource, levelOfDetail)
        {
        }

        const int MapCenterX = 118;
        const int MapCenterY = 90;

        public override byte CalculateBestColor(Int32Rect rectangle, Dictionary<byte, int> colorsWithFrequency)
        {
            var weightedDictionary = colorsWithFrequency.ToDictionary(c => c.Key,
                    c => (c.Key == WaterColorId) ? c.Value * WaterWeightCoefficient : c.Value
                );

            weightedDictionary = MergeDictonary(weightedDictionary);
            var color = weightedDictionary.OrderByDescending(c => c.Value).First().Key;
            return color; 
        }

        private Dictionary<byte, float> MergeDictonary(IReadOnlyDictionary<byte, float> weightedDictionary)
        {
            var grassIds = new[] {GrassColorId, AltGrassColorId1, AltGrassColorId2};

            // Build a return dictionary out of all non grass tiles
            var returnDictionary = weightedDictionary.Where(key => !grassIds.Contains(key.Key))
                .ToDictionary(c => c.Key, c => c.Value);
            returnDictionary[0] = 0;

            foreach (var grassId in grassIds.Where(weightedDictionary.ContainsKey))
            {
                returnDictionary[0] += weightedDictionary[grassId];
            }

            return returnDictionary;
        }
    }
}
