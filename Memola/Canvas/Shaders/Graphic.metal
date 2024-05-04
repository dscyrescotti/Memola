//
//  Graphic.metal
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[position]];
    float2 textCoord;
};

struct VertexOut {
    float4 position [[position]];
    float2 textCoord;
    float4 color;
};

struct Uniforms {
    float4 color;
};

vertex VertexOut vertex_graphic(
    constant VertexIn *vertices [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(11)]],
    uint vertexId [[vertex_id]]
) {
    VertexIn in = vertices[vertexId];
    VertexOut out;
    out.position = in.position;
    out.textCoord = in.textCoord;
    out.color = uniforms.color;
    return out;
}

fragment float4 fragment_graphic(
    VertexOut out [[stage_in]],
    texture2d<float> offscreenTexture [[texture(0)]]
) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float4 color = float4(offscreenTexture.sample(textureSampler, out.textCoord));
    return float4(out.color.rgb, color.a * out.color.a);
}
