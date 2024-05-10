//
//  Quad.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/8/24.
//

import CoreData
import Foundation

@objc(Quad)
class Quad: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var originX: CGFloat
    @NSManaged var originY: CGFloat
    @NSManaged var size: CGFloat
    @NSManaged var rotation: CGFloat
    @NSManaged var shape: Int16
    @NSManaged var stroke: Stroke?

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
