//
//  Quad.metal
//  Memola
//
//  Created by Dscyre Scotti on 5/12/24.
//

#include <metal_stdlib>
using namespace metal;

struct Quad {
    float originX;
    float originY;
    float size;
    float rotation;
    int shape;
    float4 color;
};

struct Vertex {
    float4 position;
    float2 textCoord;
    float4 color;
    float2 origin;
    float rotation;
};

Vertex createVertex(Quad quad, float2 factor, float2 textCoord) {
    Vertex output;
    float x = quad.originX + factor.x;
    float y = quad.originY + factor.y;
    output.position = float4(x, y, 0, 1);
    output.textCoord = textCoord;
    output.color = quad.color;
    output.origin = float2(quad.originX, quad.originY);
    output.rotation = quad.rotation;
    return output;
}

kernel void generate_stroke_vertices(
    device Quad *quads [[buffer(0)]],
    device Vertex *vertices [[buffer(1)]],
    uint gid [[thread_position_in_grid]]
) {
    uint index = gid * 6;
    Quad quad = quads[gid];
    float halfSize = quad.size * 0.5;
    vertices[index] = createVertex(quad, float2(-halfSize, -halfSize), float2(0, 0));
    vertices[index + 1] = createVertex(quad, float2(halfSize, -halfSize), float2(1, 0));
    vertices[index + 2] = createVertex(quad, float2(-halfSize, halfSize), float2(0, 1));
    vertices[index + 3] = createVertex(quad, float2(halfSize, -halfSize), float2(1, 0));
    vertices[index + 4] = createVertex(quad, float2(-halfSize, halfSize), float2(0, 1));
    vertices[index + 5] = createVertex(quad, float2(halfSize, halfSize), float2(1, 1));
}
