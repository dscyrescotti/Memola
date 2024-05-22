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
    device uint *indices [[buffer(1)]],
    device Vertex *vertices [[buffer(2)]],
    uint gid [[thread_position_in_grid]]
) {
    Quad quad = quads[gid];
    uint index = gid * 6;
    uint vertexIndex = gid * 4;
    float halfSize = quad.size * 0.5;
    vertices[vertexIndex] = createVertex(quad, float2(-halfSize, -halfSize), float2(0, 0));
    vertices[vertexIndex + 1] = createVertex(quad, float2(halfSize, -halfSize), float2(1, 0));
    vertices[vertexIndex + 2] = createVertex(quad, float2(-halfSize, halfSize), float2(0, 1));
    vertices[vertexIndex + 3] = createVertex(quad, float2(halfSize, halfSize), float2(1, 1));

    indices[index] = vertexIndex;
    indices[index + 1] = vertexIndex + 1;
    indices[index + 2] = vertexIndex + 2;
    indices[index + 3] = vertexIndex + 1;
    indices[index + 4] = vertexIndex + 2;
    indices[index + 5] = vertexIndex + 3;
}
