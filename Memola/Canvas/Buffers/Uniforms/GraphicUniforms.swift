//
//  GraphicUniforms.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

struct GraphicUniforms {
    var color: vector_float4

    init(color: [CGFloat]) {
        self.color = [color[0].float, color[1].float, color[2].float, color[3].float]
    }
}
