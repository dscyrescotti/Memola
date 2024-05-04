//
//  Stroke.metal
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[position]];
    float2 textCoord;
    float4 color;
    float2 origin;
    float rotation;
};

struct VertexOut {
    float4 position [[position]];
    float2 textCoord;
    float4 color;
};

struct Uniforms {
    float4x4 transform;
};

vertex VertexOut vertex_stroke(
    constant VertexIn *vertices [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(11)]],
    uint vertexId [[vertex_id]]
) {
    VertexIn in = vertices[vertexId];

    float2 rotatedPosition;
    rotatedPosition.x = cos(in.rotation) * (in.position.x - in.origin.x) - sin(in.rotation) * (in.position.y - in.origin.y) + in.origin.x;
    rotatedPosition.y = sin(in.rotation) * (in.position.x - in.origin.x) + cos(in.rotation) * (in.position.y - in.origin.y) + in.origin.y;

    VertexOut out;
    out.position = uniforms.transform * float4(rotatedPosition, 0, 1);
    out.textCoord = in.textCoord;
    out.color = in.color;

    return out;
}

fragment float4 fragment_stroke(
    VertexOut out [[stage_in]],
    texture2d<float> texture [[texture(0)]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(texture.sample(textureSampler, out.textCoord));
    return float4(1, 1, 1, color.a);
}
