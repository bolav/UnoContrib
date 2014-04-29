using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;

namespace RainForestTileResourceGenerator
{
    public class LODFileFormatWriter
    {

        public void Write(FileStream fileStream, Dictionary<Int32Rect, byte> lodArray)
        {
            // LOD sorted by column, then row.
            var sortedLod = lodArray.OrderBy(element => element.Key.Y).ThenBy(element => element.Key.X);

            Console.WriteLine("Has " + sortedLod.Count() + " Elements. Expecting to write: " + (sortedLod.Count()) + " bytes");

            var orderedLod = sortedLod.ToList();

            var writeCount = 0;
            for (var i = 0; i < orderedLod.Count; i++)
            {
                fileStream.WriteByte(orderedLod[i].Value);
                writeCount++;
            }

            Console.WriteLine("Wrote :" + writeCount + " bytes");
        }
    }
}
