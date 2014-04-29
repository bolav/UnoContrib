using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using RainForestTileResourceGenerator;
using Color = System.Drawing.Color;
using WindowsMediaColor = System.Windows.Media.Color;
using Pen = System.Windows.Media.Pen;
using PixelFormat = System.Drawing.Imaging.PixelFormat;

namespace TestRenderer
{
    public class RawImageCanvas : Canvas
    {
        private byte[] _imageSource;
        private int _numPixelWidth;

        public byte[] ImageSource
        {
            get { return _imageSource; }
            set
            {
                _imageSource = value;
                _numPixelWidth = (int) Math.Sqrt(_imageSource.Length);
            }
        }

        public RawImageCanvas()
        {
            RenderOptions.SetBitmapScalingMode(this, BitmapScalingMode.NearestNeighbor);
        }

        protected override void OnInitialized(EventArgs e)
        {
            
            base.OnInitialized(e);
        }

        protected override void OnRender(DrawingContext dc)
        {
            base.OnRender(dc);
            if (ImageSource == null) return;

            dc.DrawImage(ImageSource.ConvertToBitmap(_numPixelWidth).ToImageSource(), new Rect(0, 0, _numPixelWidth, _numPixelWidth));
        }



    }
}
