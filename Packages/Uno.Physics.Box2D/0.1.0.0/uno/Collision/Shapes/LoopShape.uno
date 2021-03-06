/*
* Box2D.XNA port of Box2D:
* Copyright (c) 2009 Brandon Furtwangler, Nathan Furtwangler
*
* Original source Box2D:
* Copyright (c) 2006-2009 Erin Catto http://www.gphysics.com
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
    /// A loop Shape is a free form sequence of line segments that form a circular list.
    /// The loop may cross upon itself, but this is not recommended for smooth collision.
    /// The loop has double sided collision, so you can use inside and outside collision.
    /// Therefore, you may use any winding order.
    public class LoopShape : Shape
    {
	    public LoopShape()
        {
	        ShapeType = ShapeType.Chain;
	        _radius = Settings.b2_polygonRadius;
	        _vertices = null;
	        _count = 0;
        }

	    /// Implement Shape.
	    public override Shape Clone()
        {
            var loop = new LoopShape();
            loop._count = _count;
            loop._radius = _radius;
            Array.Copy(_vertices, loop._vertices, loop._vertices.Length);
            return loop;
        }

	    /// @see Shape::GetChildCount
        public override int GetChildCount()
        {
	        return _count;
        }
	    /// Get a child edge.
        public void GetChildEdge(ref EdgeShape edge, int index)
        {
	        edge.ShapeType = ShapeType.Edge;
	        edge._radius = _radius;
	        edge._hasVertex0 = true;
	        edge._hasVertex3 = true;

	        int i0 = index - 1 >= 0 ? index - 1 : _count - 1;
	        int i1 = index;
	        int i2 = index + 1 < _count ? index + 1 : 0;
	        int i3 = index + 2;
	        while (i3 >= _count)
	        {
		        i3 -= _count;
	        }

	        edge._vertex0 = _vertices[i0];
	        edge._vertex1 = _vertices[i1];
	        edge._vertex2 = _vertices[i2];
	        edge._vertex3 = _vertices[i3];
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

	    /// The vertices. These are not owned/freed by the loop Shape.
	    public float2[] _vertices;

	    /// The vertex count.
	    public int _count;

        public static EdgeShape s_edgeShape = new EdgeShape();
    }
}
