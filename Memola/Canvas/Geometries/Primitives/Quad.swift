//
//  Quad.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/8/24.
//

import CoreData
import Foundation

struct Quad {
    var originX: CGFloat
    var originY: CGFloat
    var size: CGFloat
    var rotation: CGFloat
    var shape: Int16

    init(object: QuadObject) {
        self.originX = object.originX
        self.originY = object.originY
        self.size = object.size
        self.rotation = object.rotation
        self.shape = object.shape
    }

    init(origin: CGPoint, size: CGFloat, rotation: CGFloat, shape: Int16) {
        self.originX = origin.x
        self.originY = origin.y
        self.size = size
        self.rotation = rotation
        self.shape = shape
    }

    var origin: CGPoint {
        get { CGPoint(x: originX, y: originY) }
        set {
            originX = newValue.x
            originY = newValue.y
        }
    }

    func generateVertices(_ color: [CGFloat]) -> [QuadVertex] {
        guard let shape = QuadShape.init(rawValue: shape) else { return [] }
        switch shape {
        case .rounded:
            return generateRoundedQuad(color)
        case .squared:
            return generateSquaredQuad(color)
        }
    }

    func generateRoundedQuad(_ color: [CGFloat]) -> [QuadVertex] {
        let halfSize = size * 0.5
        return [
            QuadVertex(x: origin.x - halfSize, y: origin.y - halfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + halfSize, y: origin.y - halfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - halfSize, y: origin.y + halfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + halfSize, y: origin.y - halfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - halfSize, y: origin.y + halfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + halfSize, y: origin.y + halfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
    }

    func generateSquaredQuad(_ color: [CGFloat]) -> [QuadVertex] {
        let vHalfSize = size * 0.5
        let hHalfSize = size * 0.15
        return [
            QuadVertex(x: origin.x - hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
    }
}
