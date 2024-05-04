//
//  Viewport.metal
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[position]];
    float2 textCoord;
};

struct Uniforms {
    float4x4 transform;
};

vertex Vertex vertex_viewport(
    constant Vertex *vertices [[buffer(0)]],
    uint vertexId [[vertex_id]]
) {
    Vertex _vertex = vertices[vertexId];
    return _vertex;
}

vertex Vertex vertex_viewport_update(
    constant Vertex *vertices [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(11)]],
    uint vertexId [[vertex_id]]
) {
    Vertex _vertex = vertices[vertexId];
    _vertex.position = uniforms.transform * _vertex.position;
    return _vertex;
}

fragment float4 fragment_viewport(
    Vertex _vertex [[stage_in]],
    texture2d<float> offscreenTexture [[texture(0)]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 sampledColor = float4(offscreenTexture.sample(textureSampler, _vertex.textCoord));
    return sampledColor;
}
