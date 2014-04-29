using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;

namespace RainForestTileResourceGenerator
{
    public static class Int32RectSubdivideExt
    {

        /// <summary>
        /// Subdivides the current rectangle down to MaxDepth and fills this into the outputList
        /// </summary>
        public static void Subdivide(this Int32Rect rect, int maxDepth, List<Int32Rect> outputList)
        {
            SubdivideHelper(rect, 0, maxDepth, outputList);
        }

        /// <summary>
        /// Internal helper to hide away the current depth value.
        /// </summary>
        private static void SubdivideHelper(this Int32Rect rect, int currentDepth, int maxDepth, List<Int32Rect> outputList)
        {
            if (currentDepth < maxDepth)
            {
                foreach (var subdividedRect in SubdivideRect(rect))
                {
                    SubdivideHelper(subdividedRect, currentDepth + 1, maxDepth, outputList);
                }
            }
            else
            {
                outputList.Add(rect);
            }
        }

        /// <summary>
        /// Helper method for subdividing a rectangle down to four smaller rectangles.
        /// 
        /// This divides it into Top-Left, Top-Right, Bottom-Left, Bottom-Right.
        /// </summary>
        /// <param name="rect"></param>
        /// <returns></returns>
        private static IEnumerable<Int32Rect> SubdivideRect(Int32Rect rect)
        {
            int halfRectSize = rect.Width / 2;

            return new[]
            {
                // Top left
                new Int32Rect(rect.X, rect.Y, halfRectSize, halfRectSize),
                // Top Right
                new Int32Rect(rect.X + halfRectSize, rect.Y, halfRectSize, halfRectSize),
                // Bottom Left
                new Int32Rect(rect.X, rect.Y + halfRectSize, halfRectSize, halfRectSize),
                // Bottom Right
                new Int32Rect(rect.X + halfRectSize, rect.Y + halfRectSize, halfRectSize, halfRectSize) 
            };
        }
    }
}
