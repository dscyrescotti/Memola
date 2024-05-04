//
//  QuadVertex.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

struct QuadVertex: Codable {
    var position: vector_float4
    var textCoord: vector_float2
    var color: vector_float4
    var origin: vector_float2
    var rotation: Float
}

extension QuadVertex {
    init(x: CGFloat, y: CGFloat, textCoord: CGPoint, color: [CGFloat], origin: CGPoint, rotation: CGFloat) {
        self.position = [x.float, y.float, 0, 1]
        self.textCoord = [textCoord.x.float, textCoord.y.float]
        self.color = [color[0].float, color[1].float, color[2].float, color[3].float]
        self.origin = [origin.x.float, origin.y.float]
        self.rotation = rotation.float
    }

    func getOrigin() -> CGPoint {
        CGPoint(x: CGFloat(origin[0]), y: CGFloat(origin[1]))
    }
}

