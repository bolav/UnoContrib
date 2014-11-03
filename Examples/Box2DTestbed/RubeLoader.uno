using Uno;
using Uno.UX;
using Uno.Collections;
using Experimental.Data;
using Uno.Physics.Box2D;

namespace TestBed {
	public class RubeLoader : TestBed
	{
	
		[Content]
		public BundleFile RubeFile { get; set; }

		JsonReader _rube;
		[Content]
		public JsonReader Rube {
			get {
				if (_rube == null) {
					if (RubeFile != null) {
						_rube = new JsonReader(RubeFile.ReadAllText());
					}
				}
				return _rube;
			}
			set {
				_rube = value;
			}
		}
	
		internal Dictionary<Body,string> _BodyToNameMap;
		public Dictionary<Body,string> BodyToNameMap {
			get {
				if (_BodyToNameMap == null) {
					_BodyToNameMap = new Dictionary<Body,string>();
				}
				return _BodyToNameMap;
			}
			private set {
				_BodyToNameMap = value;
			}
		}
		public Body GetBodyByName (string name) {
			foreach(KeyValuePair<Body, string> entry in _BodyToNameMap)
			{
				if (entry.Value == name) {
					return entry.Key;
				}
			}
			return null;
		}

		public int JsonInt(JsonReader j, string k, int defaultValue = 0) {
			if (j.HasKey(k)) {
				return j[k].AsInteger();
			}
			else {
				return defaultValue;
			}
		}
		public bool JsonBool(string k, JsonReader j, bool defaultValue = false) {
			if (j.HasKey(k)) {
				return j[k].AsBool();
			}
			else {
				return defaultValue;
			}
		}

		public string JsonString(string k, JsonReader j, string defaultValue = "") {
			if (j.HasKey(k)) {
				return j[k].AsString();
			}
			else {
				return defaultValue;
			}
		}

		public float jsonToFloat(string k, JsonReader j, float defaultValue = 0) {
			if (j.HasKey(k)) {
				return j[k].AsFloat();
			}
			else {
				return defaultValue;
			}
		}
	
		public float2 jsonToVec(string k, JsonReader j, int index = -1, float2 defaultValue = float2(0)) {
			if (j[k].AsString() == "0") {
				return defaultValue;
			}
			if (!j.HasKey(k)) {
				return defaultValue;
			}
			if (index == -1) {
				return JsonFloat2(j[k], defaultValue);
			}
			else {
				return float2(j[k]["x"][index].AsFloat(), j[k]["y"][index].AsFloat());
			}
		}

		public float2 JsonFloat2(JsonReader j, float2 defaultValue = float2(0)) {
			if (!j.HasKey("x")) {
				return defaultValue;
			}
			if (!j.HasKey("y")) {
				return defaultValue;
			}
			return float2(j["x"].AsFloat(), j["y"].AsFloat());
		}

		public void setBodyName (Body body, string name) {
			BodyToNameMap[body] = name;
		}

		protected override void OnInitializeTestBed()
		{
			List<Body> bodies = new List<Body>();
			if (RubeFile != null) {
				var worldValue = Rube;
			    World world = new World( jsonToVec("gravity", worldValue) );
			    world.AllowSleeping = worldValue["allowSleep"].AsBool();

			    world.SetAutoClearForces( worldValue["autoClearForces"].AsBool() );
			    world.WarmStarting = worldValue["warmStarting"].AsBool();
			    world.ContinuousPhysics = worldValue["continuousPhysics"].AsBool();
			    world.SubStepping = worldValue["subStepping"].AsBool();
				World = world;

				if (Rube.HasKey("body")) {
					var val = Rube["body"];
					for (var i = 0; i<val.Count; i++) {
						var bodyValue = val[i];
						var bodyDef = new BodyDef();
				        bodyDef.type = (BodyType)bodyValue["type"].AsInteger();
						bodyDef.position = JsonFloat2(bodyValue["position"]);
						bodyDef.angle = bodyValue["angle"].AsFloat();
					    bodyDef.linearVelocity = jsonToVec("linearVelocity", bodyValue);
					    bodyDef.angularVelocity = jsonToFloat("angularVelocity", bodyValue);
					    bodyDef.linearDamping = jsonToFloat("linearDamping", bodyValue, 0);
					    bodyDef.angularDamping = jsonToFloat("angularDamping", bodyValue, 0);
					    bodyDef.inertiaScale = jsonToFloat("gravityScale", bodyValue, 1);

					    bodyDef.allowSleep = JsonBool("allowSleep",bodyValue,true);
					    bodyDef.awake = JsonBool("awake", bodyValue, false);
					    bodyDef.fixedRotation = JsonBool("fixedRotation",bodyValue, false);
					    bodyDef.bullet = JsonBool("bullet",bodyValue,false);
					    bodyDef.active = JsonBool("active",bodyValue,true);
						var body = World.CreateBody(bodyDef);

					    string bodyName = JsonString("name", bodyValue, "");
					    if ( bodyName != "" ) {
					        //printf("Found named body: %s\n",bodyName.c_str());
					        setBodyName(body, bodyName);
					    }

						var fval = bodyValue["fixture"];
						for (var j = 0; j < fval.Count; j++) {
							var fixtureValue = fval[j];
							var fd = new FixtureDef();
							fd.restitution = fixtureValue["restitution"].AsFloat();
							fd.friction = fixtureValue["friction"].AsFloat();
							fd.density = fixtureValue["density"].AsFloat();
							fd.isSensor = JsonBool("sensor", fixtureValue, false);
							fd.filter.categoryBits = (ushort)JsonInt(fixtureValue, "filter-categoryBits", 0x0001);
							fd.filter.maskBits = (ushort)JsonInt(fixtureValue, "filter-maskBits", 0xffff);
							fd.filter.groupIndex = (short)JsonInt(fixtureValue, "filter-groupIndex", 0);
							if (fixtureValue.HasKey("circle")) {
						        var shape = new CircleShape();
								shape._radius = fixtureValue["circle"]["radius"].AsFloat();
								shape._p = jsonToVec("center",fixtureValue["circle"]);
								fd.shape = shape;
								body.CreateFixture(fd);
							}
							else if (fixtureValue.HasKey("chain")) {
						        var chainShape = new ChainShape();
								int numVertices = fixtureValue["chain"]["vertices"]["x"].Count;
								var vertices = new float2[numVertices];
								for (var ii = 0; ii < numVertices; ii++) {
						            vertices[ii] = jsonToVec("vertices", fixtureValue["chain"], ii);
								}
						        chainShape.CreateChain(vertices, numVertices);
						        chainShape._hasPrevVertex = JsonBool("hasPrevVertex",fixtureValue["chain"],false);
						        chainShape._hasNextVertex = JsonBool("hasNextVertex",fixtureValue["chain"],false);
						        if ( chainShape._hasPrevVertex )
						            chainShape._prevVertex = jsonToVec("prevVertex", fixtureValue["chain"]);
						        if ( chainShape._hasNextVertex )
						            chainShape._nextVertex = jsonToVec("nextVertex", fixtureValue["chain"]);
								fd.shape = chainShape;
								body.CreateFixture(fd);
							}
							else if (fixtureValue.HasKey("polygon")) {
								int numVertices = fixtureValue["polygon"]["vertices"]["x"].Count;
								if (numVertices > 8) {
									debug_log "polygon Too many vertices";
								}
								else if (numVertices < 2) {
									debug_log "polygon Too few vertices";
								}
								else if (numVertices == 2) {
									debug_log "polygon Should be edge";
								}
								else {
									float2[] vertices = new float2[numVertices];
							        var shape = new PolygonShape();
									for (var ii = 0; ii < numVertices; ii++) {
										vertices[ii] = float2(fixtureValue["polygon"]["vertices"]["x"][ii].AsFloat(), fixtureValue["polygon"]["vertices"]["y"][ii].AsFloat());
									}
									shape.Set(vertices, numVertices);
									fd.shape = shape;
									body.CreateFixture(fd);
								}
							}
							else {
								debug_log "No shapetype for fixture";
								foreach (var k in fixtureValue.Keys) {
									debug_log k;
								}
							}
						}
					    //may be necessary if user has overridden mass characteristics
						MassData massData = new MassData();
					    massData.mass = jsonToFloat("massData-mass", bodyValue);
					    massData.center = jsonToVec("massData-center", bodyValue);
					    massData.I = jsonToFloat("massData-I", bodyValue);
					    body.SetMassData(ref massData);

						bodies.Add(body);
					}
				}
				if (Rube.HasKey("joint")) {
					var val = Rube["joint"];
					for (var i = 0; i<val.Count; i++) {
						var jointValue = val[i];
						JointDef jointDef = null;
						var bodyIndexA = jointValue["bodyA"].AsInteger();
						var bodyIndexB = jointValue["bodyB"].AsInteger();
						if (jointValue["type"].AsString() == "revolute") {
							var revoluteDef = new RevoluteJointDef();
							revoluteDef.localAnchorA = JsonFloat2(jointValue["anchorA"]);
							revoluteDef.localAnchorB = JsonFloat2(jointValue["anchorB"]);
							revoluteDef.referenceAngle = jointValue["refAngle"].AsFloat();
							revoluteDef.enableLimit = jointValue["enableLimit"].AsBool();
							revoluteDef.lowerAngle = jointValue["lowerLimit"].AsFloat();
							revoluteDef.upperAngle = jointValue["upperLimit"].AsFloat();
							revoluteDef.enableMotor = jointValue["enableMotor"].AsBool();
							revoluteDef.motorSpeed = jointValue["motorSpeed"].AsFloat();
							revoluteDef.maxMotorTorque = jointValue["maxMotorTorque"].AsFloat();

							jointDef = revoluteDef;
						}
						else if (jointValue["type"].AsString() == "prismatic") {
							var distanceDef = new DistanceJointDef();
							jointDef = distanceDef;
						}
						else if (jointValue["type"].AsString() == "distance") {
							var distanceDef = new DistanceJointDef();
							distanceDef.localAnchorA = JsonFloat2(jointValue["anchorA"]);
							distanceDef.localAnchorB = JsonFloat2(jointValue["anchorB"]);
					        distanceDef.length = jsonToFloat("length", jointValue);
					        distanceDef.frequencyHz = jsonToFloat("frequency", jointValue);
					        distanceDef.dampingRatio = jsonToFloat("dampingRatio", jointValue);

							jointDef = distanceDef;
						}
						// TODO : Wheel in Box2D
						// else if (jointValue["type"].AsString() == "wheel") {
						// 	var wheelDef = new WheelJointDef();
						// 	wheelDef.localAnchorA = JsonFloat2(jointValue["anchorA"]);
						// 	wheelDef.localAnchorB = JsonFloat2(jointValue["anchorB"]);
						// 				        wheelDef.localAxisA = jsonToVec("localAxisA", jointValue);
						// 				        wheelDef.enableMotor = jointValue["enableMotor"].AsBool();
						// 				        wheelDef.motorSpeed = jsonToFloat("motorSpeed", jointValue);
						// 				        wheelDef.maxMotorTorque = jsonToFloat("maxMotorTorque", jointValue);
						// 				        wheelDef.frequencyHz = jsonToFloat("springFrequency", jointValue);
						// 				        wheelDef.dampingRatio = jsonToFloat("springDampingRatio", jointValue);
						//
						// 	jointDef = wheelDef;
						// }
						// TODO : Motor in Box2D
						// else if (jointValue["type"].AsString() == "motor") {
						// 	var motorDef = new MotorJointDef();
						// 	motorDef.linearOffset = JsonFloat2(jointValue["anchorA"]);
						// 				        motorDef.angularOffset = jsonToFloat("refAngle", jointValue);
						// 				        motorDef.maxForce = jsonToFloat("maxForce", jointValue);
						// 				        motorDef.maxTorque = jsonToFloat("maxTorque", jointValue);
						// 				        motorDef.correctionFactor = jsonToFloat("correctionFactor", jointValue);
						//
						// 	jointDef = motorDef;
						// }
						else if (jointValue["type"].AsString() == "weld") {
							var weldDef = new WeldJointDef();
							weldDef.localAnchorA = JsonFloat2(jointValue["anchorA"]);
							weldDef.localAnchorB = JsonFloat2(jointValue["anchorB"]);
					        weldDef.referenceAngle = jsonToFloat("refAngle", jointValue);
							// TODO: update WeldJoint
					        // weldDef.frequencyHz = jsonToFloat("frequency", jointValue);
					        // weldDef.dampingRatio = jsonToFloat("dampingRatio", jointValue);

							jointDef = weldDef;
						}
						else if (jointValue["type"].AsString() == "friction") {
							var frictionDef = new FrictionJointDef();
							frictionDef.localAnchorA = JsonFloat2(jointValue["anchorA"]);
							frictionDef.localAnchorB = JsonFloat2(jointValue["anchorB"]);
							frictionDef.maxForce = jointValue["maxForce"].AsFloat();
							frictionDef.maxTorque = jointValue["maxTorque"].AsFloat();

							jointDef = frictionDef;
						}
						// TODO: Rope in Box2D
						// else if (jointValue["type"].AsString() == "rope") {
						// 	var ropeDef = new RopeJointDef();
						// 				        ropeDef.localAnchorA = jsonToVec("anchorA", jointValue);
						// 				        ropeDef.localAnchorB = jsonToVec("anchorB", jointValue);
						// 				        ropeDef.maxLength = jsonToFloat("maxLength", jointValue);
						// 	jointDef = ropeDef;
						// 				    }
						else {
							debug_log "Unknown type: " + jointValue["type"].AsString();
						}
						if (jointDef != null) {
							jointDef.bodyA = bodies[bodyIndexA];
							jointDef.bodyB = bodies[bodyIndexB];
							World.CreateJoint(jointDef);
						}
					}
				}
			}
		}
	}
}
