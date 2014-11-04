/*
* Box2D: r313
* Box2D.XNA port of Box2D:
* Copyright (c) 2009 Brandon Furtwangler, Nathan Furtwangler
*
* Original source Box2D:
* Copyright (c) 2006-2009 Erin Catto http://www.box2d.org
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

		/// Multiply a matrix times a vector. If a rotation matrix is provided,
		/// then this transforms the vector from one frame to another.
        public static float2 Multiply(ref Mat22 A, float2 v)
        {
            return float2(A.ex.X * v.X + A.ey.X * v.Y, A.ex.Y * v.X + A.ey.Y * v.Y);
        }

		/// Multiply a matrix transpose times a vector. If a rotation matrix is provided,
		/// then this transforms the vector from one frame to another (inverse transform).
        public static float2 MultiplyT(ref Mat22 A, float2 v)
        {
            return float2(Dot(v, A.ex), Dot(v, A.ey));
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
			float x = (T.q2.c * v.X - T.q2.s * v.Y) + T.p.X;
			float y = (T.q2.s * v.X + T.q2.c * v.Y) + T.p.Y;

            return float2(x, y);
        }

        public static float2 MultiplyT(ref Transform T, float2 v)
        {
			float px = v.X - T.p.X;
			float py = v.Y - T.p.Y;
			float x = (T.q2.c * px + T.q2.s * py);
			float y = (-T.q2.s * px + T.q2.c * py);

			return float2(x, y);
        }

		// v2 = A.q.Rot(B.q.Rot(v1) + B.p) + A.p
		//    = (A.q * B.q).Rot(v1) + A.q.Rot(B.p) + A.p
		public static Transform Multiply(ref Transform A, ref Transform B)
		{
			Transform C = new Transform();
			Multiply(ref A.q, ref B.q, out C.q);
			C.p = Multiply(ref A.q, B.p) + A.p;
			return C;
		}

		// v2 = A.q' * (B.q * v1 + B.p - A.p)
		//    = A.q' * B.q * v1 + A.q' * (B.p - A.p)
        public static void MultiplyT(ref Transform A, ref Transform B, out Transform C)
		{
			C = new Transform();
			MultiplyT(ref A.q, ref B.q, out C.q);
			C.p = MultiplyT(ref A.q, B.p - A.p);
		}

        // A * B
        public static void Multiply(ref Mat22 A, ref Mat22 B, out Mat22 C)
        {
			C = new Mat22(Multiply(ref A, B.ex), Multiply(ref A, B.ey));
        }

        // A^T * B
        public static void MultiplyT(ref Mat22 A, ref Mat22 B, out Mat22 C)
        {
            float2 c1 = float2(Uno.Vector.Dot(A.ex, B.ex), Uno.Vector.Dot(A.ey, B.ex));
            float2 c2 = float2(Uno.Vector.Dot(A.ex, B.ey), Uno.Vector.Dot(A.ey, B.ey));
	        C = new Mat22(c1, c2);
        }

		/// Multiply a matrix times a vector.
		public static float2 Multiply22(ref Mat33 A, ref float2 v)
		{
			return float2(A.ex.X * v.X + A.ey.X * v.Y, A.ex.Y * v.X + A.ey.Y * v.Y);
		}

		/// Multiply two rotations: q * r
		public static Rot Multiply(ref Rot q, ref Rot r)
		{
			// [qc -qs] * [rc -rs] = [qc*rc-qs*rs -qc*rs-qs*rc]
			// [qs  qc]   [rs  rc]   [qs*rc+qc*rs -qs*rs+qc*rc]
			// s = qs * rc + qc * rs
			// c = qc * rc - qs * rs
			Rot qr = new Rot();
			qr.s = q.s * r.c + q.c * r.s;
			qr.c = q.c * r.c - q.s * r.s;
			return qr;
		}

		/// Transpose multiply two rotations: qT * r
		public static Rot MultiplyT(ref Rot q, ref Rot r)
		{
			// [ qc qs] * [rc -rs] = [qc*rc+qs*rs -qc*rs+qs*rc]
			// [-qs qc]   [rs  rc]   [-qs*rc+qc*rs qs*rs+qc*rc]
			// s = qc * rs - qs * rc
			// c = qc * rc + qs * rs
			Rot qr = new Rot();
			qr.s = q.c * r.s - q.s * r.c;
			qr.c = q.c * r.c + q.s * r.s;
			return qr;
		}

		/// Rotate a vector
		public static float2 Multiply(ref Rot q, ref float2 v)
		{
			return float2(q.c * v.X - q.s * v.Y, q.s * v.X + q.c * v.Y);
		}

		/// Inverse rotate a vector
		public static float2 MultiplyT(ref Rot q, ref float2 v)
		{
			return float2(q.c * v.X + q.s * v.Y, -q.s * v.X + q.c * v.Y);
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

        /// This function is used to ensure that a floating point number is not a NaN or infinity.
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
		    ex = c1;
		    ey = c2;
	    }

	    /// construct this matrix using scalars.
        public Mat22(float a11, float a12, float a21, float a22)
	    {
            ex = float2(a11, a21);
            ey = float2(a12, a22);
	    }

		// XXX: DELETE THIS
        public Mat22(float angle)
           {
                   // TODO_ERIN compute sin+cos together.
            float c = (float)Math.Cos(angle), s = (float)Math.Sin(angle);
            ex = float2(c, s);
            ey = float2(-s, c);
		}

	    /// Initialize this matrix using columns.
        public void Set(float2 c1, float2 c2)
	    {
		    ex = c1;
		    ey = c2;
	    }

        public void Set(float angle)
        {
            float c = (float)Math.Cos(angle), s = (float)Math.Sin(angle);
            ex.X = c; ey.X = -s;
            ex.Y = s; ey.Y = c;
		}

	    /// Set this to the identity matrix.
        public void SetIdentity()
	    {
		    ex.X = 1.0f; ey.X = 0.0f;
		    ex.Y = 0.0f; ey.Y = 1.0f;
	    }

	    /// Set this matrix to all zeros.
        public void SetZero()
	    {
		    ex.X = 0.0f; ey.X = 0.0f;
		    ex.Y = 0.0f; ey.Y = 0.0f;
	    }

        public Mat22 GetInverse()
	    {
		    float a = ex.X, b = ey.X, c = ex.Y, d = ey.Y;
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
		    float a11 = ex.X, a12 = ey.X, a21 = ex.Y, a22 = ey.Y;
		    float det = a11 * a22 - a12 * a21;
            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return float2(det * (a22 * b.X - a12 * b.Y), det * (a11 * b.Y - a21 * b.X));
	    }

        public static void Add (ref Mat22 A, ref Mat22 B, out Mat22 R)
        {
            R = new Mat22(A.ex + B.ex, A.ey + B.ey);
        }

        public float2 ex, ey;
    }

    /// A 3-by-3 matrix. Stored in column-major order.
    public struct Mat33
    {

	    /// construct this matrix using columns.
        public Mat33(float3 c1, float3 c2, float3 c3)
	    {
		    ex = c1;
		    ey = c2;
		    ez = c3;
	    }

	    /// Set this matrix to all zeros.
        public void SetZero()
	    {
            ex = float3(0);
            ey = float3(0);
            ez = float3(0);
	    }

	    /// Solve A * x = b, where b is a column vector. This is more efficient
	    /// than computing the inverse in one-shot cases.
        public float3 Solve33(float3 b)
        {
            float det = Vector.Dot(ex, Vector.Cross(ey, ez));
            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return float3( det * Vector.Dot(b, Vector.Cross(ey, ez)),
                                det * Vector.Dot(ex, Vector.Cross(b, ez)),
                                det * Vector.Dot(ex, Vector.Cross(ey, b)));
        }

	    /// Solve A * x = b, where b is a column vector. This is more efficient
	    /// than computing the inverse in one-shot cases. Solve only the upper
	    /// 2-by-2 matrix equation.
        public float2 Solve22(float2 b)
        {
            float a11 = ex.X, a12 = ey.X, a21 = ex.Y, a22 = ey.Y;
            float det = a11 * a22 - a12 * a21;

            if (det != 0.0f)
            {
                det = 1.0f / det;
            }

            return float2(det * (a22 * b.X - a12 * b.Y), det * (a11 * b.Y - a21 * b.X));
        }

		/// Get the inverse of this matrix as a 2-by-2.
		/// Returns the zero matrix if singular.
		void GetInverse22(out Mat33 M)
		{
			float a = ex.X, b = ey.X, c = ex.Y, d = ey.Y;
			float det = a * d - b * c;
			if (det != 0.0f)
			{
				det = 1.0f / det;
			}

			M.ex.X =  det * d;	M.ey.X = -det * b; M.ex.Z = 0.0f;
			M.ex.Y = -det * c;	M.ey.Y =  det * a; M.ey.Z = 0.0f;
			M.ez.X = 0.0f; M.ez.Y = 0.0f; M.ez.Z = 0.0f;
		}

		/// Get the symmetric inverse of this matrix as a 3-by-3.
		/// Returns the zero matrix if singular.
		void GetSymInverse33(out Mat33 M)
		{
			float det = Uno.Vector.Dot(ex, Uno.Vector.Cross(ey, ez));
			if (det != 0.0f)
			{
				det = 1.0f / det;
			}

			float a11 = ex.X, a12 = ey.X, a13 = ez.X;
			float a22 = ey.Y, a23 = ez.Y;
			float a33 = ez.Z;

			M.ex.X = det * (a22 * a33 - a23 * a23);
			M.ex.Y = det * (a13 * a23 - a12 * a33);
			M.ex.Z = det * (a12 * a23 - a13 * a22);

			M.ey.X = M.ex.Y;
			M.ey.Y = det * (a11 * a33 - a13 * a13);
			M.ey.Z = det * (a13 * a12 - a11 * a23);

			M.ez.X = M.ex.Z;
			M.ez.Y = M.ey.Z;
			M.ez.Z = det * (a11 * a22 - a12 * a12);
		}


        public float3 ex, ey, ez;
    }

	/// Rotation
	public struct Rot
	{
		/// Initialize from an angle in radians
		public Rot(float angle)
		{
			/// TODO_ERIN optimize
			s = Math.Sin(angle);
			c = Math.Cos(angle);
		}

		/// Set using an angle in radians.
		void Set(float angle)
		{
			/// TODO_ERIN optimize
			s = Math.Sin(angle);
			c = Math.Cos(angle);
		}

		/// Set to the identity rotation
		void SetIdentity()
		{
			s = 0.0f;
			c = 1.0f;
		}

		/// Get the angle in radians
		float GetAngle()
		{
			return Math.Atan2(s, c);
		}

		/// Get the x-axis
		float2 GetXAxis()
		{
			return float2(c, s);
		}

		/// Get the u-axis
		float2 GetYAxis()
		{
			return float2(-s, c);
		}

		/// Sine and cosine
		public float s, c;
	}

    /// A transform contains translation and rotation. It is used to represent
    /// the position and orientation of rigid frames.
    public struct Transform
    {
	    /// Initialize using a position vector and a rotation matrix.
        public Transform(float2 position, ref Mat22 rotation)
        {
            p = position;
            q = rotation;
        }

	    /// Set this to the identity transform.
        public void SetIdentity()
	    {
		    p = float2(0);
		    q.SetIdentity();
	    }

	    /// Set this based on the position and angle.
        public void Set(float2 position, float angle)
	    {
		    p = p;
		    q.Set(angle);
	    }

        public float2 p; // Position
        public Mat22 q; // R
		public Rot q2; // XXX: Should become q
    }

    /// This describes the motion of a body/shape for TOI computation.
    /// Shapes are defined with respect to the body origin, which may
    /// no coincide with the center of mass. However, to support dynamics
    /// we must interpolate the center of mass position.
    public struct Sweep
    {
	    /// Get the interpolated transform at a specific time.
    	/// @param beta is a factor in [0,1], where 0 indicates alpha0.
	    public void GetTransform(out Transform xf, float beta)
        {
			xf = new Transform();
			xf.p = (1.0f - beta) * c0 + beta * c;
			float angle = (1.0f - beta) * a0 + beta * a;
			xf.q.Set(angle);

			// Shift to origin
			xf.p -= MathUtils.Multiply(ref xf.q, localCenter);
        }

	    /// Advance the sweep forward, yielding a new initial state.
		/// @param alpha the new initial time.
	    public void Advance(float alpha)
        {
			// b2Assert(alpha0 < 1.0f);
			float beta = (alpha - alpha0) / (1.0f - alpha0);
			c0 += beta * (c - c0);
			a0 += beta * (a - a0);
			alpha0 = alpha;
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

		/// Fraction of the current time step in the range [0,1]
		/// c0 and a0 are the positions at alpha0.
		public float alpha0;
    }
}
