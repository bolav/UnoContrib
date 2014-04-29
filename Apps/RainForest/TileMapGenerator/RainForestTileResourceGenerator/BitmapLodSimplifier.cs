using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media.Imaging;

namespace RainForestTileResourceGenerator
{
    /// <summary>
    /// Bitmap Lod Simplifier
    /// 
    /// Simplifies a bitmap based on a specific level of detail down to a smaller
    /// level of detail.
    /// </summary>
    public class BitmapLodSimplifier
    {
        public BitmapImage BitmapSource { get; set; }

        public int LevelOfDetail { get; set; }

        public BitmapLodSimplifier(BitmapImage bitmapSource, int levelOfDetail)
        {
            if (bitmapSource.PixelHeight != bitmapSource.PixelWidth)
            {
                throw new ArgumentException("Pixel Height and Bitmap Source must match");
            }

            BitmapSource = bitmapSource;
            LevelOfDetail = levelOfDetail;
        }

        /// <summary>
        /// Calculate the LOD dictionary based on the Bitmap Source and requested LOD in the constructor.
        /// 
        /// The colour returned (the byte) is dependent on the CalculateBestColor method, which can be
        /// overridden to weight specific colour keys.
        /// </summary>
        /// <returns></returns>
        public virtual Dictionary<Int32Rect, byte> CalculateLod()
        {
            var initialRect = new Int32Rect(0, 0, BitmapSource.PixelHeight, BitmapSource.PixelHeight);

            // Subdivide the rectangle
            var outputList = new List<Int32Rect>();
            initialRect.Subdivide(LevelOfDetail, outputList);

            var outputDictionary = new ConcurrentDictionary<Int32Rect, byte>();
            if(BitmapSource.CanFreeze)
            { 
                BitmapSource.Freeze();
            }
            
            Parallel.ForEach(outputList, (element) =>
            {
                Dictionary<byte, int> colorsWithFrequency = BitmapSource.GetDistinctColors(element);

                byte bestColor = CalculateBestColor(element, colorsWithFrequency);

                outputDictionary[element] = bestColor;
            });

            return outputDictionary.ToDictionary(c => c.Key, c => c.Value);
        }

        public virtual byte CalculateBestColor(Int32Rect rectangle, Dictionary<byte, int> colorsWithFrequency)
        {
            return colorsWithFrequency.OrderByDescending(c => c.Value).First().Key;
        }
    }
}
