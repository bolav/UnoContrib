using Uno;
using Uno.UX;
using Uno.Collections;
using Experimental.Data;
using TowerBuilder;
using Uno.Physics.Box2D;

public class RubeLoader : TowerBuilder.TestBed
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
	
	public int JsonInt(JsonReader j, string k, int defaultValue = 0) {
		if (j.HasKey(k)) {
			return j[k].AsInteger();
		}
		else {
			return defaultValue;
		}
	}
	public bool JsonBool(JsonReader j, string k, bool defaultValue = false) {
		if (j.HasKey(k)) {
			return j[k].AsBool();
		}
		else {
			return defaultValue;
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

	protected override void OnInitializeTestBed()
	{
		List<Body> bodies = new List<Body>();
		debug_log "OnInitializeTestBed";
		if (RubeFile != null) {
			if (Rube.HasKey("body")) {
				var val = Rube["body"];
				for (var i = 0; i<val.Count; i++) {
					var bodyValue = val[i];
					var bd = new BodyDef();
			        bd.type = (BodyType)bodyValue["type"].AsInteger();
					bd.position = JsonFloat2(bodyValue["position"]);
					bd.angle = bodyValue["angle"].AsFloat();
					var body = World.CreateBody(bd);
					var fval = bodyValue["fixture"];
					for (var j = 0; j < fval.Count; j++) {
						var fixtureValue = fval[j];
						var fd = new FixtureDef();
						fd.friction = fixtureValue["restitution"].AsFloat();
						fd.friction = fixtureValue["friction"].AsFloat();
						fd.density = fixtureValue["density"].AsFloat();
						fd.isSensor = JsonBool(fixtureValue, "sensor", false);
						fd.filter.categoryBits = (ushort)JsonInt(fixtureValue, "filter-categoryBits", 0x0001);
						fd.filter.maskBits = (ushort)JsonInt(fixtureValue, "filter-maskBits", 0xffff);
						fd.filter.groupIndex = (short)JsonInt(fixtureValue, "filter-groupIndex", 0);
						if (fixtureValue.HasKey("circle")) {
					        var shape = new CircleShape();
							shape._radius = fixtureValue["circle"]["radius"].AsFloat();
							shape._p = JsonFloat2(fixtureValue["circle"]["center"]);
							fd.shape = shape;
							body.CreateFixture(fd);
						}
						else if (fixtureValue.HasKey("polygon")) {
							int numVertices = fixtureValue["polygon"]["vertices"]["x"].Count;
							if (numVertices > 8) {
								debug_log "Too many vertices";
							}
							else if (numVertices < 2) {
								debug_log "Too few vertices";
							}
							else if (numVertices == 2) {
								debug_log "Should be edge";
							}
							float2[] vertices = new float2[numVertices];
					        var shape = new PolygonShape();
							for (var ii = 0; ii < numVertices; ii++) {
								vertices[ii] = float2(fixtureValue["polygon"]["vertices"]["x"][ii].AsFloat(), fixtureValue["polygon"]["vertices"]["y"][ii].AsFloat());
							}
							shape.Set(vertices, numVertices);
							fd.shape = shape;
							body.CreateFixture(fd);
						}
						else {
							debug_log "No shapetype for fixture";
							foreach (var k in fixtureValue.Keys) {
								debug_log k;
							}
						}
					}
				}
				bodies.Add(body);
			}
			if (Rube.HasKey("joint")) {
				var val = Rube["joint"];
				for (var i = 0; i<val.Count; i++) {
				}
			}
		}
	}
}

