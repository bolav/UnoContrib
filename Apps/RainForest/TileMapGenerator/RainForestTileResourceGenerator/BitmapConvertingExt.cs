using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Media.Imaging;

namespace RainForestTileResourceGenerator
{
    public static class BitmapConvertingExt
    {
        public static Bitmap ConvertToBitmap(this byte[] map, int numPixelWidth)
        {
            var b = new Bitmap(numPixelWidth, numPixelWidth, PixelFormat.Format8bppIndexed);

            ColorPalette ncp = b.Palette;

            for (byte i = 0; i < 255; i++)
            {
                ncp.Entries[i] = Color.FromArgb(1, (i*2%255), (i*3%255), i);
            }

            b.Palette = ncp;

            var boundsRect = new Rectangle(0, 0, numPixelWidth, numPixelWidth);
            BitmapData bmpData = b.LockBits(boundsRect,
                                            ImageLockMode.WriteOnly,
                                            b.PixelFormat);

            IntPtr ptr = bmpData.Scan0;

            int bytes = bmpData.Stride * b.Height;
            var rgbValues = map;

            Marshal.Copy(rgbValues, 0, ptr, bytes);
            b.UnlockBits(bmpData);
            return b;
        }

        public static BitmapImage ToImageSource(this Bitmap bitmap)
        {
            return ToImageSource(bitmap, ImageFormat.Bmp);
        }

        public static BitmapImage ToImageSource(this Bitmap bitmap, ImageFormat imgFormat)
        {
            using (var memory = new MemoryStream())
            {
                bitmap.Save(memory, imgFormat);
                memory.Position = 0;
                var bitmapImage = new BitmapImage();
                bitmapImage.BeginInit();
                bitmapImage.StreamSource = memory;
                bitmapImage.CacheOption = BitmapCacheOption.OnLoad;
                bitmapImage.EndInit();

                return bitmapImage;
            }
        }

    }
}
