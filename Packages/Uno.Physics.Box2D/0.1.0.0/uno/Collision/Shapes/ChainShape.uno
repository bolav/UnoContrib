/*
* Box2D: r313
* Uno port of Box2D:
* Copyright (c) 2014 Bjørn-Olav Strand
*
* Original source Box2D:
* Copyright (c) 2006-2010 Erin Catto http://www.box2d.org
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*/




namespace Uno.Physics.Box2D
{
    /// A Chain Shape is a free form sequence of line segments that form a circular list.
    /// The Chain may cross upon itself, but this is not recommended for smooth collision.
    /// The Chain has double sided collision, so you can use inside and outside collision.
    /// Therefore, you may use any winding order.
    public class ChainShape : Shape
    {
	    public ChainShape()
        {
	        ShapeType = ShapeType.Chain;
	        _radius = Settings.b2_polygonRadius;
	        _vertices = null;
	        _count = 0;
			_hasPrevVertex = false;
			_hasNextVertex = false;
        }

		public void CreateLoop (float2[] vertices, int count) {
			// b2Assert(m_vertices == NULL && m_count == 0);
			// b2Assert(count >= 3);
			for (var i = 0; i < count; ++i) {
				var v1 = vertices[i-1];
				var v2 = vertices[i];
				// b2Assert(b2DistanceSquared(v1, v2) > b2_linearSlop * b2_linearSlop);
			}

			_count = count + 1;
			_vertices = new float2[_count];
            Array.Copy(_vertices, 0, vertices, 0, vertices.Length);
			_vertices[count] = _vertices[0];
			_prevVertex = _vertices[_count - 2];
			_nextVertex = _vertices[1];
			_hasPrevVertex = true;
			_hasNextVertex = true;
		}
		
		public void CreateChain (float2[] vertices, int count) {
			// b2Assert(m_vertices == NULL && m_count == 0);
			// b2Assert(count >= 2);
			for (int i = 1; i < count; ++i)
			{
				// If the code crashes here, it means your vertices are too close together.
				// b2Assert(b2DistanceSquared(vertices[i-1], vertices[i]) > b2_linearSlop * b2_linearSlop);
			}

			_count = count;
			_vertices = new float2[_count];
            Array.Copy(_vertices, 0, vertices, 0, vertices.Length);

			_hasPrevVertex = false;
			_hasNextVertex = false;

			_prevVertex = float2(0);
			_nextVertex = float2(0);
		}
		
		public float2 PrevVertex {
			get { return _prevVertex; }
			set {
				_prevVertex = value;
				_hasPrevVertex = true;
			}
		}
		
		public float2 NextVertex {
			get { return _nextVertex; }
			set {
				_nextVertex = value;
				_hasNextVertex = true;
			}
		}

	    /// Implement Shape.
	    public override Shape Clone()
        {
            var Chain = new ChainShape();
			Chain.CreateChain(_vertices, _count);
			Chain._prevVertex = _prevVertex;
			Chain._nextVertex = _nextVertex;
			Chain._hasPrevVertex = _hasPrevVertex;
			Chain._hasNextVertex = _hasNextVertex;
            return Chain;
        }

	    /// @see Shape::GetChildCount
        public override int GetChildCount()
        {
	        return _count - 1;
        }
	    /// Get a child edge.
        public void GetChildEdge(ref EdgeShape edge, int index)
        {
			// 	b2Assert(0 <= index && index < m_count - 1);
	        edge.ShapeType = ShapeType.Edge;
	        edge._radius = _radius;

			edge._vertex1 = _vertices[index + 0];
			edge._vertex2 = _vertices[index + 1];

			if (index > 0)
			{
				edge._vertex0 = _vertices[index - 1];
				edge._hasVertex0 = true;
			}
			else
			{
				edge._vertex0 = _prevVertex;
				edge._hasVertex0 = _hasPrevVertex;
			}

			if (index < _count - 2)
			{
				edge._vertex3 = _vertices[index + 2];
				edge._hasVertex3 = true;
			}
			else
			{
				edge._vertex3 = _nextVertex;
				edge._hasVertex3 = _hasNextVertex;
			}
        }
	    /// This always return false.
	    /// @see Shape::TestPoint
        public override bool TestPoint(ref Transform transform, float2 p)
        {
	        return false;
        }

	    /// Implement Shape.
        public override bool RayCast(out RayCastOutput output, ref RayCastInput input,
					    ref Transform transform, int childIndex)
        {
            int i1 = childIndex;
	        int i2 = childIndex + 1;
	        if (i2 == _count)
	        {
		        i2 = 0;
	        }

	        s_edgeShape._vertex1 = _vertices[i1];
	        s_edgeShape._vertex2 = _vertices[i2];

	        return s_edgeShape.RayCast(out output, ref input, ref transform, 0);
        }

	    /// @see Shape::ComputeAABB
        public override void ComputeAABB(out AABB aabb, ref Transform transform, int childIndex)
        {
            aabb = new AABB();

	        int i1 = childIndex;
	        int i2 = childIndex + 1;
	        if (i2 == _count)
	        {
		        i2 = 0;
	        }

            float2 v1 = MathUtils.Multiply(ref transform, _vertices[i1]);
            float2 v2 = MathUtils.Multiply(ref transform, _vertices[i2]);

	        aabb.lowerBound = MathUtils.Min(v1, v2);
	        aabb.upperBound = MathUtils.Max(v1, v2);
        }

	    /// Chains have zero mass.
	    /// @see Shape::ComputeMass
        public override void ComputeMass(out MassData massData, float density)
        {
            massData = new MassData();
	        massData.mass = 0.0f;
	        massData.center = float2(0);
	        massData.I = 0.0f;
        }

	/// The vertices. Owned by this class.
	    public float2[] _vertices;

	    /// The vertex count.
	    public int _count;

		public float2 _prevVertex;
		public float2 _nextVertex;

		public bool _hasPrevVertex;
		public bool _hasNextVertex;

        public static EdgeShape s_edgeShape = new EdgeShape();
    }
}
