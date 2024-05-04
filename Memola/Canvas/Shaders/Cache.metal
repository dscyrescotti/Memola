//
//  Cache.metal
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

#include <metal_stdlib>
using namespace metal;

kernel void copy_texture_viewport(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    float4 color = inTexture.read(gid);
    outTexture.write(color, gid);
}
