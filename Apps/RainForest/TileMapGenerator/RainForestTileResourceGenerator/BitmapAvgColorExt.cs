using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Media.Imaging;

namespace RainForestTileResourceGenerator
{
    public static class BitmapAvgColorExt
    {
        /// <summary>
        /// Calculates a dictionary of each distinct "colour" in the BitmapSource.
        /// 
        /// This function only works on 8 bit images.
        /// 
        /// The dictionary is returned as < byte(Color), int(Count) >
        /// </summary>
        public static Dictionary<byte, int> GetDistinctColors(this BitmapSource bitmap, Int32Rect ? area)
        {
            if (area.HasValue)
            {
                bitmap = new CroppedBitmap(bitmap, area.Value);   
            }

            if (bitmap.PixelHeight != bitmap.PixelWidth)
            {
                throw new ArgumentException("Bitmap pixel height must match pixel width");
            }

            var array = new byte[bitmap.PixelHeight * bitmap.PixelHeight];

            bitmap.CopyPixels(array, bitmap.PixelWidth, 0);

            // Extended debug - if necessary Console.Write(".");

            return array.GroupBy(b => b).ToDictionary(c => c.Key, d => d.Count());
        }
    }
}
