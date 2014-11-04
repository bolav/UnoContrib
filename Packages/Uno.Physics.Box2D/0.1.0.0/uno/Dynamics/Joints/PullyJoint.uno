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
    /// Pulley joint definition. This requires two ground anchors,
    /// two dynamic body anchor points, max lengths for each side,
    /// and a pulley ratio.
    public class PulleyJointDef : JointDef
    {
        internal const float b2_minPulleyLength = 2.0f;

	    public PulleyJointDef()
	    {
		    type = JointType.Pulley;
		    groundAnchorA = float2(-1.0f, 1.0f);
		    groundAnchorB = float2(1.0f, 1.0f);
		    localAnchorA = float2(-1.0f, 0.0f);
		    localAnchorB = float2(1.0f, 0.0f);
		    lengthA = 0.0f;
		    maxLengthA = 0.0f;
		    lengthB = 0.0f;
		    maxLengthB = 0.0f;
		    ratio = 1.0f;
		    collideConnected = true;
	    }

	    /// Initialize the bodies, anchors, lengths, max lengths, and ratio using the world anchors.
        public void Initialize(Body b1, Body b2,
                        float2 ga1, float2 ga2,
					    float2 anchor1, float2 anchor2,
					    float r)
        {
	        bodyA = b1;
	        bodyB = b2;
	        groundAnchorA = ga1;
	        groundAnchorB = ga2;
	        localAnchorA = bodyA.GetLocalPoint(anchor1);
	        localAnchorB = bodyB.GetLocalPoint(anchor2);
	        float2 d1 = anchor1 - ga1;
	        lengthA = Vector.Length(d1);
	        float2 d2 = anchor2 - ga2;
	        lengthB = Vector.Length(d2);
	        ratio = r;
	        
	        float C = lengthA + ratio * lengthB;
	        maxLengthA = C - ratio * b2_minPulleyLength;
	        maxLengthB = (C - b2_minPulleyLength) / ratio;
        }

	    /// The first ground anchor in world coordinates. This point never moves.
	    public float2 groundAnchorA;

	    /// The second ground anchor in world coordinates. This point never moves.
	    public float2 groundAnchorB;

	    /// The local anchor point relative to body1's origin.
	    public float2 localAnchorA;

	    /// The local anchor point relative to body2's origin.
	    public float2 localAnchorB;

	    /// The a reference length for the segment attached to body1.
	    public float lengthA;

	    /// The maximum length of the segment attached to body1.
	    public float maxLengthA;

	    /// The a reference length for the segment attached to body2.
	    public float lengthB;

	    /// The maximum length of the segment attached to body2.
	    public float maxLengthB;

	    /// The pulley ratio, used to simulate a block-and-tackle.
	    public float ratio;
    }

    /// The pulley joint is connected to two bodies and two fixed ground points.
    /// The pulley supports a ratio such that:
    /// length1 + ratio * length2 <= ant
    /// Yes, the force transmitted is scaled by the ratio.
    /// The pulley also enforces a maximum length limit on both sides. This is
    /// useful to prevent one side of the pulley hitting the top.
    public class PulleyJoint : Joint
    {
	    public override float2 GetAnchorA()
        {
            return _bodyA.GetWorldPoint(_localAnchor1);
        }

	    public override float2 GetAnchorB()
        {
            return _bodyB.GetWorldPoint(_localAnchor2);
        }

	    public override float2 GetReactionForce(float inv_dt)
        {
            float2 P = _impulse * _u2;
	        return inv_dt * P;
        }

	    public override float GetReactionTorque(float inv_dt)
        {
            return 0.0f;
        }

	    /// Get the first ground anchor.
	    public float2 GetGroundAnchorA()
        {
            return _groundAnchor1;
        }

	    /// Get the second ground anchor.
	    public float2 GetGroundAnchorB()
        {
            return _groundAnchor2;
        }

	    /// Get the current length of the segment attached to body1.
	    public float GetLength1()
        {
            float2 p = _bodyA.GetWorldPoint(_localAnchor1);
	        float2 s = _groundAnchor1;
	        float2 d = p - s;
	        return Vector.Length(d);
        }

	    /// Get the current length of the segment attached to body2.
	    public float GetLength2()
        {
            float2 p = _bodyB.GetWorldPoint(_localAnchor2);
	        float2 s = _groundAnchor2;
	        float2 d = p - s;
	        return Vector.Length(d);
        }

	    /// Get the pulley ratio.
	    public float GetRatio()
        {
            return _ratio;
        }

	    internal PulleyJoint(PulleyJointDef def)
            : base (def)
        {
	        _groundAnchor1 = def.groundAnchorA;
	        _groundAnchor2 = def.groundAnchorB;
	        _localAnchor1 = def.localAnchorA;
	        _localAnchor2 = def.localAnchorB;

	        
	        _ratio = def.ratio;

	        _ant = def.lengthA + _ratio * def.lengthB;

            _maxLength1 = Math.Min(def.maxLengthA, _ant - _ratio * PulleyJointDef.b2_minPulleyLength);
            _maxLength2 = Math.Min(def.maxLengthB, (_ant - PulleyJointDef.b2_minPulleyLength) / _ratio);

	        _impulse = 0.0f;
	        _limitImpulse1 = 0.0f;
	        _limitImpulse2 = 0.0f;
        }

	    internal override void InitVelocityConstraints(ref TimeStep step)
        {
	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

            Transform xf1, xf2;
            b1.GetTransform(out xf1);
            b2.GetTransform(out xf2);

	        float2 r1 = MathUtils.Multiply(ref xf1.q, _localAnchor1 - b1.GetLocalCenter());
	        float2 r2 = MathUtils.Multiply(ref xf2.q, _localAnchor2 - b2.GetLocalCenter());

	        float2 p1 = b1._sweep.c + r1;
	        float2 p2 = b2._sweep.c + r2;

	        float2 s1 = _groundAnchor1;
	        float2 s2 = _groundAnchor2;

	        // Get the pulley axes.
	        _u1 = p1 - s1;
	        _u2 = p2 - s2;

	        float length1 = Vector.Length(_u1);
	        float length2 = Vector.Length(_u2);

	        if (length1 > Settings.b2_linearSlop)
	        {
		        _u1 *= 1.0f / length1;
	        }
	        else
	        {
		        _u1 = float2(0);
	        }

	        if (length2 > Settings.b2_linearSlop)
	        {
		        _u2 *= 1.0f / length2;
	        }
	        else
	        {
		        _u2 = float2(0);
	        }

	        float C = _ant - length1 - _ratio * length2;
	        if (C > 0.0f)
	        {
		        _state = LimitState.Inactive;
		        _impulse = 0.0f;
	        }
	        else
	        {
		        _state = LimitState.AtUpper;
	        }

	        if (length1 < _maxLength1)
	        {
		        _limitState1 = LimitState.Inactive;
		        _limitImpulse1 = 0.0f;
	        }
	        else
	        {
		        _limitState1 = LimitState.AtUpper;
	        }

	        if (length2 < _maxLength2)
	        {
		        _limitState2 = LimitState.Inactive;
		        _limitImpulse2 = 0.0f;
	        }
	        else
	        {
		        _limitState2 = LimitState.AtUpper;
	        }

	        // Compute effective mass.
	        float cr1u1 = MathUtils.Cross(r1, _u1);
	        float cr2u2 = MathUtils.Cross(r2, _u2);

	        _limitMass1 = b1._invMass + b1._invI * cr1u1 * cr1u1;
	        _limitMass2 = b2._invMass + b2._invI * cr2u2 * cr2u2;
	        _pulleyMass = _limitMass1 + _ratio * _ratio * _limitMass2;
	        
	        
	        
	        _limitMass1 = 1.0f / _limitMass1;
	        _limitMass2 = 1.0f / _limitMass2;
	        _pulleyMass = 1.0f / _pulleyMass;

	        if (step.warmStarting)
	        {
		        // Scale impulses to support variable time steps.
		        _impulse *= step.dtRatio;
		        _limitImpulse1 *= step.dtRatio;
		        _limitImpulse2 *= step.dtRatio;

		        // Warm starting.
		        float2 P1 = -(_impulse + _limitImpulse1) * _u1;
		        float2 P2 = (-_ratio * _impulse - _limitImpulse2) * _u2;
		        b1._linearVelocity += b1._invMass * P1;
		        b1._angularVelocity += b1._invI * MathUtils.Cross(r1, P1);
		        b2._linearVelocity += b2._invMass * P2;
		        b2._angularVelocity += b2._invI * MathUtils.Cross(r2, P2);
	        }
	        else
	        {
		        _impulse = 0.0f;
		        _limitImpulse1 = 0.0f;
		        _limitImpulse2 = 0.0f;
	        }
        }

	    internal override void SolveVelocityConstraints(ref TimeStep step)
        {
	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

            Transform xf1, xf2;
            b1.GetTransform(out xf1);
            b2.GetTransform(out xf2);

	        float2 r1 = MathUtils.Multiply(ref xf1.q, _localAnchor1 - b1.GetLocalCenter());
	        float2 r2 = MathUtils.Multiply(ref xf2.q, _localAnchor2 - b2.GetLocalCenter());

	        if (_state == LimitState.AtUpper)
	        {
		        float2 v1 = b1._linearVelocity + MathUtils.Cross(b1._angularVelocity, r1);
		        float2 v2 = b2._linearVelocity + MathUtils.Cross(b2._angularVelocity, r2);

		        float Cdot = -Uno.Vector.Dot(_u1, v1) - _ratio * Uno.Vector.Dot(_u2, v2);
		        float impulse = _pulleyMass * (-Cdot);
		        float oldImpulse = _impulse;
		        _impulse = Math.Max(0.0f, _impulse + impulse);
		        impulse = _impulse - oldImpulse;

                float2 P1 = _u1 * -impulse;
                float2 P2 = _u2 * -_ratio * impulse;
                b1._linearVelocity += P1 * b1._invMass;
		        b1._angularVelocity += b1._invI * MathUtils.Cross(r1, P1);
                b2._linearVelocity += P2 * b2._invMass;
		        b2._angularVelocity += b2._invI * MathUtils.Cross(r2, P2);
	        }

	        if (_limitState1 == LimitState.AtUpper)
	        {
		        float2 v1 = b1._linearVelocity + MathUtils.Cross(b1._angularVelocity, r1);

		        float Cdot = -Uno.Vector.Dot(_u1, v1);
		        float impulse = -_limitMass1 * Cdot;
		        float oldImpulse = _limitImpulse1;
		        _limitImpulse1 = Math.Max(0.0f, _limitImpulse1 + impulse);
		        impulse = _limitImpulse1 - oldImpulse;

                float2 P1 = _u1 * -impulse;
                b1._linearVelocity += P1 * b1._invMass;
		        b1._angularVelocity += b1._invI * MathUtils.Cross(r1, P1);
	        }

	        if (_limitState2 == LimitState.AtUpper)
	        {
		        float2 v2 = b2._linearVelocity + MathUtils.Cross(b2._angularVelocity, r2);

		        float Cdot = -Uno.Vector.Dot(_u2, v2);
		        float impulse = -_limitMass2 * Cdot;
		        float oldImpulse = _limitImpulse2;
		        _limitImpulse2 = Math.Max(0.0f, _limitImpulse2 + impulse);
		        impulse = _limitImpulse2 - oldImpulse;

                float2 P2 = _u2 -impulse;
                b2._linearVelocity += P2 * b2._invMass;
		        b2._angularVelocity += b2._invI * MathUtils.Cross(r2, P2);
	        }
        }

	    internal override bool SolvePositionConstraints(float baumgarte)
        {
	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

	        float2 s1 = _groundAnchor1;
	        float2 s2 = _groundAnchor2;

	        float linearError = 0.0f;

	        if (_state == LimitState.AtUpper)
	        {
                Transform xf1, xf2;
                b1.GetTransform(out xf1);
                b2.GetTransform(out xf2);

		        float2 r1 = MathUtils.Multiply(ref xf1.q, _localAnchor1 - b1.GetLocalCenter());
		        float2 r2 = MathUtils.Multiply(ref xf2.q, _localAnchor2 - b2.GetLocalCenter());

		        float2 p1 = b1._sweep.c + r1;
		        float2 p2 = b2._sweep.c + r2;

		        // Get the pulley axes.
		        _u1 = p1 - s1;
		        _u2 = p2 - s2;

		        float length1 = Vector.Length(_u1);
		        float length2 = Vector.Length(_u2);

		        if (length1 > Settings.b2_linearSlop)
		        {
			        _u1 *= 1.0f / length1;
		        }
		        else
		        {
			        _u1 = float2(0);
		        }

		        if (length2 > Settings.b2_linearSlop)
		        {
			        _u2 *= 1.0f / length2;
		        }
		        else
		        {
			        _u2 = float2(0);
		        }

		        float C = _ant - length1 - _ratio * length2;
		        linearError = Math.Max(linearError, -C);

		        C = MathUtils.Clamp(C + Settings.b2_linearSlop, -Settings.b2_maxLinearCorrection, 0.0f);
                float impulse = C  * (- _pulleyMass);

                float2 P1 = _u1 * (-impulse);
                float2 P2 = _u2 * -_ratio * impulse;

                b1._sweep.c += P1 * b1._invMass;
		        b1._sweep.a += b1._invI * MathUtils.Cross(r1, P1);
                b2._sweep.c += P2 * b2._invMass;
		        b2._sweep.a += b2._invI * MathUtils.Cross(r2, P2);

		        b1.SynchronizeTransform();
		        b2.SynchronizeTransform();
	        }

	        if (_limitState1 == LimitState.AtUpper)
	        {
                Transform xf1;
                b1.GetTransform(out xf1);

		        float2 r1 = MathUtils.Multiply(ref xf1.q, _localAnchor1 - b1.GetLocalCenter());
		        float2 p1 = b1._sweep.c + r1;

		        _u1 = p1 - s1;
		        float length1 = Vector.Length(_u1);

		        if (length1 > Settings.b2_linearSlop)
		        {
			        _u1 *= 1.0f / length1;
		        }
		        else
		        {
			        _u1 = float2(0);
		        }

		        float C = _maxLength1 - length1;
		        linearError = Math.Max(linearError, -C);
		        C = MathUtils.Clamp(C + Settings.b2_linearSlop, -Settings.b2_maxLinearCorrection, 0.0f);
		        float impulse = -_limitMass1 * C;

		        float2 P1 = -impulse * _u1;
		        b1._sweep.c += b1._invMass * P1;
		        b1._sweep.a += b1._invI * MathUtils.Cross(r1, P1);

		        b1.SynchronizeTransform();
	        }

	        if (_limitState2 == LimitState.AtUpper)
	        {
                Transform xf2;
                b2.GetTransform(out xf2);

		        float2 r2 = MathUtils.Multiply(ref xf2.q, _localAnchor2 - b2.GetLocalCenter());
		        float2 p2 = b2._sweep.c + r2;

		        _u2 = p2 - s2;
		        float length2 = Vector.Length(_u2);

		        if (length2 > Settings.b2_linearSlop)
		        {
			        _u2 *= 1.0f / length2;
		        }
		        else
		        {
			        _u2 = float2(0);
		        }

		        float C = _maxLength2 - length2;
		        linearError = Math.Max(linearError, -C);
		        C = MathUtils.Clamp(C + Settings.b2_linearSlop, -Settings.b2_maxLinearCorrection, 0.0f);
		        float impulse = -_limitMass2 * C;

		        float2 P2 = -impulse * _u2;
		        b2._sweep.c += b2._invMass * P2;
		        b2._sweep.a += b2._invI * MathUtils.Cross(r2, P2);

		        b2.SynchronizeTransform();
	        }

	        return linearError < Settings.b2_linearSlop;
        }

	    internal float2 _groundAnchor1;
	    internal float2 _groundAnchor2;
	    internal float2 _localAnchor1;
	    internal float2 _localAnchor2;

	    internal float2 _u1;
	    internal float2 _u2;
    	
	    internal float _ant;
	    internal float _ratio;
    	
	    internal float _maxLength1;
	    internal float _maxLength2;

	    // Effective masses
	    internal float _pulleyMass;
	    internal float _limitMass1;
	    internal float _limitMass2;

	    // Impulses for accumulation/warm starting.
	    internal float _impulse;
	    internal float _limitImpulse1;
	    internal float _limitImpulse2;

	    internal LimitState _state;
	    internal LimitState _limitState1;
	    internal LimitState _limitState2;
    }
}
