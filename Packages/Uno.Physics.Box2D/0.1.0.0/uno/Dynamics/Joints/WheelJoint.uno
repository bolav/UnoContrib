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

        internal override void InitVelocityConstraints(ref TimeStep step)
		{
	        Body b1 = _bodyA;
	        Body b2 = _bodyB;

	        _localCenterA = b1.GetLocalCenter();
	        _localCenterB = b2.GetLocalCenter();
			
	        _invMassA = b1._invMass;
	        _invIA = b1._invI;
	        _invMassB = b2._invMass;
	        _invIB = b2._invI;

			// XXX: We are here, but we need SolverData instead of step, need to rewrite entire Box2D

			float32 mA = _invMassA, mB = _invMassB;
			float32 iA = _invIA, iB = _invIB;

			b2Vec2 cA = data.positions[_indexA].c;
			float32 aA = data.positions[_indexA].a;
			b2Vec2 vA = data.velocities[_indexA].v;
			float32 wA = data.velocities[_indexA].w;

			b2Vec2 cB = data.positions[_indexB].c;
			float32 aB = data.positions[_indexB].a;
			b2Vec2 vB = data.velocities[_indexB].v;
			float32 wB = data.velocities[_indexB].w;

			b2Rot qA(aA), qB(aB);

			// Compute the effective masses.
			b2Vec2 rA = b2Mul(qA, _localAnchorA - _localCenterA);
			b2Vec2 rB = b2Mul(qB, _localAnchorB - _localCenterB);
			b2Vec2 d = cB + rB - cA - rA;

			// Point to line constraint
			{
				_ay = b2Mul(qA, _localYAxisA);
				_sAy = b2Cross(d + rA, _ay);
				_sBy = b2Cross(rB, _ay);

				_mass = mA + mB + iA * _sAy * _sAy + iB * _sBy * _sBy;

				if (_mass > 0.0f)
				{
					_mass = 1.0f / _mass;
				}
			}

			// Spring constraint
			_springMass = 0.0f;
			_bias = 0.0f;
			_gamma = 0.0f;
			if (_frequencyHz > 0.0f)
			{
				_ax = b2Mul(qA, _localXAxisA);
				_sAx = b2Cross(d + rA, _ax);
				_sBx = b2Cross(rB, _ax);

				float32 invMass = mA + mB + iA * _sAx * _sAx + iB * _sBx * _sBx;

				if (invMass > 0.0f)
				{
					_springMass = 1.0f / invMass;

					float32 C = b2Dot(d, _ax);

					// Frequency
					float32 omega = 2.0f * b2_pi * _frequencyHz;

					// Damping coefficient
					float32 d = 2.0f * _springMass * _dampingRatio * omega;

					// Spring stiffness
					float32 k = _springMass * omega * omega;

					// magic formulas
					float32 h = data.step.dt;
					_gamma = h * (d + h * k);
					if (_gamma > 0.0f)
					{
						_gamma = 1.0f / _gamma;
					}

					_bias = C * h * k * _gamma;

					_springMass = invMass + _gamma;
					if (_springMass > 0.0f)
					{
						_springMass = 1.0f / _springMass;
					}
				}
			}
			else
			{
				_springImpulse = 0.0f;
			}

			// Rotational motor
			if (_enableMotor)
			{
				_motorMass = iA + iB;
				if (_motorMass > 0.0f)
				{
					_motorMass = 1.0f / _motorMass;
				}
			}
			else
			{
				_motorMass = 0.0f;
				_motorImpulse = 0.0f;
			}

			if (data.step.warmStarting)
			{
				// Account for variable time step.
				_impulse *= data.step.dtRatio;
				_springImpulse *= data.step.dtRatio;
				_motorImpulse *= data.step.dtRatio;

				b2Vec2 P = _impulse * _ay + _springImpulse * _ax;
				float32 LA = _impulse * _sAy + _springImpulse * _sAx + _motorImpulse;
				float32 LB = _impulse * _sBy + _springImpulse * _sBx + _motorImpulse;

				vA -= _invMassA * P;
				wA -= _invIA * LA;

				vB += _invMassB * P;
				wB += _invIB * LB;
			}
			else
			{
				_impulse = 0.0f;
				_springImpulse = 0.0f;
				_motorImpulse = 0.0f;
			}

			data.velocities[_indexA].v = vA;
			data.velocities[_indexA].w = wA;
			data.velocities[_indexB].v = vB;
			data.velocities[_indexB].w = wB;
		}

		void b2WheelJoint::SolveVelocityConstraints(const b2SolverData& data)
		{
			float32 mA = m_invMassA, mB = m_invMassB;
			float32 iA = m_invIA, iB = m_invIB;

			b2Vec2 vA = data.velocities[m_indexA].v;
			float32 wA = data.velocities[m_indexA].w;
			b2Vec2 vB = data.velocities[m_indexB].v;
			float32 wB = data.velocities[m_indexB].w;

			// Solve spring constraint
			{
				float32 Cdot = b2Dot(m_ax, vB - vA) + m_sBx * wB - m_sAx * wA;
				float32 impulse = -m_springMass * (Cdot + m_bias + m_gamma * m_springImpulse);
				m_springImpulse += impulse;

				b2Vec2 P = impulse * m_ax;
				float32 LA = impulse * m_sAx;
				float32 LB = impulse * m_sBx;

				vA -= mA * P;
				wA -= iA * LA;

				vB += mB * P;
				wB += iB * LB;
			}

			// Solve rotational motor constraint
			{
				float32 Cdot = wB - wA - m_motorSpeed;
				float32 impulse = -m_motorMass * Cdot;

				float32 oldImpulse = m_motorImpulse;
				float32 maxImpulse = data.step.dt * m_maxMotorTorque;
				m_motorImpulse = b2Clamp(m_motorImpulse + impulse, -maxImpulse, maxImpulse);
				impulse = m_motorImpulse - oldImpulse;

				wA -= iA * impulse;
				wB += iB * impulse;
			}

			// Solve point to line constraint
			{
				float32 Cdot = b2Dot(m_ay, vB - vA) + m_sBy * wB - m_sAy * wA;
				float32 impulse = -m_mass * Cdot;
				m_impulse += impulse;

				b2Vec2 P = impulse * m_ay;
				float32 LA = impulse * m_sAy;
				float32 LB = impulse * m_sBy;

				vA -= mA * P;
				wA -= iA * LA;

				vB += mB * P;
				wB += iB * LB;
			}

			data.velocities[m_indexA].v = vA;
			data.velocities[m_indexA].w = wA;
			data.velocities[m_indexB].v = vB;
			data.velocities[m_indexB].w = wB;
		}

		bool b2WheelJoint::SolvePositionConstraints(const b2SolverData& data)
		{
			b2Vec2 cA = data.positions[m_indexA].c;
			float32 aA = data.positions[m_indexA].a;
			b2Vec2 cB = data.positions[m_indexB].c;
			float32 aB = data.positions[m_indexB].a;

			b2Rot qA(aA), qB(aB);

			b2Vec2 rA = b2Mul(qA, m_localAnchorA - m_localCenterA);
			b2Vec2 rB = b2Mul(qB, m_localAnchorB - m_localCenterB);
			b2Vec2 d = (cB - cA) + rB - rA;

			b2Vec2 ay = b2Mul(qA, m_localYAxisA);

			float32 sAy = b2Cross(d + rA, ay);
			float32 sBy = b2Cross(rB, ay);

			float32 C = b2Dot(d, ay);

			float32 k = m_invMassA + m_invMassB + m_invIA * m_sAy * m_sAy + m_invIB * m_sBy * m_sBy;

			float32 impulse;
			if (k != 0.0f)
			{
				impulse = - C / k;
			}
			else
			{
				impulse = 0.0f;
			}

			b2Vec2 P = impulse * ay;
			float32 LA = impulse * sAy;
			float32 LB = impulse * sBy;

			cA -= m_invMassA * P;
			aA -= m_invIA * LA;
			cB += m_invMassB * P;
			aB += m_invIB * LB;

			data.positions[m_indexA].c = cA;
			data.positions[m_indexA].a = aA;
			data.positions[m_indexB].c = cB;
			data.positions[m_indexB].a = aB;

			return b2Abs(C) <= b2_linearSlop;
		}

		b2Vec2 b2WheelJoint::GetAnchorA() const
		{
			return m_bodyA->GetWorldPoint(m_localAnchorA);
		}

		b2Vec2 b2WheelJoint::GetAnchorB() const
		{
			return m_bodyB->GetWorldPoint(m_localAnchorB);
		}

		b2Vec2 b2WheelJoint::GetReactionForce(float32 inv_dt) const
		{
			return inv_dt * (m_impulse * m_ay + m_springImpulse * m_ax);
		}

		float32 b2WheelJoint::GetReactionTorque(float32 inv_dt) const
		{
			return inv_dt * m_motorImpulse;
		}

		float32 b2WheelJoint::GetJointTranslation() const
		{
			b2Body* bA = m_bodyA;
			b2Body* bB = m_bodyB;

			b2Vec2 pA = bA->GetWorldPoint(m_localAnchorA);
			b2Vec2 pB = bB->GetWorldPoint(m_localAnchorB);
			b2Vec2 d = pB - pA;
			b2Vec2 axis = bA->GetWorldVector(m_localXAxisA);

			float32 translation = b2Dot(d, axis);
			return translation;
		}

		float32 b2WheelJoint::GetJointSpeed() const
		{
			float32 wA = m_bodyA->m_angularVelocity;
			float32 wB = m_bodyB->m_angularVelocity;
			return wB - wA;
		}

		bool b2WheelJoint::IsMotorEnabled() const
		{
			return m_enableMotor;
		}

		void b2WheelJoint::EnableMotor(bool flag)
		{
			m_bodyA->SetAwake(true);
			m_bodyB->SetAwake(true);
			m_enableMotor = flag;
		}

		void b2WheelJoint::SetMotorSpeed(float32 speed)
		{
			m_bodyA->SetAwake(true);
			m_bodyB->SetAwake(true);
			m_motorSpeed = speed;
		}

		void b2WheelJoint::SetMaxMotorTorque(float32 torque)
		{
			m_bodyA->SetAwake(true);
			m_bodyB->SetAwake(true);
			m_maxMotorTorque = torque;
		}

		float32 b2WheelJoint::GetMotorTorque(float32 inv_dt) const
		{
			return inv_dt * m_motorImpulse;
		}

		void b2WheelJoint::Dump()
		{
			int32 indexA = m_bodyA->m_islandIndex;
			int32 indexB = m_bodyB->m_islandIndex;

			b2Log("  b2WheelJointDef jd;\n");
			b2Log("  jd.bodyA = bodies[%d];\n", indexA);
			b2Log("  jd.bodyB = bodies[%d];\n", indexB);
			b2Log("  jd.collideConnected = bool(%d);\n", m_collideConnected);
			b2Log("  jd.localAnchorA.Set(%.15lef, %.15lef);\n", m_localAnchorA.x, m_localAnchorA.y);
			b2Log("  jd.localAnchorB.Set(%.15lef, %.15lef);\n", m_localAnchorB.x, m_localAnchorB.y);
			b2Log("  jd.localAxisA.Set(%.15lef, %.15lef);\n", m_localXAxisA.x, m_localXAxisA.y);
			b2Log("  jd.enableMotor = bool(%d);\n", m_enableMotor);
			b2Log("  jd.motorSpeed = %.15lef;\n", m_motorSpeed);
			b2Log("  jd.maxMotorTorque = %.15lef;\n", m_maxMotorTorque);
			b2Log("  jd.frequencyHz = %.15lef;\n", m_frequencyHz);
			b2Log("  jd.dampingRatio = %.15lef;\n", m_dampingRatio);
			b2Log("  joints[%d] = m_world->CreateJoint(&jd);\n", m_index);
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
