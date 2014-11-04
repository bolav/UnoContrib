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

//#define MATH_OVERLOADS

using Uno.Collections;


namespace Uno.Physics.Box2D
{
    public struct ContactConstraintPoint
    {
        public float2 localPoint;
        public float2 rA;
        public float2 rB;
        public float normalImpulse;
        public float tangentImpulse;
        public float normalMass;
        public float tangentMass;
        public float velocityBias;
    }

    public class ContactConstraint
    {
        public ContactConstraintPoint[] points = new ContactConstraintPoint[2];
        public float2 localNormal;
        public float2 localPoint;
        public float2 normal;
        public Mat22 normalMass;
        public Mat22 K;
        public Body bodyA;
        public Body bodyB;
        public ManifoldType type;
        public float radius;
        public float friction;
        public int pointCount;
        public Manifold manifold = new Manifold();
		
		public ContactConstraint() 
		{
			for(int i = 0; i < points.Length; i++)
				points[i] = new ContactConstraintPoint();
		}
    }

    public class ContactSolver
    {
        public ContactSolver() { }

        public void Reset(Contact[] contacts, int contactCount, float impulseRatio)
        {
            _contacts = contacts;

            _constraintCount = contactCount;

            // grow the array
            if (_constraints == null || _constraints.Length < _constraintCount)
            {
                _constraints = new ContactConstraint[_constraintCount * 2];
            }

            for (int i = 0; i < _constraintCount; ++i)
	        {
		        Contact contact = contacts[i];

		        Fixture fixtureA = contact._fixtureA;
		        Fixture fixtureB = contact._fixtureB;
		        Shape shapeA = fixtureA.GetShape();
		        Shape shapeB = fixtureB.GetShape();
		        float radiusA = shapeA._radius;
		        float radiusB = shapeB._radius;
		        Body bodyA = fixtureA.GetBody();
		        Body bodyB = fixtureB.GetBody();
                Manifold manifold = new Manifold();
                contact.GetManifold(out manifold);

		        float friction = Settings.b2MixFriction(fixtureA.GetFriction(), fixtureB.GetFriction());
                float restitution = Settings.b2MixRestitution(fixtureA.GetRestitution(), fixtureB.GetRestitution());

		        float2 vA = bodyA._linearVelocity;
		        float2 vB = bodyB._linearVelocity;
		        float wA = bodyA._angularVelocity;
		        float wB = bodyB._angularVelocity;



		        var worldManifold = new WorldManifold(ref manifold, ref bodyA._xf, radiusA, ref bodyB._xf, radiusB);

		        ContactConstraint cc = _constraints[i];
				if(cc == null) cc = _constraints[i] = new ContactConstraint();
		        cc.bodyA = bodyA;
		        cc.bodyB = bodyB;
		        cc.manifold = manifold;
		        cc.normal = worldManifold._normal;
		        cc.pointCount = manifold._pointCount;
		        cc.friction = friction;

		        cc.localNormal = manifold._localNormal;
		        cc.localPoint = manifold._localPoint;
		        cc.radius = radiusA + radiusB;
		        cc.type = manifold._type;

		        for (int j = 0; j < cc.pointCount; ++j)
		        {
			        ManifoldPoint cp = manifold._points[j];
			        ContactConstraintPoint ccp = cc.points[j];

                    ccp.normalImpulse = impulseRatio * cp.NormalImpulse;
                    ccp.tangentImpulse = impulseRatio * cp.TangentImpulse;

			        ccp.localPoint = cp.LocalPoint;

			        ccp.rA = worldManifold._points[j] - bodyA._sweep.c;
			        ccp.rB = worldManifold._points[j] - bodyB._sweep.c;

			        float rnA = MathUtils.Cross(ccp.rA, cc.normal);
			        float rnB = MathUtils.Cross(ccp.rB, cc.normal);

			        rnA *= rnA;
			        rnB *= rnB;

			        float kNormal = bodyA._invMass + bodyB._invMass + bodyA._invI * rnA + bodyB._invI * rnB;


			        ccp.normalMass = 1.0f / kNormal;

			        float2 tangent = MathUtils.Cross(cc.normal, 1.0f);

			        float rtA = MathUtils.Cross(ccp.rA, tangent);
			        float rtB = MathUtils.Cross(ccp.rB, tangent);

                    rtA *= rtA;
                    rtB *= rtB;
			        float kTangent = bodyA._invMass + bodyB._invMass + bodyA._invI * rtA + bodyB._invI * rtB;


			        ccp.tangentMass = 1.0f /  kTangent;

			        // Setup a velocity bias for restitution.
			        ccp.velocityBias = 0.0f;
			        float vRel = Uno.Vector.Dot(cc.normal, vB + MathUtils.Cross(wB, ccp.rB) - vA - MathUtils.Cross(wA, ccp.rA));
			        if (vRel < -Settings.b2_velocityThreshold)
			        {
				        ccp.velocityBias = -restitution * vRel;
			        }

                    cc.points[j] = ccp;
		        }

		        // If we have two points, then prepare the block solver.
		        if (cc.pointCount == 2)
		        {
			        ContactConstraintPoint ccp1 = cc.points[0];
			        ContactConstraintPoint ccp2 = cc.points[1];

			        float invMassA = bodyA._invMass;
			        float invIA = bodyA._invI;
			        float invMassB = bodyB._invMass;
			        float invIB = bodyB._invI;

			        float rn1A = MathUtils.Cross(ccp1.rA, cc.normal);
			        float rn1B = MathUtils.Cross(ccp1.rB, cc.normal);
			        float rn2A = MathUtils.Cross(ccp2.rA, cc.normal);
			        float rn2B = MathUtils.Cross(ccp2.rB, cc.normal);

			        float k11 = invMassA + invMassB + invIA * rn1A * rn1A + invIB * rn1B * rn1B;
			        float k22 = invMassA + invMassB + invIA * rn2A * rn2A + invIB * rn2B * rn2B;
			        float k12 = invMassA + invMassB + invIA * rn1A * rn2A + invIB * rn1B * rn2B;

			        // Ensure a reasonable condition number.
			        const float k_maxConditionNumber = 100.0f;
			        if (k11 * k11 < k_maxConditionNumber * (k11 * k22 - k12 * k12))
			        {
				        // K is safe to invert.
				        cc.K = new Mat22(float2(k11, k12), float2(k12, k22));
				        cc.normalMass = cc.K.GetInverse();
			        }
			        else
			        {
				        // The constraints are redundant, just use one.
				        // TODO_ERIN use deepest?
				        cc.pointCount = 1;
			        }
		        }

                _constraints[i] = cc;
	        }
        }

        public void WarmStart()
        {
            // Warm start.
            for (int i = 0; i < _constraintCount; ++i)
            {
	            ContactConstraint c = _constraints[i];

	            Body bodyA = c.bodyA;
	            Body bodyB = c.bodyB;
	            float invMassA = bodyA._invMass;
	            float invIA = bodyA._invI;
	            float invMassB = bodyB._invMass;
	            float invIB = bodyB._invI;
	            float2 normal = c.normal;

	            float2 tangent = MathUtils.Cross(normal, 1.0f);

	            for (int j = 0; j < c.pointCount; ++j)
	            {
		            ContactConstraintPoint ccp = c.points[j];
		            float2 P = ccp.normalImpulse * normal + ccp.tangentImpulse * tangent;
		            bodyA._angularVelocity -= invIA * MathUtils.Cross(ccp.rA, P);
		            bodyA._linearVelocity -= invMassA * P;
		            bodyB._angularVelocity += invIB * MathUtils.Cross(ccp.rB, P);
		            bodyB._linearVelocity += invMassB * P;
                    c.points[j] = ccp;
	            }

                _constraints[i] = c;
            }
        }

        public void SolveVelocityConstraints()
        {
            for (int i = 0; i < _constraintCount; ++i)
	        {
		        ContactConstraint c = _constraints[i];
		        Body bodyA = c.bodyA;
		        Body bodyB = c.bodyB;
		        float wA = bodyA._angularVelocity;
		        float wB = bodyB._angularVelocity;
		        float2 vA = bodyA._linearVelocity;
		        float2 vB = bodyB._linearVelocity;
		        float invMassA = bodyA._invMass;
		        float invIA = bodyA._invI;
		        float invMassB = bodyB._invMass;
		        float invIB = bodyB._invI;
		        float2 normal = c.normal;

				float2 tangent = MathUtils.Cross(normal, 1.0f);
		        float friction = c.friction;



		        // Solve tangent constraints
		        for (int j = 0; j < c.pointCount; ++j)
		        {
			        ContactConstraintPoint ccp = c.points[j];

			        // Relative velocity at contact
			        float2 dv = vB + MathUtils.Cross(wB, ccp.rB) - vA - MathUtils.Cross(wA, ccp.rA);

			        // Compute tangent force
			        float vt = Uno.Vector.Dot(dv, tangent);
			        float lambda = ccp.tangentMass * (-vt);

			        // MathUtils.Clamp the accumulated force
			        float maxFriction = friction * ccp.normalImpulse;
			        float newImpulse = MathUtils.Clamp(ccp.tangentImpulse + lambda, -maxFriction, maxFriction);
			        lambda = newImpulse - ccp.tangentImpulse;

			        // Apply contact impulse
			        float2 P = lambda * tangent;

			        vA -= invMassA * P;
			        wA -= invIA * MathUtils.Cross(ccp.rA, P);

			        vB += invMassB * P;
			        wB += invIB * MathUtils.Cross(ccp.rB, P);
			        ccp.tangentImpulse = newImpulse;
                    c.points[j] = ccp;
		        }

		        // Solve normal constraints
		        if (c.pointCount == 1)
		        {
			        ContactConstraintPoint ccp = c.points[0];

			        // Relative velocity at contact
			        float2 dv = vB + MathUtils.Cross(wB, ccp.rB) - vA - MathUtils.Cross(wA, ccp.rA);

			        // Compute normal impulse
			        float vn = Uno.Vector.Dot(dv, normal);
			        float lambda = -ccp.normalMass * (vn - ccp.velocityBias);

			        // MathUtils.Clamp the accumulated impulse
			        float newImpulse = Math.Max(ccp.normalImpulse + lambda, 0.0f);
			        lambda = newImpulse - ccp.normalImpulse;

			        // Apply contact impulse
			        float2 P = lambda * normal;
			        vA -= invMassA * P;
			        wA -= invIA * MathUtils.Cross(ccp.rA, P);

			        vB += invMassB * P;
			        wB += invIB * MathUtils.Cross(ccp.rB, P);
                    ccp.normalImpulse = newImpulse;
                    c.points[0] = ccp;
		        }
		        else
		        {
			        // Block solver developed in collaboration with Dirk Gregorius (back in 01/07 on Box2D_Lite).
			        // Build the mini LCP for this contact patch
			        //
			        // vn = A * x + b, vn >= 0, , vn >= 0, x >= 0 and vn_i * x_i = 0 with i = 1..2
			        //
			        // A = J * W * JT and J = ( -n, -r1 x n, n, r2 x n )
			        // b = vn_0 - velocityBias
			        //
			        // The system is solved using the "Total enumeration method" (s. Murty). The complementary constraint vn_i * x_i
			        // implies that we must have in any solution either vn_i = 0 or x_i = 0. So for the 2D contact problem the cases
			        // vn1 = 0 and vn2 = 0, x1 = 0 and x2 = 0, x1 = 0 and vn2 = 0, x2 = 0 and vn1 = 0 need to be tested. The first valid
			        // solution that satisfies the problem is chosen.
			        //
			        // In order to account of the accumulated impulse 'a' (because of the iterative nature of the solver which only requires
			        // that the accumulated impulse is clamped and not the incremental impulse) we change the impulse variable (x_i).
			        //
			        // Substitute:
			        //
			        // x = x' - a
			        //
			        // Plug into above equation:
			        //
			        // vn = A * x + b
			        //    = A * (x' - a) + b
			        //    = A * x' + b - A * a
			        //    = A * x' + b'
			        // b' = b - A * a;

			        ContactConstraintPoint cp1 = c.points[0];
			        ContactConstraintPoint cp2 = c.points[1];

			        float2 a = float2(cp1.normalImpulse, cp2.normalImpulse);


			        // Relative velocity at contact
			        float2 dv1 = vB + MathUtils.Cross(wB, cp1.rB) - vA - MathUtils.Cross(wA, cp1.rA);
			        float2 dv2 = vB + MathUtils.Cross(wB, cp2.rB) - vA - MathUtils.Cross(wA, cp2.rA);

			        // Compute normal velocity
			        float vn1 = Uno.Vector.Dot(dv1, normal);
			        float vn2 = Uno.Vector.Dot(dv2, normal);

                    float2 b = float2(vn1 - cp1.velocityBias, vn2 - cp2.velocityBias);
			        b -= MathUtils.Multiply(ref c.K, a);
                    while (true)
			        {
				        //
				        // Case 1: vn = 0
				        //
				        // 0 = A * x' + b'
				        //
				        // Solve for x':
				        //
				        // x' = - inv(A) * b'
				        //
				        float2 x = - MathUtils.Multiply(ref c.normalMass, b);

				        if (x.X >= 0.0f && x.Y >= 0.0f)
                        {
					        // Resubstitute for the incremental impulse
					        float2 d = x - a;

					        // Apply incremental impulse
					        float2 P1 = d.X * normal;
					        float2 P2 = d.Y * normal;
					        vA -= invMassA * (P1 + P2);
					        wA -= invIA * (MathUtils.Cross(cp1.rA, P1) + MathUtils.Cross(cp2.rA, P2));

					        vB += invMassB * (P1 + P2);
					        wB += invIB * (MathUtils.Cross(cp1.rB, P1) + MathUtils.Cross(cp2.rB, P2));
					        // Accumulate
					        cp1.normalImpulse = x.X;
					        cp2.normalImpulse = x.Y;

                            break;
				        }

				        //
				        // Case 2: vn1 = 0 and x2 = 0
				        //
				        //   0 = a11 * x1' + a12 * 0 + b1'
				        // vn2 = a21 * x1' + a22 * 0 + b2'
				        //
				        x.X = - cp1.normalMass * b.X;
				        x.Y = 0.0f;
				        vn1 = 0.0f;
				        vn2 = c.K.ex.Y * x.X + b.Y;

				        if (x.X >= 0.0f && vn2 >= 0.0f)
				        {
					        // Resubstitute for the incremental impulse
					        float2 d = x - a;

					        // Apply incremental impulse
					        float2 P1 = d.X * normal;
					        float2 P2 = d.Y * normal;
					        vA -= invMassA * (P1 + P2);
					        wA -= invIA * (MathUtils.Cross(cp1.rA, P1) + MathUtils.Cross(cp2.rA, P2));

					        vB += invMassB * (P1 + P2);
					        wB += invIB * (MathUtils.Cross(cp1.rB, P1) + MathUtils.Cross(cp2.rB, P2));
					        // Accumulate
					        cp1.normalImpulse = x.X;
					        cp2.normalImpulse = x.Y;

					        break;
				        }


				        //
				        // Case 3: vn2 = 0 and x1 = 0
				        //
				        // vn1 = a11 * 0 + a12 * x2' + b1'
				        //   0 = a21 * 0 + a22 * x2' + b2'
				        //
				        x.X = 0.0f;
				        x.Y = - cp2.normalMass * b.Y;
				        vn1 = c.K.ey.X * x.Y + b.X;
				        vn2 = 0.0f;

				        if (x.Y >= 0.0f && vn1 >= 0.0f)
				        {
					        // Resubstitute for the incremental impulse
					        float2 d = x - a;

					        // Apply incremental impulse
					        float2 P1 = d.X * normal;
					        float2 P2 = d.Y * normal;
					        vA -= invMassA * (P1 + P2);
					        wA -= invIA * (MathUtils.Cross(cp1.rA, P1) + MathUtils.Cross(cp2.rA, P2));

					        vB += invMassB * (P1 + P2);
					        wB += invIB * (MathUtils.Cross(cp1.rB, P1) + MathUtils.Cross(cp2.rB, P2));
					        // Accumulate
					        cp1.normalImpulse = x.X;
					        cp2.normalImpulse = x.Y;

					        break;
				        }

				        //
				        // Case 4: x1 = 0 and x2 = 0
				        //
				        // vn1 = b1
				        // vn2 = b2;
				        x.X = 0.0f;
				        x.Y = 0.0f;
				        vn1 = b.X;
				        vn2 = b.Y;

				        if (vn1 >= 0.0f && vn2 >= 0.0f )
				        {
					        // Resubstitute for the incremental impulse
					        float2 d = x - a;

					        // Apply incremental impulse
					        float2 P1 = d.X * normal;
					        float2 P2 = d.Y * normal;
					        vA -= invMassA * (P1 + P2);
					        wA -= invIA * (MathUtils.Cross(cp1.rA, P1) + MathUtils.Cross(cp2.rA, P2));

					        vB += invMassB * (P1 + P2);
					        wB += invIB * (MathUtils.Cross(cp1.rB, P1) + MathUtils.Cross(cp2.rB, P2));
					        // Accumulate
					        cp1.normalImpulse = x.X;
					        cp2.normalImpulse = x.Y;

					        break;
				        }

				        // No solution, give up. This is hit sometimes, but it doesn't seem to matter.
				        break;
			        }

                    c.points[0] = cp1;
                    c.points[1] = cp2;
		        }

                _constraints[i] = c;

		        bodyA._linearVelocity = vA;
		        bodyA._angularVelocity = wA;
		        bodyB._linearVelocity = vB;
		        bodyB._angularVelocity = wB;
	        }
        }

        public void StoreImpulses()
        {
            for (int i = 0; i < _constraintCount; ++i)
	        {
		        ContactConstraint c = _constraints[i];
		        Manifold m = c.manifold;

		        for (int j = 0; j < c.pointCount; ++j)
		        {
                    var pj = m._points[j];
                    var cp = c.points[j];

                    pj.NormalImpulse = cp.normalImpulse;
                    pj.TangentImpulse = cp.tangentImpulse;

                    m._points[j] = pj;
		        }

                // TODO: look for better ways of doing this.
                c.manifold = m;
                _constraints[i] = c;
                _contacts[i]._manifold = m;
	        }
        }

        public bool SolvePositionConstraints(float baumgarte)
        {
            float minSeparation = 0.0f;

            for (int i = 0; i < _constraintCount; ++i)
	        {
		        ContactConstraint c = _constraints[i];

		        Body bodyA = c.bodyA;
		        Body bodyB = c.bodyB;

		        float invMassA = bodyA._mass * bodyA._invMass;
		        float invIA = bodyA._mass * bodyA._invI;
		        float invMassB = bodyB._mass * bodyB._invMass;
		        float invIB = bodyB._mass * bodyB._invI;

		        // Solve normal constraints
		        for (int j = 0; j < c.pointCount; ++j)
		        {
                    var psm = new PositionSolverManifold(ref c, j);
                    float2 normal = psm._normal;

                    float2 point = psm._point;
                    float separation = psm._separation;

			        float2 rA = point - bodyA._sweep.c;
			        float2 rB = point - bodyB._sweep.c;

			        // Track max constraint error.
			        minSeparation = Math.Min(minSeparation, separation);

			        // Prevent large corrections and allow slop.
                    float C = MathUtils.Clamp(baumgarte *  (separation + Settings.b2_linearSlop), -Settings.b2_maxLinearCorrection, 0.0f);

                    // Compute the effective mass.
                    float rnA = MathUtils.Cross(rA, normal);
                    float rnB = MathUtils.Cross(rB, normal);
                    float K = invMassA + invMassB + invIA * rnA * rnA + invIB * rnB * rnB;

                    // Compute normal impulse
                    float impulse = K > 0.0f ? -C / K : 0.0f;

			        float2 P = impulse * normal;

			        bodyA._sweep.c -= invMassA * P;
			        bodyA._sweep.a -= invIA * MathUtils.Cross(rA, P);

			        bodyB._sweep.c += invMassB * P;
			        bodyB._sweep.a += invIB * MathUtils.Cross(rB, P);
                    bodyA.SynchronizeTransform();
			        bodyB.SynchronizeTransform();
		        }
	        }

	        // We can't expect minSpeparation >= -Settings.b2_linearSlop because we don't
	        // push the separation above -Settings.b2_linearSlop.
	        return minSeparation >= -1.5f * Settings.b2_linearSlop;
        }

        public ContactConstraint[] _constraints = new ContactConstraint[8];
        public int _constraintCount; // collection can be bigger.
        private Contact[] _contacts = new Contact[8];
    }

    internal struct PositionSolverManifold
    {
        internal PositionSolverManifold(ref ContactConstraint cc, int index)
        {


	        switch (cc.type)
	        {
	        case ManifoldType.Circles:
		        {
			        float2 pointA = cc.bodyA.GetWorldPoint(cc.localPoint);
			        float2 pointB = cc.bodyB.GetWorldPoint(cc.points[0].localPoint);
			        if (MathUtils.DistanceSquared(pointA, pointB) > Settings.b2_epsilon * Settings.b2_epsilon)
			        {
				        _normal = pointB - pointA;
                        _normal = Vector.Normalize(_normal);
			        }
			        else
			        {
				        _normal = float2(1.0f, 0.0f);
			        }

			        _point = 0.5f * (pointA + pointB);
			        _separation = Uno.Vector.Dot(pointB - pointA, _normal) - cc.radius;
		        }
		        break;

	        case ManifoldType.FaceA:
		        {
			        _normal = cc.bodyA.GetWorldVector(cc.localNormal);
			        float2 planePoint = cc.bodyA.GetWorldPoint(cc.localPoint);

			        float2 clipPoint = cc.bodyB.GetWorldPoint(cc.points[index].localPoint);
			        _separation = Uno.Vector.Dot(clipPoint - planePoint, _normal) - cc.radius;
			        _point = clipPoint;
		        }
		        break;

	        case ManifoldType.FaceB:
		        {
			        _normal = cc.bodyB.GetWorldVector(cc.localNormal);
			        float2 planePoint = cc.bodyB.GetWorldPoint(cc.localPoint);

                    float2 clipPoint = cc.bodyA.GetWorldPoint(cc.points[index].localPoint);
			        _separation = Uno.Vector.Dot(clipPoint - planePoint, _normal) - cc.radius;
			        _point = clipPoint;

                    // Ensure normal points from A to B
			        _normal = -_normal;
		        }
		        break;
            default:
                _normal = float2(0);
                _point = float2(0);
                _separation = 0.0f;
                break;
	        }
        }

        internal float2 _normal;
        internal float2 _point;
        internal float _separation;
    }
}
