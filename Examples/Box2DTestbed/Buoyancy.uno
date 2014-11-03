using Uno;
using Uno.UX;
using Uno.Collections;
using Experimental.Data;
using Uno.Physics.Box2D;
using Uno.Platform;

namespace TestBed {
    internal struct FixturePair 
	{
		public Fixture first;
		public Fixture second;
        public int CompareTo(FixturePair other) {
			debug_log "Running CompareTo";
        	if (first == other.first && second == other.second) {
        		return 0;
        	}
			return 1;
        }
	}
	public class Buoyancy : RubeLoader, IContactListener
	{
		internal FixturePair make_pair (Fixture a, Fixture b) {
			FixturePair p; // = new FixturePair();
			p.first = a;
			p.second = b;
			return p;
		}
		protected override void OnInitializeTestBed()
		{
			debug_log "OnInitializeTestBed";
			base.OnInitializeTestBed();
			World.ContactListener = this;
			// var s = Parent as RubeScene;
			// s.KeyPressed += OnKeyPressed;
			Focus();
			KeyPressed += OnKeyPressed;
		}
		
		public void OnKeyPressed (object sender, Fuse.KeyPressedArgs args) {
			// debug_log sender + " " + args.Key;
			if (args.Key == Key.A) {
				GetBodyByName("Ball").ApplyForce(float2(-120,0), float2(0));
			}
			else if (args.Key == Key.D) {
				GetBodyByName("Ball").ApplyForce(float2(120,0), float2(0));
				
			}
			else if (args.Key == Key.W) {
				GetBodyByName("Ball").ApplyForce(float2(0,400), float2(0));
				
			}
			
		}
		
		HashSet <FixturePair> _fixturePairs = new HashSet<FixturePair>();
        public void BeginContact(Contact contact) {
			debug_log "BeginContact " + _fixturePairs.Count;
	        Fixture fixtureA = contact.GetFixtureA();
	        Fixture fixtureB = contact.GetFixtureB();

	        //This assumes every sensor fixture is fluid, and will interact
	        //with every dynamic body.
	        if ( fixtureA.IsSensor() &&
	             fixtureB.GetBody().GetBodyType() == BodyType.Dynamic )
	            _fixturePairs.Add( make_pair(fixtureA, fixtureB) );
	        else if ( fixtureB.IsSensor() &&
	                  fixtureA.GetBody().GetBodyType() == BodyType.Dynamic )
	            _fixturePairs.Add( make_pair(fixtureB, fixtureA) );
        	
        }
        public void EndContact(Contact contact) {
			debug_log "EndContact";
	        Fixture fixtureA = contact.GetFixtureA();
	        Fixture fixtureB = contact.GetFixtureB();

	        //This check should be the same as for BeginContact, but here
	        //we remove the fixture pair
	        if ( fixtureA.IsSensor() &&
	             fixtureB.GetBody().GetBodyType() == BodyType.Dynamic ) {
					 debug_log "try to remove";
	 	             debug_log _fixturePairs.Remove( make_pair(fixtureA, fixtureB) );
	             }
	        else if ( fixtureB.IsSensor() &&
	                  fixtureA.GetBody().GetBodyType() == BodyType.Dynamic ) {
	 					 debug_log "try to remove";
		  	             debug_log _fixturePairs.Remove( make_pair(fixtureB, fixtureA) );
	                  }
        }
		
		protected override void Step() {
		// protected void Step2() {
			base.Step();
			foreach (var it in _fixturePairs) {

	            //fixtureA is the fluid
	            Fixture fixtureA = it.first;
	            Fixture fixtureB = it.second;

	            float density = fixtureA.GetDensity();

	            List<float2> intersectionPoints = new List<float2>();
	            if ( findIntersectionOfFixtures(fixtureA, fixtureB, ref intersectionPoints) ) {

	                //find centroid
	                float area = 0;
	                float2 centroid = ComputeCentroid( intersectionPoints, ref area);

	                //apply buoyancy force
	                float displacedMass = fixtureA.GetDensity() * area;
					// debug_log "Area " + area;
					// debug_log "displacedMass " + displacedMass;
	                float2 gravity = float2( 0, -10 );
	                float2 buoyancyForce = displacedMass * -gravity;
	                fixtureB.GetBody().ApplyForce( buoyancyForce, centroid );

	                /*
	                //simple drag
	                //find relative velocity between object and fluid
	                float2 velDir = fixtureB.GetBody().GetLinearVelocityFromWorldPoint( centroid ) -
	                        fixtureA.GetBody().GetLinearVelocityFromWorldPoint( centroid );
	                float vel = velDir.Normalize();

	                float dragMod = 1;//adjust as desired
	                float dragMag = fixtureA.GetDensity() * vel * vel;
	                float2 dragForce = dragMod * dragMag * -velDir;
	                fixtureB.GetBody().ApplyForce( dragForce, centroid );
	                float angularDrag = area * -fixtureB.GetBody().GetAngularVelocity();
	                fixtureB.GetBody().ApplyTorque( angularDrag );
	                */

	                //apply complex drag
	                float dragMod = 0.5f;//adjust as desired
	                float liftMod = 0.25f;//adjust as desired
	                float maxDrag = 2000;//adjust as desired
	                float maxLift = 500;//adjust as desired
	                for (int i = 0; i < intersectionPoints.Count; i++) {
	                    float2 v0 = intersectionPoints[i];
	                    float2 v1 = intersectionPoints[(i+1)%intersectionPoints.Count];
	                    float2 midPoint = 0.5f * (v0+v1);

	                    //find relative velocity between object and fluid at edge midpoint
	                    float2 velDir = fixtureB.GetBody().GetLinearVelocityFromWorldPoint( midPoint ) -
	                            fixtureA.GetBody().GetLinearVelocityFromWorldPoint( midPoint );
	                    float vel = Vector.Length(velDir);
						Vector.Normalize(velDir);

	                    float2 edge = v1 - v0;
	                    float edgeLength = Vector.Length(edge);
						edge = Vector.Normalize(edge);
	                    float2 normal = MathUtils.Cross(-1,edge);
	                    float dragDot = Uno.Vector.Dot(normal, velDir);
	                    if ( dragDot < 0 )
	                        continue;//normal points backwards - this is not a leading edge

	                    //apply drag
	                    float dragMag = dragDot * dragMod * edgeLength * density * vel * vel;
	                    dragMag = Math.Min( dragMag, maxDrag );
	                    float2 dragForce = dragMag * -velDir;
	                    fixtureB.GetBody().ApplyForce( dragForce, midPoint );

	                    //apply lift
	                    float liftDot = Uno.Vector.Dot(edge, velDir);
	                    float liftMag =  dragDot * liftDot * liftMod * edgeLength * density * vel * vel;
	                    liftMag = Math.Min( liftMag, maxLift );
	                    float2 liftDir = MathUtils.Cross(1,velDir);
	                    float2 liftForce = liftMag * liftDir;
	                    fixtureB.GetBody().ApplyForce( liftForce, midPoint );
	                }

	                //draw debug info
	                // glColor3f(0,1,1);
	                // glLineWidth(2);
	                // glBegin(GL_LINE_LOOP);
	                // for (int i = 0; i < intersectionPoints.size(); i++)
	                //     glVertex2f( intersectionPoints[i].x, intersectionPoints[i].Y );
	                // glEnd();
	                // glLineWidth(1);
	                /*
	                //line showing buoyancy force
	                if ( area > 0 ) {
	                    glBegin(GL_LINES);
	                    glVertex2f( centroid.x, centroid.Y );
	                    glVertex2f( centroid.x, centroid.Y + area );
	                    glEnd();
	                }*/
	            }
			}
		}
        public void PreSolve(Contact contact, ref Manifold oldManifold) { }
        public void PostSolve(Contact contact, ref ContactImpulse impulse) { }

		bool inside(float2 cp1, float2 cp2, float2 p) {
		    return (cp2.X-cp1.X)*(p.Y-cp1.Y) > (cp2.Y-cp1.Y)*(p.X-cp1.X);
		}

		float2 intersection(float2 cp1, float2 cp2, float2 s, float2 e) {
		    float2 dc = float2( cp1.X - cp2.X, cp1.Y - cp2.Y );
		    float2 dp = float2( s.X - e.X, s.Y - e.Y );
		    float n1 = cp1.X * cp2.Y - cp1.Y * cp2.X;
		    float n2 = s.X * e.Y - s.Y * e.X;
		    float n3 = 1.0f / (dc.X * dp.Y - dc.Y * dp.X);
		    return float2( (n1*dp.X - n2*dc.X) * n3, (n1*dp.Y - n2*dc.Y) * n3);
		}

		//http://rosettacode.org/wiki/Sutherland-Hodgman_polygon_clipping#JavaScript
		bool findIntersectionOfFixtures(Fixture fA, Fixture fB, ref List<float2> outputVertices)
		{
		    //currently this only handles polygon vs polygon
		    if ( fA.GetShape().ShapeType != ShapeType.Polygon ||
		         fB.GetShape().ShapeType != ShapeType.Polygon ) {
					 debug_log "Not Polygons!";
	 		        return false;
		         }

		    PolygonShape polyA = (PolygonShape)fA.GetShape();
		    PolygonShape polyB = (PolygonShape)fB.GetShape();

		    //fill 'subject polygon' from fixtureA polygon
		    for (int i = 0; i < polyA.GetVertexCount(); i++)
		        outputVertices.Add( fA.GetBody().GetWorldPoint( polyA.GetVertex(i) ) );

		    //fill 'clip polygon' from fixtureB polygon
		    List<float2> clipPolygon = new List<float2>();
		    for (int i = 0; i < polyB.GetVertexCount(); i++)
		        clipPolygon.Add( fB.GetBody().GetWorldPoint( polyB.GetVertex(i) ) );

		    float2 cp1 = clipPolygon[clipPolygon.Count-1];
		    for (int j = 0; j < clipPolygon.Count; j++) {
		        float2 cp2 = clipPolygon[j];
		        if ( outputVertices.Count == 0 )
		            return false;
		        float2[] inputList = outputVertices.ToArray();
		        outputVertices.Clear();
		        float2 s = inputList[inputList.Length - 1]; //last on the input list
		        for (int i = 0; i < inputList.Length; i++) {
		            float2 e = inputList[i];
		            if (inside(cp1, cp2, e)) {
		                if (!inside(cp1, cp2, s)) {
		                    outputVertices.Add( intersection(cp1, cp2, s, e) );
		                }
		                outputVertices.Add(e);
		            }
		            else if (inside(cp1, cp2, s)) {
		                outputVertices.Add( intersection(cp1, cp2, s, e) );
		            }
		            s = e;
		        }
		        cp1 = cp2;
		    }

		    return (outputVertices.Count > 0);
		}

		static float2 ComputeCentroid(List<float2> vs, ref float area)
		{
		    int count = vs.Count;
		    // b2Assert(count >= 3);

		    float2 c = float2(0);
		    area = 0.0f;

		    // pRef is the reference point for forming triangles.
		    // It's location doesn't change the result (except for rounding error).
		    float2 pRef = float2(0.0f, 0.0f);

		    float inv3 = 1.0f / 3.0f;

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
		        c += triangleArea * inv3 * (p1 + p2 + p3);
		    }

		    // Centroid
		    if (area > Settings.b2_epsilon)
		        c *= 1.0f / area;
		    else
		        area = 0;
		    return c;
		}

	}
}
