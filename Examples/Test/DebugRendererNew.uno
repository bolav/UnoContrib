using Uno.Physics.Box2D;
using Fuse;
using Uno;

public class DebugRenderer : DebugDraw
{
	public DebugRenderer () {
		debug_log "Create DebugRenderer";
	}

	public override void DrawPolygon(ref float2[] vertices, int count, float4 color, float2 center)
	{
		debug_log "DrawPolygon";
	}

    /// Draw a solid closed polygon provided in CCW order.
    public override void DrawSolidPolygon(ref float2[] vertices, int count, float4 color, float2 center)
	{
		debug_log "DrawSolidPolygon " + count;
		draw
		{
			ClipPosition : Spaces.PixelsToClipSpace(vertex_attrib(vertices), Spaces.VirtualResolution);

			PixelColor: float4(1,0,0,1);
			LineWidth : 4f;
			VertexCount: count;

			PrimitiveType: Uno.Graphics.PrimitiveType.Lines;
		};	
		
	}

    /// Draw a circle.
    public override void DrawCircle(float2 center, float radius, float4 color)
	{
		debug_log "DrawCircle";
	}

    /// Draw a solid circle.
    public override void DrawSolidCircle(float2 center, float radius, float2 axis, float4 color)
	{
		debug_log "DrawSolidCircle";
	}

    /// Draw a line segment.
    public override void DrawSegment(float2 p1, float2 p2, float4 color, float2 center)
	{
		debug_log "DrawSegment";
	}

    /// Draw a transform. Choose your own length scale.
    /// @param xf a transform.
    public override void DrawTransform(ref Uno.Physics.Box2D.Transform xf)
	{
		debug_log "DrawTransform";
	}
}

