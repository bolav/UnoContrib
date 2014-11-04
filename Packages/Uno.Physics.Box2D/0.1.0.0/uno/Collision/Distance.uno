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
    /// A distance proxy is used by the GJK algorithm.
    /// It encapsulates any shape.
    public class DistanceProxy
    {
	    /// Initialize the proxy using the given shape. The shape
	    /// must remain in scope while the proxy is in use.
	    public void Set(Shape shape, int index)
        {
            switch (shape.ShapeType)
	        {
	        case ShapeType.Circle:
		        {
			        CircleShape circle = (CircleShape)shape;
                    _vertices[0] = circle._p;
			        _count = 1;
			        _radius = circle._radius;
		        }
		        break;

            case ShapeType.Polygon:
		        {
			        PolygonShape polygon = (PolygonShape)shape;
			        _vertices = polygon._vertices;
			        _count = polygon._vertexCount;
			        _radius = polygon._radius;
		        }
		        break;

	        case ShapeType.Chain:
	            {
		            ChainShape chain = (ChainShape)shape;

		            _buffer[0] = chain._vertices[index];
		            if (index + 1 < chain._count)
		            {
			            _buffer[1] = chain._vertices[index + 1];
		            }
		            else
		            {
			            _buffer[1] = chain._vertices[0];
		            }

                    _vertices[0] = _buffer[0];
                    _vertices[1] = _buffer[1];
		            _count = 2;
		            _radius = chain._radius;
	            }
	            break;

	        case ShapeType.Edge:
	            {
		            EdgeShape edge = (EdgeShape)shape;
                    _vertices[0] = edge._vertex1;
                    _vertices[1] = edge._vertex2;
		            _count = 2;
		            _radius = edge._radius;
                }
                break;

	        default:
                break;
	        }

        }

	    /// Get the supporting vertex index in the given direction.
	    public int GetSupport(float2 d)
        {
            int bestIndex = 0;
            float bestValue = Uno.Vector.Dot(_vertices[0], d);
            for (int i = 1; i < _count; ++i)
            {
                float value = Uno.Vector.Dot(_vertices[i], d);
                if (value > bestValue)
                {
                    bestIndex = i;
                    bestValue = value;
                }
            }

            return bestIndex;
        }

	    /// Get the supporting vertex in the given direction.
	    public float2 GetSupportVertex(float2 d)
        {
            int bestIndex = 0;
            float bestValue = Uno.Vector.Dot(_vertices[0], d);
            for (int i = 1; i < _count; ++i)
            {
                float value = Uno.Vector.Dot(_vertices[i], d);
                if (value > bestValue)
                {
                    bestIndex = i;
                    bestValue = value;
                }
            }

            return _vertices[bestIndex];
        }

	    /// Get the vertex count.
	    public int GetVertexCount()
        {
            return _count;
        }

	    /// Get a vertex by index. Used by b2Distance.
	    public float2 GetVertex(int index)
        {
            return _vertices[index];
        }

	    internal float2[] _vertices = new float2[8];
        internal float2[] _buffer = new float2[2];
	    internal int _count;
	    internal float _radius;
    }



    /// Used to warm start ComputeDistance.
    /// Set count to zero on first call.
    public class SimplexCache
    {
	    public float metric;		///< length or area
        public ushort count;
        public byte[] indexA = new byte[3];	///< vertices on shape A
        public byte[] indexB = new byte[3];	///< vertices on shape B
    }

    /// Input for ComputeDistance.
    /// You have to option to use the shape radii
    /// in the computation. Even
    public class DistanceInput
    {
        public DistanceProxy proxyA = new DistanceProxy();
        public DistanceProxy proxyB = new DistanceProxy();
        public Transform transformA;
        public Transform transformB;
        public bool useRadii;
    }

    /// Output for ComputeDistance.
    public struct DistanceOutput
    {
        public float2 pointA;		///< closest point on shapeA
        public float2 pointB;		///< closest point on shapeB
        public float distance;
        public int iterations;	///< number of GJK iterations used
    }

    internal struct SimplexVertex
    {
        public float2 wA;		// support point in proxyA
        public float2 wB;		// support point in proxyB
        public float2 w;		// wB - wA
        public float a;		// barycentric coordinate for closest point
        public int indexA;	// wA index
        public int indexB;	// wB index
    }

    internal class Simplex
    {

	    internal void ReadCache(ref SimplexCache cache,
					    ref DistanceProxy proxyA, ref Transform transformA,
                        ref DistanceProxy proxyB, ref Transform transformB)
	    {
		    // Copy data from cache.
		    _count = cache.count;
		    for (int i = 0; i < _count; ++i)
		    {
			    SimplexVertex v = _v[i];
			    v.indexA = cache.indexA[i];
			    v.indexB = cache.indexB[i];
			    float2 wALocal = proxyA.GetVertex(v.indexA);
                float2 wBLocal = proxyB.GetVertex(v.indexB);
			    v.wA = MathUtils.Multiply(ref transformA, wALocal);
			    v.wB = MathUtils.Multiply(ref transformB, wBLocal);
			    v.w = v.wB - v.wA;
			    v.a = 0.0f;
                _v[i] = v;
		    }

		    // Compute the new simplex metric, if it is substantially different than
		    // old metric then flush the simplex.
		    if (_count > 1)
		    {
			    float metric1 = cache.metric;
			    float metric2 = GetMetric();
			    if (metric2 < 0.5f * metric1 || 2.0f * metric1 < metric2 || metric2 < Settings.b2_epsilon)
			    {
				    // Reset the simplex.
				    _count = 0;
			    }
		    }

		    // If the cache is empty or invalid ...
		    if (_count == 0)
		    {
			    SimplexVertex v = _v[0];
			    v.indexA = 0;
			    v.indexB = 0;
			    float2 wALocal = proxyA.GetVertex(0);
                float2 wBLocal = proxyB.GetVertex(0);
			    v.wA = MathUtils.Multiply(ref transformA, wALocal);
			    v.wB = MathUtils.Multiply(ref transformB, wBLocal);
			    v.w = v.wB - v.wA;
                _v[0] = v;
			    _count = 1;
		    }
	    }

        internal void WriteCache(ref SimplexCache cache)
	    {
		    cache.metric = GetMetric();
		    cache.count = (ushort)_count;
		    for (int i = 0; i < _count; ++i)
		    {
                cache.indexA[i] = (byte)(_v[i].indexA);
                cache.indexB[i] = (byte)(_v[i].indexB);
		    }
	    }

        internal float2 GetSearchDirection()
	    {
		    switch (_count)
		    {
		    case 1:
			    return -_v[0].w;

		    case 2:
				    float2 e12 = _v[1].w - _v[0].w;
				    float sgn = MathUtils.Cross(e12, _v[0].w * -1.0f);
				    return (sgn > 0.0f)
						? MathUtils.Cross(1.0f, e12)
						: MathUtils.Cross(e12, 1.0f);
		    default:
			    return float2(0);
		    }
	    }

        internal float2 GetClosestPoint()
	    {
		    switch (_count)
		    {
		    case 0:
			    return float2(0);

		    case 1:
			    return _v[0].w;

		    case 2:
			    return _v[0].a * _v[0].w + _v[1].a * _v[1].w;

		    case 3:
			    return float2(0);

		    default:
			    return float2(0);
		    }
	    }

        internal void GetWitnessPoints(out float2 pA, out float2 pB)
	    {
		    switch (_count)
		    {
		    case 0:
                pA = float2(0);
                pB = float2(0);
			    break;

		    case 1:
			    pA = _v[0].wA;
			    pB = _v[0].wB;
			    break;

		    case 2:
			    pA = _v[0].a * _v[0].wA + _v[1].a * _v[1].wA;
			    pB = _v[0].a * _v[0].wB + _v[1].a * _v[1].wB;
			    break;

		    case 3:
			    pA = _v[0].a * _v[0].wA + _v[1].a * _v[1].wA + _v[2].a * _v[2].wA;
			    pB = pA;
			    break;

		    default:
                throw new Exception();
		    }
	    }

        internal float GetMetric()
	    {
		    switch (_count)
		    {
		    case 0:
			    return 0.0f;

		    case 1:
			    return 0.0f;

		    case 2:
                return Vector.Length(_v[0].w - _v[1].w);

		    case 3:
			    return MathUtils.Cross(_v[1].w - _v[0].w, _v[2].w - _v[0].w);

		    default:
			    return 0.0f;
		    }
	    }

        // Solve a line segment using barycentric coordinates.
        //
        // p = a1 * w1 + a2 * w2
        // a1 + a2 = 1
        //
        // The vector from the origin to the closest point on the line is
        // perpendicular to the line.
        // e12 = w2 - w1
        // dot(p, e) = 0
        // a1 * dot(w1, e) + a2 * dot(w2, e) = 0
        //
        // 2-by-2 linear system
        // [1      1     ][a1] = [1]
        // [w1.e12 w2.e12][a2] = [0]
        //
        // Define
        // d12_1 =  dot(w2, e12)
        // d12_2 = -dot(w1, e12)
        // d12 = d12_1 + d12_2
        //
        // Solution
        // a1 = d12_1 / d12
        // a2 = d12_2 / d12

        internal void Solve2()
        {
            float2 w1 = _v[0].w;
            float2 w2 = _v[1].w;
            float2 e12 = w2 - w1;

            // w1 region
            float d12_2 = -Uno.Vector.Dot(w1, e12);
            if (d12_2 <= 0.0f)
            {
                // a2 <= 0, so we clamp it to 0
                var v0 = _v[0];
                v0.a = 1.0f;
                _v[0] = v0;
                _count = 1;
                return;
            }

            // w2 region
            float d12_1 = Uno.Vector.Dot(w2, e12);
            if (d12_1 <= 0.0f)
            {
                // a1 <= 0, so we clamp it to 0
                var v1 = _v[1];
                v1.a = 1.0f;
                _v[1] = v1;
                _count = 1;
                _v[0] = _v[1];
                return;
            }

            // Must be in e12 region.
            float inv_d12 = 1.0f / (d12_1 + d12_2);
            var v0_2 = _v[0];
            var v1_2 = _v[1];
            v0_2.a = d12_1 * inv_d12;
            v1_2.a = d12_2 * inv_d12;
            _v[0] = v0_2;
            _v[1] = v1_2;
            _count = 2;
        }

        // Possible regions:
        // - points[2]
        // - edge points[0]-points[2]
        // - edge points[1]-points[2]
        // - inside the triangle
        internal void Solve3()
        {
            float2 w1 = _v[0].w;
            float2 w2 = _v[1].w;
            float2 w3 = _v[2].w;

            // Edge12
            // [1      1     ][a1] = [1]
            // [w1.e12 w2.e12][a2] = [0]
            // a3 = 0
            float2 e12 = w2 - w1;
            float w1e12 = Uno.Vector.Dot(w1, e12);
            float w2e12 = Uno.Vector.Dot(w2, e12);
            float d12_1 = w2e12;
            float d12_2 = -w1e12;

            // Edge13
            // [1      1     ][a1] = [1]
            // [w1.e13 w3.e13][a3] = [0]
            // a2 = 0
            float2 e13 = w3 - w1;
            float w1e13 = Uno.Vector.Dot(w1, e13);
            float w3e13 = Uno.Vector.Dot(w3, e13);
            float d13_1 = w3e13;
            float d13_2 = -w1e13;

            // Edge23
            // [1      1     ][a2] = [1]
            // [w2.e23 w3.e23][a3] = [0]
            // a1 = 0
            float2 e23 = w3 - w2;
            float w2e23 = Uno.Vector.Dot(w2, e23);
            float w3e23 = Uno.Vector.Dot(w3, e23);
            float d23_1 = w3e23;
            float d23_2 = -w2e23;

            // Triangle123
            float n123 = MathUtils.Cross(e12, e13);

            float d123_1 = n123 * MathUtils.Cross(w2, w3);
            float d123_2 = n123 * MathUtils.Cross(w3, w1);
            float d123_3 = n123 * MathUtils.Cross(w1, w2);

            // w1 region
            if (d12_2 <= 0.0f && d13_2 <= 0.0f)
            {
                var v0_1 = _v[0];
                v0_1.a = 1.0f;
                _v[0] = v0_1;
                _count = 1;
                return;
            }

            // e12
            if (d12_1 > 0.0f && d12_2 > 0.0f && d123_3 <= 0.0f)
            {
                float inv_d12 = 1.0f / (d12_1 + d12_2);
                var v0_2 = _v[0];
                var v1_2 = _v[1];
                v0_2.a = d12_1 * inv_d12;
                v1_2.a = d12_2 * inv_d12;
                _v[0] = v0_2;
                _v[1] = v1_2;
                _count = 2;
                return;
            }

            // e13
            if (d13_1 > 0.0f && d13_2 > 0.0f && d123_2 <= 0.0f)
            {
                float inv_d13 = 1.0f / (d13_1 + d13_2);
                var v0_3 = _v[0];
                var v2_3 = _v[2];
                v0_3.a = d13_1 * inv_d13;
                v2_3.a = d13_2 * inv_d13;
                _v[0] = v0_3;
                _v[2] = v2_3;
                _count = 2;
                _v[1] = _v[2];
                return;
            }

            // w2 region
            if (d12_1 <= 0.0f && d23_2 <= 0.0f)
            {
                var v1_4 = _v[1];
                v1_4.a = 1.0f;
                _v[1] = v1_4;
                _count = 1;
                _v[0] = _v[1];
                return;
            }

            // w3 region
            if (d13_1 <= 0.0f && d23_1 <= 0.0f)
            {
                var v2_5 = _v[2];
                v2_5.a = 1.0f;
                _v[2] = v2_5;
                _count = 1;
                _v[0] = _v[2];
                return;
            }

            // e23
            if (d23_1 > 0.0f && d23_2 > 0.0f && d123_1 <= 0.0f)
            {
                float inv_d23 = 1.0f / (d23_1 + d23_2);
                var v1_6 = _v[1];
                var v2_6 = _v[2];
                v1_6.a = d23_1 * inv_d23;
                v2_6.a = d23_2 * inv_d23;
                _v[1] = v1_6;
                _v[2] = v2_6;
                _count = 2;
                _v[0] = _v[2];
                return;
            }

            // Must be in triangle123
            float inv_d123 = 1.0f / (d123_1 + d123_2 + d123_3);
            var v0_7 = _v[0];
            var v1_7 = _v[1];
            var v2_7 = _v[2];
            v0_7.a = d123_1 * inv_d123;
            v1_7.a = d123_2 * inv_d123;
            v2_7.a = d123_3 * inv_d123;
            _v[0] = v0_7;
            _v[1] = v1_7;
            _v[2] = v2_7;
            _count = 3;
        }

	    internal SimplexVertex[] _v = new SimplexVertex[3];
        internal int _count;
    }

    public static class Distance
    {
        public static void ComputeDistance(out DistanceOutput output,
				                           out SimplexCache cache,
				                           ref DistanceInput input)
        {
            cache = new SimplexCache();
	        ++b2_gjkCalls;

	        // Initialize the simplex.
	        Simplex simplex = new Simplex();
            simplex.ReadCache(ref cache, ref input.proxyA, ref input.transformA, ref input.proxyB, ref input.transformB);

	        // Get simplex vertices as an array.
	        int k_maxIters = 20;

	        // These store the vertices of the last simplex so that we
	        // can check for duplicates and prevent cycling.
            var saveA = new int[3];
            var saveB = new int[3];
	        int saveCount = 0;

	        float2 closestPoint = simplex.GetClosestPoint();
	        float distanceSqr1 = Vector.LengthSquared(closestPoint);
	        float distanceSqr2 = distanceSqr1;

	        // Main iteration loop.
	        int iter = 0;
	        while (iter < k_maxIters)
	        {
		        // Copy simplex so we can identify duplicates.
		        saveCount = simplex._count;
		        for (int i = 0; i < saveCount; ++i)
		        {
			        saveA[i] = simplex._v[i].indexA;
                    saveB[i] = simplex._v[i].indexB;
		        }

		        switch (simplex._count)
		        {
		        case 1:
			        break;

		        case 2:
			        simplex.Solve2();
			        break;

		        case 3:
			        simplex.Solve3();
			        break;

		        default:
                    break;
		        }

		        // If we have 3 points, then the origin is in the corresponding triangle.
		        if (simplex._count == 3)
		        {
			        break;
		        }

		        // Compute closest point.
		        float2 p = simplex.GetClosestPoint();
		        distanceSqr2 = Vector.LengthSquared(p);

		        // Ensure progress
		        if (distanceSqr2 >= distanceSqr1)
		        {
			        //break;
		        }
		        distanceSqr1 = distanceSqr2;

		        // Get search direction.
		        float2 d = simplex.GetSearchDirection();

		        // Ensure the search direction is numerically fit.
		        if (Vector.LengthSquared(d) < Settings.b2_epsilon * Settings.b2_epsilon)
		        {
			        // The origin is probably contained by a line segment
			        // or triangle. Thus the shapes are overlapped.

			        // We can't return zero here even though there may be overlap.
			        // In case the simplex is a point, segment, or triangle it is difficult
			        // to determine if the origin is contained in the CSO or very close to it.
			        break;
		        }

		        // Compute a tentative new simplex vertex using support points.
                SimplexVertex simpleVertex = simplex._v[simplex._count];
                simpleVertex.indexA = input.proxyA.GetSupport(MathUtils.MultiplyT(ref input.transformA.q, d * -1.0f));
                simpleVertex.wA = MathUtils.Multiply(ref input.transformA, input.proxyA.GetVertex(simpleVertex.indexA));

                simpleVertex.indexB = input.proxyB.GetSupport(MathUtils.MultiplyT(ref input.transformB.q, d));
                simpleVertex.wB = MathUtils.Multiply(ref input.transformB, input.proxyB.GetVertex(simpleVertex.indexB));
		        simpleVertex.w = simpleVertex.wB - simpleVertex.wA;
                simplex._v[simplex._count] = simpleVertex;

		        // Iteration count is equated to the number of support point calls.
		        ++iter;
		        ++b2_gjkIters;

		        // Check for duplicate support points. This is the main termination criteria.
		        bool duplicate = false;
		        for (int i = 0; i < saveCount; ++i)
		        {
			        if (simpleVertex.indexA == saveA[i] && simpleVertex.indexB == saveB[i])
			        {
				        duplicate = true;
				        break;
			        }
		        }

		        // If we found a duplicate support point we must exit to avoid cycling.
		        if (duplicate)
		        {
			        break;
		        }

		        // New vertex is ok and needed.
		        ++simplex._count;
	        }

	        b2_gjkMaxIters = Math.Max(b2_gjkMaxIters, iter);

	        // Prepare output.
	        simplex.GetWitnessPoints(out output.pointA, out output.pointB);
	        output.distance = Vector.Length(output.pointA - output.pointB);
	        output.iterations = iter;

	        // Cache the simplex.
	        simplex.WriteCache(ref cache);

	        // Apply radii if requested.
	        if (input.useRadii)
	        {
                float rA = input.proxyA._radius;
                float rB = input.proxyB._radius;

		        if (output.distance > rA + rB && output.distance > Settings.b2_epsilon)
		        {
			        // Shapes are still no overlapped.
			        // Move the witness points to the outer surface.
			        output.distance -= rA + rB;
			        float2 normal = output.pointB - output.pointA;
			        Vector.Normalize(normal);
			        output.pointA += rA * normal;
			        output.pointB -= rB * normal;
		        }
		        else
		        {
			        // Shapes are overlapped when radii are considered.
			        // Move the witness points to the middle.
			        float2 p = 0.5f * (output.pointA + output.pointB);
			        output.pointA = p;
			        output.pointB = p;
			        output.distance = 0.0f;
		        }
	        }
        }

        public static int b2_gjkCalls, b2_gjkIters, b2_gjkMaxIters;
    }
}
