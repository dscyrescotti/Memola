//
//  PhotoVertex.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/13/24.
//

import MetalKit
import Foundation

struct PhotoVertex {
    var position: vector_float4
    var textCoord: vector_float2
}

extension PhotoVertex {
    init(x: CGFloat, y: CGFloat, textCoord: CGPoint) {
        self.position = [x.float, y.float, 0, 1]
        self.textCoord = [textCoord.x.float, textCoord.y.float]
    }
}
