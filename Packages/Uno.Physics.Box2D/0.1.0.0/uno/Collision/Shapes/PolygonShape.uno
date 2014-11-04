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
    public class PolygonShape : Shape
    {
	    public PolygonShape()
        {
	        ShapeType = ShapeType.Polygon;
	        _radius = Settings.b2_polygonRadius;
	        _vertexCount = 0;
	        _centroid = float2(0);
			_vertices = new float2[8];
			_normals = new float2[8];
        }

	    /// Implement Shape.
	    public override Shape Clone()
        {
            var clone = new PolygonShape();
            clone.ShapeType = ShapeType;
            clone._radius = _radius;
            clone._vertexCount = _vertexCount;
            clone._centroid = _centroid;
            clone._vertices = _vertices;
            clone._normals = _normals;

            return clone;
        }

        /// @see b2Shape::GetChildCount
        public override int GetChildCount()
        {
            return 1;
        }

	    /// Copy vertices. This assumes the vertices define a convex polygon.
	    /// It is assumed that the exterior is the the right of each edge.
        public void Set(float2[] vertices, int count)
        {

            _vertexCount = count;

            // Copy vertices.
            for (int i = 0; i < _vertexCount; ++i)
            {
	            _vertices[i] = vertices[i];
            }

            // Compute normals. Ensure the edges have non-zero length.
            for (int i = 0; i < _vertexCount; ++i)
            {
	            int i1 = i;
	            int i2 = i + 1 < _vertexCount ? i + 1 : 0;
	            float2 edge = _vertices[i2] - _vertices[i1];


                var temp = MathUtils.Cross(edge, 1.0f);
                temp = Vector.Normalize(temp);
                _normals[i] = temp;
            }

            // Compute the polygon centroid.
            _centroid = ComputeCentroid(ref _vertices, _vertexCount);
        }

        static float2 ComputeCentroid(ref float2[] vs, int count)
        {


	        float2 c = float2(0.0f, 0.0f);
	        float area = 0.0f;

	        if (count == 2)
	        {
                c = (vs[0] + vs[1]) * 0.5f;
		        return c;
	        }

	        // pRef is the reference point for forming triangles.
	        // It's location doesn't change the result (except for rounding error).
	        float2 pRef = float2(0.0f, 0.0f);

	        const float inv3 = 1.0f / 3.0f;

	        for (int i = 0; i < count; ++i)
	        {
		        // Triangle vertices.
		        float2 p1 = pRef;
		        float2 p2 = vs[i];
		        float2 p3 = i + 1 < count ? vs[i+1] : vs[0];

		        float2 e1 = p2 - p1;
		        float2 e2 = p3 - p1;

		        float D = MathUtils.Cross(e1, e2);

		        float triangleArea = 0.5f * D;
		        area += triangleArea;

		        // Area weighted centroid
		        c += (p1 + p2 + p3) * (triangleArea * inv3);
	        }

	        // Centroid

	        c *= 1.0f / area;
	        return c;
        }

	    /// Build vertices to represent an axis-aligned box.
	    /// @param hx the half-width.
	    /// @param hy the half-height.
        public void SetAsBox(float hx, float hy)
        {
	        _vertexCount = 4;
	        _vertices[0] = float2(-hx, -hy);
	        _vertices[1] = float2( hx, -hy);
	        _vertices[2] = float2( hx,  hy);
	        _vertices[3] = float2(-hx,  hy);
	        _normals[0] = float2(0.0f, -1.0f);
	        _normals[1] = float2(1.0f, 0.0f);
	        _normals[2] = float2(0.0f, 1.0f);
	        _normals[3] = float2(-1.0f, 0.0f);
	        _centroid = float2(0);
        }

	    /// Build vertices to represent an oriented box.
	    /// @param hx the half-width.
	    /// @param hy the half-height.
	    /// @param center the center of the box in local coordinates.
	    /// @param angle the rotation of the box in local coordinates.
        public void SetAsBox(float hx, float hy, float2 center, float angle)
        {
	        _vertexCount = 4;
	        _vertices[0] = float2(-hx, -hy);
	        _vertices[1] = float2( hx, -hy);
	        _vertices[2] = float2( hx,  hy);
	        _vertices[3] = float2(-hx,  hy);
	        _normals[0] = float2(0.0f, -1.0f);
	        _normals[1] = float2(1.0f, 0.0f);
	        _normals[2] = float2(0.0f, 1.0f);
	        _normals[3] = float2(-1.0f, 0.0f);
	        _centroid = center;

            Transform xf = new Transform();
	        xf.p = center;
	        xf.q.Set(angle);

	        // Transform vertices and normals.
	        for (int i = 0; i < _vertexCount; ++i)
	        {
		        _vertices[i] = MathUtils.Multiply(ref xf, _vertices[i]);
		        _normals[i] = MathUtils.Multiply(ref xf.q, _normals[i]);
	        }
        }

	    /// Set this as a single edge.
        public void SetAsEdge(float2 v1, float2 v2)
        {
	        _vertexCount = 2;
	        _vertices[0] = v1;
	        _vertices[1] = v2;
            _centroid = (v1 + v2) * 0.5f;

            var temp = MathUtils.Cross(v2 - v1, 1.0f);
            temp = Vector.Normalize(temp);
            _normals[0] = temp;

	        _normals[1] = _normals[0] * (-1.0f);
        }

	    /// @see Shape.TestPoint
	    public override bool TestPoint(ref Transform xf, float2 p)
        {
	        float2 pLocal = MathUtils.MultiplyT(ref xf.q, p - xf.p);

	        for (int i = 0; i < _vertexCount; ++i)
	        {
		        float dot = Uno.Vector.Dot(_normals[i], pLocal - _vertices[i]);
		        if (dot > 0.0f)
		        {
			        return false;
		        }
	        }

	        return true;
        }

        public override bool RayCast(out RayCastOutput output, ref RayCastInput input, ref Transform xf, int childIndex)
        {
            output = new RayCastOutput();

            // Put the ray into the polygon's frame of reference.
            float2 p1 = MathUtils.MultiplyT(ref xf.q, input.p1 - xf.p);
            float2 p2 = MathUtils.MultiplyT(ref xf.q, input.p2 - xf.p);
            float2 d = p2 - p1;

            if (_vertexCount == 2)
            {
                float2 v1 = _vertices[0];
                float2 v2 = _vertices[1];
                float2 normal = _normals[0];

                // q = p1 + t * d
                // dot(normal, q - v1) = 0
                // dot(normal, p1 - v1) + t * dot(normal, d) = 0
                float numerator = Uno.Vector.Dot(normal, v1 - p1);
                float denominator = Uno.Vector.Dot(normal, d);

                if (denominator == 0.0f)
                {
                    return false;
                }

                float t = numerator / denominator;
                if (t < 0.0f || 1.0f < t)
                {
                    return false;
                }

                float2 q = p1 + d * t;

                // q = v1 + s * r
                // s = dot(q - v1, r) / dot(r, r)
                float2 r = v2 - v1;
                float rr = Uno.Vector.Dot(r, r);
                if (rr == 0.0f)
                {
                    return false;
                }

                float s = Uno.Vector.Dot(q - v1, r) / rr;
                if (s < 0.0f || 1.0f < s)
                {
                    return false;
                }

                output.fraction = t;
                if (numerator > 0.0f)
                {
                    output.normal = normal * -1.0f;
                }
                else
                {
                    output.normal = normal;
                }
                return true;
            }
            else
            {
                float lower = 0.0f, upper = input.maxFraction;

                int index = -1;

                for (int i = 0; i < _vertexCount; ++i)
                {
                    // p = p1 + a * d
                    // dot(normal, p - v) = 0
                    // dot(normal, p1 - v) + a * dot(normal, d) = 0
                    float numerator = Uno.Vector.Dot(_normals[i], _vertices[i] - p1);
                    float denominator = Uno.Vector.Dot(_normals[i], d);

                    if (denominator == 0.0f)
                    {
                        if (numerator < 0.0f)
                        {
                            return false;
                        }
                    }
                    else
                    {
                        // Note: we want this predicate without division:
                        // lower < numerator / denominator, where denominator < 0
                        // Since denominator < 0, we have to flip the inequality:
                        // lower < numerator / denominator <==> denominator * lower > numerator.
                        if (denominator < 0.0f && numerator < lower * denominator)
                        {
                            // Increase lower.
                            // The segment enters this half-space.
                            lower = numerator / denominator;
                            index = i;
                        }
                        else if (denominator > 0.0f && numerator < upper * denominator)
                        {
                            // Decrease upper.
                            // The segment exits this half-space.
                            upper = numerator / denominator;
                        }
                    }

                    // The use of epsilon here causes the assert on lower to trip
                    // in some cases. Apparently the use of epsilon was to make edge
                    // shapes work, but now those are handled separately.
                    //if (upper < lower - b2_epsilon)
                    if (upper < lower)
                    {
                        return false;
                    }
                }



                if (index >= 0)
                {
                    output.fraction = lower;
                    output.normal = MathUtils.Multiply(ref xf.q, _normals[index]);
                    return true;
                }
            }

            return false;
        }


	    /// @see Shape.ComputeAABB
        public override void ComputeAABB(out AABB aabb, ref Transform xf, int childIndex)
        {
	        float2 lower = MathUtils.Multiply(ref xf, _vertices[0]);
	        float2 upper = lower;

	        for (int i = 1; i < _vertexCount; ++i)
	        {
		        float2 v = MathUtils.Multiply(ref xf, _vertices[i]);
		        lower = MathUtils.Min(lower, v);
		        upper = MathUtils.Max(upper, v);
	        }

	        float2 r = float2(_radius, _radius);
	        aabb.lowerBound = lower - r;
	        aabb.upperBound = upper + r;
        }

	    /// @see Shape.ComputeMass
	    public override void ComputeMass(out MassData massData, float density)
        {
	        // Polygon mass, centroid, and inertia.
	        // Let rho be the polygon density in mass per unit area.
	        // Then:
	        // mass = rho * int(dA)
	        // centroid.X = (1/mass) * rho * int(x * dA)
	        // centroid.Y = (1/mass) * rho * int(y * dA)
	        // I = rho * int((x*x + y*y) * dA)
	        //
	        // We can compute these integrals by summing all the integrals
	        // for each triangle of the polygon. To evaluate the integral
	        // for a single triangle, we make a change of variables to
	        // the (u,v) coordinates of the triangle:
	        // x = x0 + e1x * u + e2x * v
	        // y = y0 + e1y * u + e2y * v
	        // where 0 <= u && 0 <= v && u + v <= 1.
	        //
	        // We integrate u from [0,1-v] and then v from [0,1].
	        // We also need to use the Jacobian of the transformation:
	        // D = cross(e1, e2)
	        //
	        // Simplification: triangle centroid = (1/3) * (p1 + p2 + p3)
	        //
	        // The rest of the derivation is handled by computer algebra.



            // A line segment has zero mass.
            if (_vertexCount == 2)
            {
                massData.center = (_vertices[0] + _vertices[1]) * 0.5f;
                massData.mass = 0.0f;
                massData.I = 0.0f;
                return;
            }

	        float2 center = float2(0.0f, 0.0f);
	        float area = 0.0f;
	        float I = 0.0f;

	        // pRef is the reference point for forming triangles.
	        // It's location doesn't change the result (except for rounding error).
	        float2 pRef = float2(0.0f, 0.0f);

	        const float k_inv3 = 1.0f / 3.0f;

	        for (int i = 0; i < _vertexCount; ++i)
	        {
		        // Triangle vertices.
		        float2 p1 = pRef;
		        float2 p2 = _vertices[i];
		        float2 p3 = i + 1 < _vertexCount ? _vertices[i+1] : _vertices[0];

		        float2 e1 = p2 - p1;
		        float2 e2 = p3 - p1;

		        float D = MathUtils.Cross(e1, e2);

		        float triangleArea = 0.5f * D;
		        area += triangleArea;

		        // Area weighted centroid
		        center += (p1 + p2 + p3) * (triangleArea * k_inv3);

		        float px = p1.X, py = p1.Y;
		        float ex1 = e1.X, ey1 = e1.Y;
		        float ex2 = e2.X, ey2 = e2.Y;

		        float intx2 = k_inv3 * (0.25f * (ex1*ex1 + ex2*ex1 + ex2*ex2) + (px*ex1 + px*ex2)) + 0.5f*px*px;
		        float inty2 = k_inv3 * (0.25f * (ey1*ey1 + ey2*ey1 + ey2*ey2) + (py*ey1 + py*ey2)) + 0.5f*py*py;

		        I += D * (intx2 + inty2);
	        }

	        // Total mass
	        massData.mass = density * area;

	        // Center of mass

	        center *= 1.0f / area;
	        massData.center = center;

	        // Inertia tensor relative to the local origin.
	        massData.I = density * I;
        }

	    /// Get the vertex count.
        public int GetVertexCount() { return _vertexCount; }

	    /// Get a vertex by index.
        public float2 GetVertex(int index)
        {

	        return _vertices[index];
        }

        public float2 _centroid;
        public float2[] _vertices;
        public float2[] _normals;
	    public int _vertexCount;
    }
}
