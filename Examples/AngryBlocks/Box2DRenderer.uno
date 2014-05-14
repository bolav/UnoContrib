using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.Scenes;
using Uno.Content;
using Uno.Content.Models;

namespace AngryBlocks
{
	/**
	* Render a Box2D Body as a Quad
	*
	* This contains all the logic necessary to render a Box2D
	* body onto a Quad.
	*
	* It renders it onto the Clip space and performs aspect correction
	* so a 1x1 block looks like a 1x1 block, and is not stretched.
	*
	* It scales everything by factors in the Box2DMath class.
	*
	* TODO: Implement rotation
	*/
	public block RenderBox2DAsQuad
	{
		public float2 Box2DBodyPosition: float2(1, 1);
		public float Box2DBodyRotation: 0;
		public float2 Box2DQuadSize: float2(1, 1);

		// Quad Vertices and Indices
		float2[] Vertices : new [] {float2(0,0),float2( 1,0),float2( 1, 1),float2(0, 1)};
		ushort[] Indices : new ushort[] { 0,1,2,2,3,0 };
		VertexCount : 6;

		float2 AspectCorrection: float2(1 / Context.Aspect, 1);

		float3 QuadPosition: float3(Box2DMath.Box2DToUno(Box2DBodyPosition), 0) * float3(AspectCorrection.XY, 0);
		public float2 Size: Box2DMath.Box2DToUno(Box2DQuadSize) * AspectCorrection;
		float2 VertexData : vertex_attrib(Vertices, Indices);
		float3 QuadOffset: 0.5f * float3(Size, 0);
		public float3 VertexPosition: float3(VertexData.XY * Size, 0) + QuadPosition - QuadOffset;
		ClipPosition : float4(VertexPosition, 1);
		
		public float3 VertexNormal: float3(0, 0, 1);

		public float2 TexCoord : float2(VertexData.X, 1.0f - VertexData.Y);
	}
}