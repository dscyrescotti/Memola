//
//  Grid.metal
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float pointSize [[point_size]];
};

struct Uniforms {
    float ratio;
    float zoom;
    float4x4 transform;
};

vertex Vertex vertex_grid(
    constant Vertex *vertices [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(11)]],
    uint vertexId [[vertex_id]]
) {
    Vertex _vertex = vertices[vertexId];
    float x = _vertex.position.x * uniforms.ratio;
    float y = _vertex.position.y * uniforms.ratio;
    float4 position = float4(x, y, 0, 1);
    _vertex.position = uniforms.transform * position;
    _vertex.pointSize = 10 * uniforms.zoom / 12;
    return _vertex;
}

fragment float4 fragment_grid(
    Vertex _vertex [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    float dist = length(pointCoord - float2(0.5));
    float4 color = float4(0.752, 0.752, 0.752, 1);
    color.a = 1.0 - smoothstep(0.4, 0.5, dist);
    return color;
}
