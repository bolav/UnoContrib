using Uno;
using Uno.Collections;
using Uno.Content.Models;
using Uno.Scenes.Batching;

namespace RainForest
{
	/**
	* Tile Mesh Batcher
	*
	* Similar to a normal MeshBatcher. Main difference is that we send
	* the positions pre-translated to a given position, (this is for merging 2x2 tile set into a
	* single batch), and write rotation information to Attrib0 buffer.
	*/
	public partial class TileMeshBatcher
	{
		class Entry
		{
			public ModelMesh Mesh;
			public Tile Tile;
			public Entry(ModelMesh m, Tile tile) { Mesh = m; Tile = tile; }
		}

		List<Entry> entries = new List<Entry>();

		public TileMeshBatcher()
		{

		}

		public int EntryCount { get { return entries.Count; } }

		public ModelMesh[] GetEntries()
		{
			var m = new ModelMesh[entries.Count];
			for (int i = 0; i < m.Length; i++) m[i] = entries[i].Mesh;
			return m;
		}

		public void AddMesh(ModelMesh mesh, Tile tile)
		{
			entries.Add(new Entry(mesh, tile));
		}

		Batch[] batches;
		public Batch[] Batches { get { Flush(); return batches; } }

		public void Flush()
		{
			if (batches != null) return;

			debug_log "Flushing batch";

			VertexAttributeArray
				position,
				texcoord, texcoord1, texcoord2, texcoord3, texcoord4, texcoord5, texcoord6, texcoord7,
				normal,
				tangent,
				binormal,
				color,
				boneWeights,
				boneIndex;

			var batches = new List<Batch>();
			Batch b = null;

			int virtualIndexBase = 0;
			var virtualIndexToRealIndex = new Dictionary<int, int>();

			int batchVertexCount = 0;
			int batchIndexCount = 0;
			int batchVertexCutoff = 0;
			int batchIndexCutoff = 0;

			for (int e = 0; e < entries.Count; e++)
			{

				var m = entries[e].Mesh;

				var entryTile = entries[e].Tile;
				float halfTileSize = entryTile.Size / 2.0f;

				position = texcoord = texcoord1 = texcoord2 = texcoord3 = texcoord4 = texcoord5 = texcoord6 = texcoord7 = normal = tangent = binormal = color = boneWeights = boneIndex = null;
				foreach (var v in m.VertexAttributes)
				{
					if (v.Key == VertexAttributeSemantic.Position) position = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord) texcoord = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord1) texcoord1 = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord2) texcoord2 = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord3) texcoord3 = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord4) texcoord4 = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord5) texcoord5 = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord6) texcoord6 = v.Value;
					else if (v.Key == VertexAttributeSemantic.TexCoord7) texcoord7 = v.Value;
					else if (v.Key == VertexAttributeSemantic.Normal) normal = v.Value;
					else if (v.Key == VertexAttributeSemantic.Tangent) tangent = v.Value;
					else if (v.Key == VertexAttributeSemantic.Binormal) binormal = v.Value;
					else if (v.Key == VertexAttributeSemantic.Color) color = v.Value;
					else if (v.Key == VertexAttributeSemantic.BoneWeights) boneWeights = v.Value;
					else if (v.Key == VertexAttributeSemantic.BoneIndices) boneIndex = v.Value;
				}

				if (m.Indices == null)
				{
					m = CreateFakeIndexBuffer(m);
				}

				for (int i = 0; i < m.IndexCount; i++)
				{
					if (batchVertexCount >= batchVertexCutoff || batchIndexCount >= batchIndexCutoff)
					{
						// TODO: create some heurisitc to esitmate these figures instead of using constants
						batchVertexCutoff = 65535;
						batchIndexCutoff = 100000;

						b = new Batch(batchVertexCutoff, batchIndexCutoff, true);
						batches.Add(b);

						virtualIndexToRealIndex = new Dictionary<int, int>();

 						batchVertexCount = 0;
						batchIndexCount = 0;
					}

					int originalIndex = m.Indices.GetInt(i);
					int virtualIndex = virtualIndexBase + originalIndex;

					int newIndex;
					if (!virtualIndexToRealIndex.TryGetValue(virtualIndex, out newIndex))
					{
						newIndex = batchVertexCount;
						virtualIndexToRealIndex.Add(virtualIndex, newIndex);


						// Emit vertex
						if (position != null)
							b.Positions.Write(position.GetFloat4(originalIndex).XYZ + float3(entryTile.Position.X + (entryTile.Size / 2), entryTile.Position.Y + (entryTile.Size / 2), 0.0f));

						if (texcoord != null)
							b.TexCoord0s.Write(texcoord.GetFloat4(originalIndex).XY);

						if (texcoord1 != null)
							b.TexCoord1s.Write(texcoord1.GetFloat4(originalIndex).XY);

						if (texcoord2 != null)
							b.TexCoord2s.Write(texcoord2.GetFloat4(originalIndex).XY);

						if (texcoord3 != null)
							b.TexCoord3s.Write(texcoord3.GetFloat4(originalIndex).XY);

						if (texcoord4 != null)
							b.TexCoord4s.Write(texcoord4.GetFloat4(originalIndex).XY);

						if (texcoord5 != null)
							b.TexCoord5s.Write(texcoord5.GetFloat4(originalIndex).XY);

						if (texcoord6 != null)
							b.TexCoord6s.Write(texcoord6.GetFloat4(originalIndex).XY);

						if (texcoord7 != null)
							b.TexCoord7s.Write(texcoord7.GetFloat4(originalIndex).XY);

						if (normal != null)
							b.Normals.Write(normal.GetFloat4(originalIndex).XYZ);

						if (tangent != null)
							b.Tangents.Write(tangent.GetFloat4(originalIndex));

						if (binormal != null)
							b.Binormals.Write(binormal.GetFloat4(originalIndex).XYZ);

						if (color != null)
							b.Colors.Write(color.GetFloat4(originalIndex));

						if (boneWeights != null)
							b.BoneWeightBuffer.Write(boneWeights.GetByte4Normalized(originalIndex));

						if (boneIndex != null)
							b.BoneIndexBuffer.Write(boneIndex.GetByte4(originalIndex));

						if(entries.Count == 1)
						{
							b.Attrib0Buffer.Write(float4(halfTileSize, halfTileSize, 0, e));
						} else
						{
							int x = entryTile.Position.X / entryTile.Size + 1;
							int y = entryTile.Position.Y / entryTile.Size + 1;

							/**
							* Attrib0 buffer is used for finding the rotation point. For
							* elements other then 0,0 we need to translate the object not only
							* by its own center, but also back to the draw origin.
							*
							*
							* I.e. Tile at (2, 2) with size 32 needs to be translated (-32, -32).
							* But, tile at (0, 0) only needs to be translated (-16, -16).
							*/
							if(x > 1) x++;
							if(y > 1) y++;

							b.Attrib0Buffer.Write(float4(halfTileSize * x, halfTileSize * y, 0, e));
						}

						batchVertexCount++;
					}

					// Emit index
					b.Indices.Write((ushort)newIndex);
					batchIndexCount++;
				}

				virtualIndexBase += m.VertexCount;
			}

			this.batches = batches.ToArray();
		}

		static ModelMesh CreateFakeIndexBuffer(ModelMesh m)
		{
			var d = new uint[m.VertexCount];
			for (int i = 0; i < d.Length; i++) d[i] = (uint)i;

			var dict = new Dictionary<string, VertexAttributeArray>();
			foreach (var v in m.VertexAttributes)
				dict[v.Key] = v.Value;

			return new ModelMesh(m.Name, m.PrimitiveType, dict, new IndexArray(d));
		}
	}
}