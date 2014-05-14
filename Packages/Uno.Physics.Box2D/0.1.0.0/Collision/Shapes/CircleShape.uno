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
    public class CircleShape : Shape
    {
        public CircleShape()
        {
	        ShapeType = ShapeType.Circle;
	        _radius = 0.0f;
	        _p = float2(0);
        }

        /// Implement Shape.
        public override Shape Clone()
        {
            var shape = new CircleShape();
            shape.ShapeType = ShapeType;
            shape._radius = _radius;
            shape._p = _p;

            return shape;
        }

        /// @see b2Shape::GetChildCount
        public override int GetChildCount()
        {
            return 1;
        }

        /// @see Shape.TestPoint
        public override bool TestPoint(ref Transform transform, Float2 p)
        {
            Float2 center = transform.Position + MathUtils.Multiply(ref transform.R, _p);
	        Float2 d = p - center;
	        return Uno.Vector.Dot(d, d) <= _radius * _radius;
        }

        // Collision Detection in Interactive 3D Environments by Gino van den Bergen
        // From Section 3.1.2
        // x = s + a * r
        // norm(x) = radius
        public override bool RayCast(out RayCastOutput output, ref RayCastInput input, ref Transform transform, int childIndex)
        {
            output = new RayCastOutput();

	        float2 position = transform.Position + MathUtils.Multiply(ref transform.R, _p);
	        float2 s = input.p1 - position;
	        float b = Uno.Vector.Dot(s, s) - _radius * _radius;

	        // Solve quadratic equation.
            float2 r = input.p2 - input.p1;
	        float c =  Uno.Vector.Dot(s, r);
	        float rr = Uno.Vector.Dot(r, r);
	        float sigma = c * c - rr * b;

	        // Check for negative discriminant and short segment.
	        if (sigma < 0.0f || rr < Settings.b2_epsilon)
	        {
                return false;
	        }

	        // Find the point of intersection of the line with the circle.
	        float a = -(c + Math.Sqrt(sigma));

	        // Is the intersection point on the segment?
            if (0.0f <= a && a <= input.maxFraction * rr)
	        {
		        a /= rr;
                output.fraction = a;
                float2 norm1 = (s + a * r);
                norm1 = Vector.Normalize(norm1);
                output.normal = norm1;
                return true;
            }

            return false;
        }

        /// @see Shape.ComputeAABB
        public override void ComputeAABB(out AABB aabb, ref Transform transform, int childIndex)
        {
            Float2 p = transform.Position + MathUtils.Multiply(ref transform.R, _p);
	        aabb.lowerBound = float2(p.X - _radius, p.Y - _radius);
	        aabb.upperBound = float2(p.X + _radius, p.Y + _radius);
        }

        /// @see Shape.ComputeMass
        public override void ComputeMass(out MassData massData, float density)
        {
            massData.mass = density * Settings.b2_pi * _radius * _radius;
	        massData.center = _p;

	        // inertia about the local origin
	        massData.I = massData.mass * (0.5f * _radius * _radius + Uno.Vector.Dot(_p, _p));
        }

        /// Position
        public Float2 _p;
    }
}
