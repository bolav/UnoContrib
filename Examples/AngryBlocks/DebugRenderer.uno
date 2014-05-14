using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

using Uno.Physics.Box2D;
using AngryBlocks.Box2DMath;

namespace AngryBlocks
{
	public class DebugRenderer : DebugDraw
	{
		public override void DrawPolygon(ref float2[] vertices, int count, float4 color, float2 center)
		{
			DrawSolidPolygonHelper(vertices, count, color);
		}

	    /// Draw a solid closed polygon provided in CCW order.
        public override void DrawSolidPolygon(ref float2[] vertices, int count, float4 color, float2 center)
		{
			DrawSolidPolygonHelper(vertices, count, color);
		}

		private void DrawSolidPolygonHelper(float2[] vertices, int count, float4 color)
		{
			ushort[] indices = new Triangulator(vertices).Triangulate();


			draw {
				ushort[] Indices : indices;
				float2 VertexData: vertex_attrib(vertices, Indices);
				float2 VertexPosition: VertexData.XY * float2(1 / Context.Aspect, 1.0f);
				VertexCount: indices.Length;
				ClipPosition : float4(Box2DToUno(VertexPosition), 0, 1);
				public float3 VertexNormal: float3(0, 0, 1);

				PixelColor: color;
				CullFace: PolygonFace.None;
				PrimitiveType:Uno.Graphics.PrimitiveType.TriangleStrip;
			};

			draw {
				ushort[] Indices : indices;
				float2 VertexData: vertex_attrib(vertices, Indices);
				float2 VertexPosition: VertexData.XY * float2(1 / Context.Aspect, 1.0f);
				VertexCount: indices.Length;
				ClipPosition : float4(Box2DToUno(VertexPosition), 0, 1);
				public float3 VertexNormal: float3(0, 0, 1);

				PixelColor: float4(1, 0, 0, 1);
				CullFace: PolygonFace.None;
				PrimitiveType: Uno.Graphics.PrimitiveType.LineStrip;
			};

		}

	    /// Draw a circle.
        public override void DrawCircle(float2 center, float radius, float4 color)
		{
			float2[] vertices = new float2[10];
			//vertices[0] = center;
			for(int i = 0; i < 10; i++) {
				vertices[i] = center + radius * float2(Math.Sin(Math.DegreesToRadians(i * 36)), Math.Cos(Math.DegreesToRadians(i * 36)));
			}

			DrawSolidPolygonHelper(vertices, vertices.Length, color);
		}

	    /// Draw a solid circle.
        public override void DrawSolidCircle(float2 center, float radius, float2 axis, float4 color)
		{
			DrawCircle(center, radius, color);
		}

	    /// Draw a line segment.
        public override void DrawSegment(float2 p1, float2 p2, float4 color, float2 center)
		{
			draw {
				float2 VertexData: vertex_attrib(new float2[]{p1, p2});
				float2 VertexPosition: VertexData.XY * float2(1 / Context.Aspect, 1.0f);
				VertexCount: 2;
				ClipPosition : float4(Box2DToUno(VertexPosition), 0, 1);
				PixelColor: color;
				PrimitiveType: Uno.Graphics.PrimitiveType.Lines;
				LineWidth: 3.0f;
			};
		}

	    /// Draw a transform. Choose your own length scale.
	    /// @param xf a transform.
        public override void DrawTransform(ref Uno.Physics.Box2D.Transform xf)
		{

		}
	}

	// Code from: http://wiki.unity3d.com/index.php?title=Triangulator
	public class Triangulator
	{
	    private List<float2> m_points = new List<float2>();

	    public Triangulator (float2[] points) {
	        m_points = new List<float2>();

			foreach(float2 p in points)
			{
				m_points.Add(p);
			}
	    }

	    public ushort[] Triangulate() {
	        List<ushort> indices = new List<ushort>();

	        int n = m_points.Count;
	        if (n < 3)
	            return indices.ToArray();

	        int[] V = new int[n];
	        if (Area() > 0) {
	            for (int v = 0; v < n; v++)
	                V[v] = v;
	        }
	        else {
	            for (int v = 0; v < n; v++)
	                V[v] = (n - 1) - v;
	        }

	        int nv = n;
	        int count = 2 * nv;
	        for (int m = 0, v = nv - 1; nv > 2; ) {
	            if ((count--) <= 0)
	                return indices.ToArray();

	            int u = v;
	            if (nv <= u)
	                u = 0;
	            v = u + 1;
	            if (nv <= v)
	                v = 0;
	            int w = v + 1;
	            if (nv <= w)
	                w = 0;

	            if (Snip(u,v,w,nv,V)) {
	                int a, b, c, s, t;
	                a = V[u];
	                b = V[v];
	                c = V[w];
	                indices.Add((ushort) a);
	                indices.Add((ushort) b);
	                indices.Add((ushort) c);
	                m++;
					s = v;
					t = v + 1;
	                for (; t < nv; s++) {
	                    V[s] = V[t];
						t++;
					}
	                nv--;
	                count = 2 * nv;
	            }
	        }

			ushort[] array = indices.ToArray();

			ushort[] output = new ushort[array.Length];

			for(int i = 0; i < array.Length; i++)
			{
				output[i] = array[array.Length - 1 - i];
			}

			return output;
	    }

	    private float Area () {
	        int n = m_points.Count;
	        float A = 0.0f;
	        for (int p = n - 1, q = 0; q < n; p = q++) {
	            float2 pval = m_points[p];
	            float2 qval = m_points[q];
	            A += pval.X * qval.Y - qval.X * pval.Y;
	        }
	        return (A * 0.5f);
	    }

	    private bool Snip (int u, int v, int w, int n, int[] V) {
	        int p;
	        float2 A = m_points[V[u]];
	        float2 B = m_points[V[v]];
	        float2 C = m_points[V[w]];
	        if (Float.ZeroTolerance > (((B.X - A.X) * (C.Y - A.Y)) - ((B.Y - A.Y) * (C.X - A.X))))
	            return false;
	        for (p = 0; p < n; p++) {
	            if ((p == u) || (p == v) || (p == w))
	                continue;
	            float2 P = m_points[V[p]];
	            if (InsideTriangle(A, B, C, P))
	                return false;
	        }
	        return true;
	    }

	    private bool InsideTriangle (float2 A, float2 B, float2 C, float2 P) {
	        float ax, ay, bx, by, cx, cy, apx, apy, bpx, bpy, cpx, cpy;
	        float cCROSSap, bCROSScp, aCROSSbp;

	        ax = C.X - B.X; ay = C.Y - B.Y;
	        bx = A.X - C.X; by = A.Y - C.Y;
	        cx = B.X - A.X; cy = B.Y - A.Y;
	        apx = P.X - A.X; apy = P.Y - A.Y;
	        bpx = P.X - B.X; bpy = P.Y - B.Y;
	        cpx = P.X - C.X; cpy = P.Y - C.Y;

	        aCROSSbp = ax * bpy - ay * bpx;
	        cCROSSap = cx * apy - cy * apx;
	        bCROSScp = bx * cpy - by * cpx;

	        return ((aCROSSbp >= 0.0f) && (bCROSScp >= 0.0f) && (cCROSSap >= 0.0f));
	    }
	}
}