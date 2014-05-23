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
    public static class MathUtils
    {
        public static float Pi = 3.141592f;

        public static float Cross(float2 a, float2 b)
        {
            return a.X * b.Y - a.Y * b.X;
        }

        public static float2 Cross(float2 a, float s)
        {
            return float2(s * a.Y, -s * a.X);
        }

        public static float2 Cross(float s, float2 a)
        {
            return float2(-s * a.Y, s * a.X);
        }

        public static float2 Abs(float2 v)
        {
            return float2(Math.Abs(v.X), Math.Abs(v.Y));
        }

        public static float2 Multiply(ref Mat22 A, float2 v)
        {
            return float2(A.col1.X * v.X + A.col2.X * v.Y, A.col1.Y * v.X + A.col2.Y * v.Y);
        }

        public static float2 MultiplyT(ref Mat22 A, float2 v)
        {
            return float2(Dot(v, A.col1), Dot(v, A.col2));
        }
        public static float Dot(float2 a, float2 b)
        {
            return a.X * b.X + a.Y * b.Y;
        }

        public static float2 Min(float2 a, float2 b)
        {
            return float2(Math.Min(a.X, b.X), Math.Min(a.Y, b.Y));
        }

        public static float2 Max(float2 a, float2 b)
        {
            return float2(Math.Max(a.X, b.X), Math.Max(a.Y, b.Y));
        }

        public static float2 Multiply(ref Transform T, float2 v)
        {
            float x = T.Position.X + T.R.col1.X * v.X + T.R.col2.X * v.Y;
            float y = T.Position.Y + T.R.col1.Y * v.X + T.R.col2.Y * v.Y;

            return float2(x, y);
        }

        public static float2 MultiplyT(ref Transform T, float2 v)
        {
            return MultiplyT(ref T.R, v - T.Position);
        }

        // A^T * B
        public static void MultiplyT(ref Mat22 A, ref Mat22 B, out Mat22 C)
        {
            float2 c1 = float2(Uno.Vector.Dot(A.col1, B.col1), Uno.Vector.Dot(A.col2, B.col1));
            float2 c2 = float2(Uno.Vector.Dot(A.col1, B.col2), Uno.Vector.Dot(A.col2, B.col2));
	        C = new Mat22(c1, c2);
        }

        public static void MultiplyT(ref Transform A, ref Transform B, out Transform C)
        {
            Mat22 R;
            MultiplyT(ref A.R, ref B.R, out R);
            C = new Transform(B.Position - A.Position, ref R);
        }

        public static void Swap<T>(ref T a, ref T b)
        {
            T tmp = a;
            a = b;
            b = tmp;
        }

        public static float DistanceSquared(float2 value1, float2 value2)
        {
            float x = value1.X - value2.X;
            float y = value1.Y - value2.Y;

            return (x * x) + (y * y);
        }

        /// This function is used to ensure that a floating point number is
        /// not a NaN or infinity.
        public static bool IsValid(float x)
        {
			return true;
			/*
            if (float.IsNaN(x))
            {
                // NaN.
                return false;
            }

            return !float.IsInfinity(x);*/
        }

        public static bool IsValid(float2 x)
        {
            return IsValid(x.X) && IsValid(x.Y);
        }

        public static int Clamp(int a, int low, int high)
        {
            return Math.Max(low, Math.Min(a, high));
        }

        public static float Clamp(float a, float low, float high)
        {
            return Math.Max(low, Math.Min(a, high));
        }

        public static float2 Clamp(float2 a, float2 low, float2 high)
        {
            return MathUtils.Max(low, MathUtils.Min(a, high));
        }
    }

        /// A 2-by-2 matrix. Stored in column-major order.
    public struct Mat22
    {
	    /// construct this matrix using columns.
        public Mat22(float2 c1, float2 c2)
	    {
		    col1 = c1;
		    col2 = c2;
	    }

	    /// construct this matrix using scalars.
        public Mat22(float a11, float a12, float a21, float a22)
	    {
            col1 = float2(a11, a21);
            col2 = float2(a12, a22);
		}

	    /// construct this matrix using an angle. This matrix becomes
	    /// an orthonormal rotation matrix.
        public Mat22(float angle)
	    {
		    // TODO_ERIN compute sin+cos together.
            float c = (float)Math.Cos(angle), s = (float)Math.Sin(angle);
            col1 = float2(c, s);
            col2 = float2(-s, c);
	    }

	    /// Initialize this matrix using columns.
        public void Set(float2 c1, float2 c2)
	    {
		    col1 = c1;
		    col2 = c2;
	    }

	    /// Initialize this matrix using an angle. This matrix becomes
	    /// an orthonormal rotation matrix.
        public void Set(float angle)
	    {
            float c = (float)Math.Cos(angle), s = (float)Math.Sin(angle);
		    col1.X = c; col2.X = -s;
		    col1.Y = s; col2.Y = c;
	    }

	    /// Set this to the identity matrix.
        public void SetIdentity()
	    {
		    col1.X = 1.0f; col2.X = 0.0f;
		    col1.Y = 0.0f; col2.Y = 1.0f;
	    }

	    /// Set this matrix to all zeros.
        public void SetZero()
	    {
		    col1.X = 0.0f; col2.X = 0.0f;
		    col1.Y = 0.0f; col2.Y = 0.0f;
	    }

	    /// Extract the angle from this matrix (assumed to be
	    /// a rotation matrix).
        public float GetAngle()
	    {
            return (float)Math.Atan2(col1.Y, col1.X);
	    }

        public Mat22 GetInverse()
	    {
		    float a = col1.X, b = col2.X, c = col1.Y, d = col2.Y;
		    float det = a * d - b * c;
            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return new Mat22(float2(det * d, -det * c), float2(-det * b, det * a));
	    }

	    /// Solve A * x = b, where b is a column vector. This is more efficient
	    /// than computing the inverse in one-shot cases.
        public float2 Solve(float2 b)
	    {
		    float a11 = col1.X, a12 = col2.X, a21 = col1.Y, a22 = col2.Y;
		    float det = a11 * a22 - a12 * a21;
            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return float2(det * (a22 * b.X - a12 * b.Y), det * (a11 * b.Y - a21 * b.X));
	    }

        public static void Add (ref Mat22 A, ref Mat22 B, out Mat22 R)
        {
            R = new Mat22(A.col1 + B.col1, A.col2 + B.col2);
        }

        public float2 col1, col2;
    }

    /// A 3-by-3 matrix. Stored in column-major order.
    public struct Mat33
    {

	    /// construct this matrix using columns.
        public Mat33(float3 c1, float3 c2, float3 c3)
	    {
		    col1 = c1;
		    col2 = c2;
		    col3 = c3;
	    }

	    /// Set this matrix to all zeros.
        public void SetZero()
	    {
            col1 = float3(0);
            col2 = float3(0);
            col3 = float3(0);
	    }

	    /// Solve A * x = b, where b is a column vector. This is more efficient
	    /// than computing the inverse in one-shot cases.
        public float3 Solve33(float3 b)
        {
            float det = Vector.Dot(col1, Vector.Cross(col2, col3));
            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return float3( det * Vector.Dot(b, Vector.Cross(col2, col3)),
                                det * Vector.Dot(col1, Vector.Cross(b, col3)),
                                det * Vector.Dot(col1, Vector.Cross(col2, b)));
        }

	    /// Solve A * x = b, where b is a column vector. This is more efficient
	    /// than computing the inverse in one-shot cases. Solve only the upper
	    /// 2-by-2 matrix equation.
        public float2 Solve22(float2 b)
        {
            float a11 = col1.X, a12 = col2.X, a21 = col1.Y, a22 = col2.Y;
            float det = a11 * a22 - a12 * a21;

            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return float2(det * (a22 * b.X - a12 * b.Y), det * (a11 * b.Y - a21 * b.X));
        }

        public float3 col1, col2, col3;
    }

    /// A transform contains translation and rotation. It is used to represent
    /// the position and orientation of rigid frames.
    public struct Transform
    {
	    /// Initialize using a position vector and a rotation matrix.
        public Transform(float2 position, ref Mat22 r)
        {
            Position = position;
            R = r;
        }

	    /// Set this to the identity transform.
        public void SetIdentity()
	    {
		    Position = float2(0);
		    R.SetIdentity();
	    }

	    /// Set this based on the position and angle.
        public void Set(float2 p, float angle)
	    {
		    Position = p;
		    R.Set(angle);
	    }

	    /// Calculate the angle that the rotation matrix represents.
        public float GetAngle()
	    {
		    return (float)Math.Atan2(R.col1.Y, R.col1.X);
	    }

        public float2 Position;
        public Mat22 R;
    }

    /// This describes the motion of a body/shape for TOI computation.
    /// Shapes are defined with respect to the body origin, which may
    /// no coincide with the center of mass. However, to support dynamics
    /// we must interpolate the center of mass position.
    public struct Sweep
    {
	    /// Get the interpolated transform at a specific time.
	    /// @param alpha is a factor in [0,1], where 0 indicates t0.
	    public void GetTransform(out Transform xf, float alpha)
        {
            xf = new Transform();
            xf.Position = c0 * (1.0f - alpha) + c * alpha;
            float angle = a0 * (1.0f - alpha) + a * alpha;
	        xf.R.Set(angle);

	        // Shift to origin
	        xf.Position -= MathUtils.Multiply(ref xf.R, localCenter);
        }

	    /// Advance the sweep forward, yielding a new initial state.
	    /// @param t the new initial time.
	    public void Advance(float t)
        {
            c0 = c0 * (1.0f - t) + c * t;
            a0 = a0 * (1.0f - t) + a * t;
        }

        /// Normalize the angles.
        public void Normalize()
        {
            float twoPi = 2.0f * (float)MathUtils.Pi;
            float d = twoPi * (float)Math.Floor(a0 / twoPi);
            a0 -= d;
            a -= d;
        }

        public float2 localCenter;	///< local center of mass position
        public float2 c0, c;		///< center world positions
        public float a0, a;		///< world angles
    }
}
