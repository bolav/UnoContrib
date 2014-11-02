/*
* Box2D: r313
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
	/// Profiling data. Times are in milliseconds.
	public struct Profile
	{
		public float step;
		public float collide;
		public float solve;
		public float solveInit;
		public float solveVelocity;
		public float solvePosition;
		public float broadphase;
		public float solveTOI;
	}

    /// This is an internal structure.
    public struct TimeStep
    {
        public float dt;			// time step
        public float inv_dt;		// inverse time step (0 if dt == 0).
        public float dtRatio;	    // dt * inv_dt0
        public int velocityIterations;
        public int positionIterations;
        public bool warmStarting;
    }
}
