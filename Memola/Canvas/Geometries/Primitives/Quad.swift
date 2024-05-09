//
//  Quad.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/8/24.
//

import Foundation

struct Quad: Codable {
    var origin: CGPoint
    var color: [CGFloat]
    var size: CGFloat
    var rotation: CGFloat
    var shape: QuadShape

    init(origin: CGPoint, size: CGFloat, color: [CGFloat], rotation: CGFloat, shape: QuadShape = .rounded) {
        self.origin = origin
        self.size = size
        self.color = color
        self.rotation = rotation
        self.shape = shape
    }

    func generateVertices() -> [QuadVertex] {
        switch shape {
        case .rounded:
            generateRoundedQuad()
        case .squared:
            generateSquaredQuad()
        case let .calligraphic(vFactor, hFactor):
            generateCalligraphicQuad(vFactor: vFactor, hFactor: hFactor)
        case let .trapezoid(topFactor, bottomFactor, heightFactor):
            generateTrapezoidQuad(topFactor: topFactor, bottomFactor: bottomFactor, heightFactor: heightFactor)
        }
    }

    func generateRoundedQuad() -> [QuadVertex] {
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

    func generateSquaredQuad() -> [QuadVertex] {
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

    func generateCalligraphicQuad(vFactor: CGFloat, hFactor: CGFloat) -> [QuadVertex] {
        let vHalfSize = size * vFactor * 0.5
        let hHalfSize = size * hFactor * 0.5
        return [
            QuadVertex(x: origin.x - hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
    }

    func generateTrapezoidQuad(topFactor: CGFloat, bottomFactor: CGFloat, heightFactor: CGFloat) -> [QuadVertex] {
        let vHalfSize = size * heightFactor * 0.5
        let hTopHalfSize = size * topFactor * 0.5
        let hBottomHalfSize = size * bottomFactor * 0.5
        return [
            QuadVertex(x: origin.x - hTopHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hBottomHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hTopHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hBottomHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hTopHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hBottomHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
    }
}

enum QuadShape: Codable {
    case rounded
    case squared
    case calligraphic(CGFloat, CGFloat)
    case trapezoid(topFactor: CGFloat, bottomFactor: CGFloat, heightFactor: CGFloat)
}
