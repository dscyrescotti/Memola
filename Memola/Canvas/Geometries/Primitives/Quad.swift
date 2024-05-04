//
//  Quad.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class Quad {
    var origin: CGPoint
    var color: [CGFloat]
    var size: CGFloat
    var rotation: CGFloat
    var vertices: [QuadVertex] = []

    var vertexBuffer: MTLBuffer?
    var vertexCount: Int = 0

    init(origin: CGPoint, size: CGFloat, color: [CGFloat], rotation: CGFloat, shape: Shape = .rounded) {
        self.origin = origin
        self.size = size
        self.color = color
        self.rotation = rotation
        generateVertices(shape)
    }

    func generateVertices(_ shape: Shape) {
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

    func generateRoundedQuad() {
        let halfSize = size * 0.5
        vertices = [
            QuadVertex(x: origin.x - halfSize, y: origin.y - halfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + halfSize, y: origin.y - halfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - halfSize, y: origin.y + halfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + halfSize, y: origin.y - halfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - halfSize, y: origin.y + halfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + halfSize, y: origin.y + halfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
        vertexCount = vertices.count
    }

    func generateSquaredQuad() {
        let vHalfSize = size * 0.5
        let hHalfSize = size * 0.15
        vertices = [
            QuadVertex(x: origin.x - hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
        vertexCount = vertices.count
    }

    func generateCalligraphicQuad(vFactor: CGFloat, hFactor: CGFloat) {
        let vHalfSize = size * vFactor * 0.5
        let hHalfSize = size * hFactor * 0.5
        vertices = [
            QuadVertex(x: origin.x - hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
        vertexCount = vertices.count
    }

    func generateTrapezoidQuad(topFactor: CGFloat, bottomFactor: CGFloat, heightFactor: CGFloat) {
        let vHalfSize = size * heightFactor * 0.5
        let hTopHalfSize = size * topFactor * 0.5
        let hBottomHalfSize = size * bottomFactor * 0.5
        vertices = [
            QuadVertex(x: origin.x - hTopHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 0, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hBottomHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hTopHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hBottomHalfSize, y: origin.y - vHalfSize, textCoord: CGPoint(x: 1, y: 0), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x - hTopHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 0, y: 1), color: color, origin: origin, rotation: rotation),
            QuadVertex(x: origin.x + hBottomHalfSize, y: origin.y + vHalfSize, textCoord: CGPoint(x: 1, y: 1), color: color, origin: origin, rotation: rotation)
        ]
        vertexCount = vertices.count
    }
}

extension Quad {
    enum Shape {
        case rounded
        case squared
        case calligraphic(CGFloat, CGFloat)
        case trapezoid(topFactor: CGFloat, bottomFactor: CGFloat, heightFactor: CGFloat)
    }
}
