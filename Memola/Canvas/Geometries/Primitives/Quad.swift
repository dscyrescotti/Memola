//
//  Quad.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/8/24.
//

import CoreData
import MetalKit
import Foundation

struct Quad {
    var originX: Float
    var originY: Float
    var size: Float
    var rotation: Float
    var shape: Int16
    var color: vector_float4

    init(object: QuadObject) {
        self.originX = object.originX.float
        self.originY = object.originY.float
        self.size = object.size.float
        self.rotation = object.rotation.float
        self.shape = object.shape
        self.color = [
            object.color[0].float,
            object.color[1].float,
            object.color[2].float,
            object.color[3].float
        ]
    }

    init(origin: CGPoint, size: CGFloat, rotation: CGFloat, shape: Int16, color: [CGFloat]) {
        self.originX = origin.x.float
        self.originY = origin.y.float
        self.size = size.float
        self.rotation = rotation.float
        self.shape = shape
        self.color = [color[0].float, color[1].float, color[2].float, color[3].float]
    }
}

extension Quad {
    var origin: CGPoint {
        get { CGPoint(x: originX.cgFloat, y: originY.cgFloat) }
        set {
            originX = newValue.x.float
            originY = newValue.y.float
        }
    }

    func getColor() -> [CGFloat] {
        [color.x.cgFloat, color.y.cgFloat, color.z.cgFloat, color.w.cgFloat]
    }
}
