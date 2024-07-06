//
//  PointGridVertex.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

struct PointGridVertex {
    var position: vector_float4
    #if os(macOS)
    var pointSize: Float = 256
    #else
    var pointSize: Float = 10
    #endif
}

extension PointGridVertex {
    init(x: CGFloat, y: CGFloat) {
        self.position = [x.float, y.float, 0, 1]
    }
}
