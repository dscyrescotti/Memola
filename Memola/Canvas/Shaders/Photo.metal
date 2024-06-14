//
//  Photo.metal
//  Memola
//
//  Created by Dscyre Scotti on 6/13/24.
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
};

struct Uniforms {
    float4x4 transform;
};

vertex VertexOut vertex_photo(
    constant VertexIn *vertices [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(11)]],
    uint vertexId [[vertex_id]]
) {
    VertexIn in = vertices[vertexId];

    VertexOut out;
    out.position = uniforms.transform * in.position;
    out.textCoord = in.textCoord;

    return out;
}

fragment float4 fragment_photo(
    VertexOut out [[stage_in]]
//    texture2d<float> texture [[texture(0)]]
) {
//    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
//    float4 color = float4(texture.sample(textureSampler, out.textCoord));
//    return color;
    return float4(1, 0, 1, 1);
}
