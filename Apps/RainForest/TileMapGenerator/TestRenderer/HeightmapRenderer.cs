using System;
using System.Collections.Generic;
using System.Drawing.Imaging;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using RainForestTileResourceGenerator;

namespace TestRenderer
{
    public class HeightmapRenderer : Canvas
    {
        private byte[] _imageSource;
        private int _numPixelWidth;

        public byte[] ImageSource
        {
            get { return _imageSource; }
            set
            {
                _imageSource = value;
                _numPixelWidth = (int)Math.Sqrt(_imageSource.Length);
                CalculateLod();
            }
        }

        private int _levelOfDetail;
        public int LevelOfDetail
        {
            get { return _levelOfDetail; }
            set
            {
                _levelOfDetail = value;
                CalculateLod();
            }
        }

        private Dictionary<Int32Rect, byte> _map;

        private void CalculateLod()
        {
            if (_imageSource == null) return;

            if (_map != null)
            {
                _map.Clear();
                _map = null;
            }

            var s = new BitmapLodSimplifier(ImageSource.ConvertToBitmap(_numPixelWidth).ToImageSource(), LevelOfDetail);
            _map = s.CalculateLod();
            UpdateLayout();
        }

        private Color Lookup(int i)
        {
            byte color = Convert.ToByte(i);

            return Color.FromRgb(color, color, color);
        }

        protected override void OnRender(DrawingContext dc)
        {
            if (_map == null) return;

            foreach (var colorPair in _map)
            {
                dc.DrawRectangle(new SolidColorBrush(Lookup(colorPair.Value)), 
                                    null, 
                                    new Rect(colorPair.Key.X, colorPair.Key.Y, colorPair.Key.Width, colorPair.Key.Width));
            }
            /*
            foreach (var recti in _map)
            {
                dc.DrawRectangle(null, new Pen(new SolidColorBrush(Color.FromRgb(255, 0, 0)), 2.0f), new Rect(recti.Key.X, recti.Key.Y, recti.Key.Width, recti.Key.Width));
            }
             */
        }
    }
}
