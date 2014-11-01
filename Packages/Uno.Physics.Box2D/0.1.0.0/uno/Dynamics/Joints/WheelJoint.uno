/*
* r313
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
	/// Wheel joint definition. This requires defining a line of
	/// motion using an axis and an anchor point. The definition uses local
	/// anchor points and a local axis so that the initial configuration
	/// can violate the constraint slightly. The joint translation is zero
	/// when the local anchor points coincide in world space. Using local
	/// anchors and a local axis helps when saving and loading a game.
    public class WheelJointDef : JointDef
    {
	    public WheelJointDef()
	    {
		    type = JointType.Wheel;
		    localAnchorA = float2(0);
		    localAnchorB = float2(0);
			localAxisA = float2(1.0f, 0.0f);
			enableMotor = false;
			maxMotorTorque = 0.0f;
			motorSpeed = 0.0f;
			frequencyHz = 2.0f;
			dampingRatio = 0.7f;
	    }

// Linear constraint (point-to-line)
// d = pB - pA = xB + rB - xA - rA
// C = dot(ay, d)
// Cdot = dot(d, cross(wA, ay)) + dot(ay, vB + cross(wB, rB) - vA - cross(wA, rA))
//      = -dot(ay, vA) - dot(cross(d + rA, ay), wA) + dot(ay, vB) + dot(cross(rB, ay), vB)
// J = [-ay, -cross(d + rA, ay), ay, cross(rB, ay)]

// Spring linear constraint
// C = dot(ax, d)
// Cdot = = -dot(ax, vA) - dot(cross(d + rA, ax), wA) + dot(ax, vB) + dot(cross(rB, ax), vB)
// J = [-ax -cross(d+rA, ax) ax cross(rB, ax)]

// Motor rotational constraint
// Cdot = wB - wA
// J = [0 0 -1 0 0 1]
	    public void Initialize(Body b1, Body b2,
					    float2 anchor, float2 axis)
        {
	        bodyA = b1;
	        bodyB = b2;
	        localAnchorA = bodyA.GetLocalPoint(anchor);
	        localAnchorB = bodyB.GetLocalPoint(anchor);
	        localAxis1 = bodyA.GetLocalVector(axis);
        }

	    /// The local anchor point relative to body1's origin.
	    public float2 localAnchorA;

	    /// The local anchor point relative to body2's origin.
	    public float2 localAnchorB;

	    /// The local translation axis in body1.
	    public float2 localAxis1;

		/// Enable/disable the joint motor.
		public bool enableMotor;

		/// The maximum motor torque, usually in N-m.
		public float maxMotorTorque;

		/// The desired motor speed in radians per second.
		public float motorSpeed;

        /// The mass-spring-damper frequency in Hertz.
	    public float frequencyHz;

	    /// The damping ratio. 0 = no damping, 1 = critical damping.
	    public float dampingRatio;
    }

    public class WheelJoint : Joint
    {
	    internal WheelJoint(WheelJointDef def)
            : base(def)
        {
			_localAnchor1 = def.localAnchorA;
			_localAnchor2 = def.localAnchorB;
			_localXAxis1 = def.localAxisA1
			_localYAxis1 = b2Cross(1.0f, _localXAxis1);

			_mass = 0.0f;
			_impulse = 0.0f;
			_motorMass = 0.0f;
			_motorImpulse = 0.0f;
			_springMass = 0.0f;
			_springImpulse = 0.0f;

			_maxMotorTorque = def.maxMotorTorque;
			_motorSpeed = def.motorSpeed;
			_enableMotor = def.enableMotor;

			_frequencyHz = def.frequencyHz;
			_dampingRatio = def.dampingRatio;

			_bias = 0.0f;
			_gamma = 0.0f;

			_ax = float2(0);
			_ay = float2(0);
        }
        /// Set/get the natural length.
        /// Manipulating the length can lead to non-physical behavior when the frequency is zero.
        public void SetLength(float length)
        {
            _length = length;
        }

        public float GetLength()
        {
            return _length;
        }

	    // Set/get frequency in Hz.
        public void SetFrequency(float hz)
        {
            _frequencyHz = hz;
        }

        public float GetFrequency()
        {
            return _frequencyHz;
        }

	    // Set/get damping ratio.
        public void SetDampingRatio(float ratio)
        {
            _dampingRatio = ratio;
        }

        public float GetDampingRatio()
        {
            return _dampingRatio;
        }

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
	        float2 F = (inv_dt * _impulse) * _u;
	        return F;
        }

        public override float GetReactionTorque(float inv_dt)
        {
	        return 0.0f;
        }

        internal override void InitVelocityConstraints(ref TimeStep step)
        {
	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

            Transform xf1, xf2;
            b1.GetTransform(out xf1);
            b2.GetTransform(out xf2);

	        // Compute the effective mass matrix.
            float2 r1 = MathUtils.Multiply(ref xf1.R, _localAnchor1 - b1.GetLocalCenter());
            float2 r2 = MathUtils.Multiply(ref xf2.R, _localAnchor2 - b2.GetLocalCenter());
	        _u = b2._sweep.c + r2 - b1._sweep.c - r1;

	        // Handle singularity.
	        float length = Vector.Length(_u);
	        if (length > Settings.b2_linearSlop)
	        {
		        _u *= 1.0f / length;
	        }
	        else
	        {
		        _u = float2(0.0f, 0.0f);
	        }

	        float cr1u = MathUtils.Cross(r1, _u);
	        float cr2u = MathUtils.Cross(r2, _u);
	        float invMass = b1._invMass + b1._invI * cr1u * cr1u + b2._invMass + b2._invI * cr2u * cr2u;
	        
            _mass = invMass != 0.0f ? 1.0f / invMass : 0.0f;

	        if (_frequencyHz > 0.0f)
	        {
		        float C = length - _length;

		        // Frequency
		        float omega = 2.0f * Settings.b2_pi * _frequencyHz;

		        // Damping coefficient
		        float d = 2.0f * _mass * _dampingRatio * omega;

		        // Spring stiffness
		        float k = _mass * omega * omega;

		        // magic formulas
                _gamma = step.dt * (d + step.dt * k);
                _gamma = _gamma != 0.0f ? 1.0f / _gamma : 0.0f;
                _bias = C * step.dt * k * _gamma;

                _mass = invMass + _gamma;
                _mass = _mass != 0.0f ? 1.0f / _mass : 0.0f;
	        }

	        if (step.warmStarting)
	        {
		        // Scale the impulse to support a variable time step.
		        _impulse *= step.dtRatio;

		        float2 P = _impulse * _u;
		        b1._linearVelocity -= b1._invMass * P;
		        b1._angularVelocity -= b1._invI * MathUtils.Cross(r1, P);
		        b2._linearVelocity += b2._invMass * P;
		        b2._angularVelocity += b2._invI * MathUtils.Cross(r2, P);
	        }
	        else
	        {
		        _impulse = 0.0f;
	        }
        }

        internal override void SolveVelocityConstraints(ref TimeStep step)
        {
	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

            Transform xf1, xf2;
            b1.GetTransform(out xf1);
            b2.GetTransform(out xf2);

            float2 r1 = MathUtils.Multiply(ref xf1.R, _localAnchor1 - b1.GetLocalCenter());
            float2 r2 = MathUtils.Multiply(ref xf2.R, _localAnchor2 - b2.GetLocalCenter());

	        // Cdot = dot(u, v + cross(w, r))
	        float2 v1 = b1._linearVelocity + MathUtils.Cross(b1._angularVelocity, r1);
	        float2 v2 = b2._linearVelocity + MathUtils.Cross(b2._angularVelocity, r2);
	        float Cdot = Uno.Vector.Dot(_u, v2 - v1);

	        float impulse = -_mass * (Cdot + _bias + _gamma * _impulse);
	        _impulse += impulse;

	        float2 P = impulse * _u;
	        b1._linearVelocity -= b1._invMass * P;
	        b1._angularVelocity -= b1._invI * MathUtils.Cross(r1, P);
	        b2._linearVelocity += b2._invMass * P;
	        b2._angularVelocity += b2._invI * MathUtils.Cross(r2, P);
        }

        internal override bool SolvePositionConstraints(float baumgarte)
        {
	        if (_frequencyHz > 0.0f)
	        {
		        // There is no position correction for soft distance constraints.
		        return true;
	        }

	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

            Transform xf1, xf2;
            b1.GetTransform(out xf1);
            b2.GetTransform(out xf2);

	        float2 r1 = MathUtils.Multiply(ref xf1.R, _localAnchor1 - b1.GetLocalCenter());
	        float2 r2 = MathUtils.Multiply(ref xf2.R, _localAnchor2 - b2.GetLocalCenter());

	        float2 d = b2._sweep.c + r2 - b1._sweep.c - r1;

	        float length = Vector.Length(d);

            if (length == 0.0f)
                return true;

            d /= length;
	        float C = length - _length;
	        C = MathUtils.Clamp(C, -Settings.b2_maxLinearCorrection, Settings.b2_maxLinearCorrection);

	        float impulse = -_mass * C;
	        _u = d;
	        float2 P = impulse * _u;

	        b1._sweep.c -= b1._invMass * P;
	        b1._sweep.a -= b1._invI * MathUtils.Cross(r1, P);
	        b2._sweep.c += b2._invMass * P;
	        b2._sweep.a += b2._invI * MathUtils.Cross(r2, P);

	        b1.SynchronizeTransform();
	        b2.SynchronizeTransform();

	        return Math.Abs(C) < Settings.b2_linearSlop;
        }

	    internal float2 _localAnchor1;
	    internal float2 _localAnchor2;
	    internal float2 _u;
	    internal float _frequencyHz;
	    internal float _dampingRatio;
	    internal float _gamma;
	    internal float _bias;
	    internal float _impulse;
	    internal float _mass;
	    internal float _length;
    }
}
