//
//  PenStroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import CoreData
import Foundation

final class PenStroke: Stroke, @unchecked Sendable {
    var id: UUID = UUID()
    var bounds: [CGFloat]
    var color: [CGFloat]
    var style: StrokeStyle
    var createdAt: Date
    var thickness: CGFloat
    var quads: [Quad]
    var penStyle: any PenStyle

    var keyPoints: [CGPoint] = []
    var movingAverage: MovingAverage = MovingAverage(windowSize: 3)

    var texture: (any MTLTexture)?
    var indexBuffer: (any MTLBuffer)?
    var vertexBuffer: (any MTLBuffer)?

    var object: StrokeObject?

    init(
        bounds: [CGFloat],
        color: [CGFloat],
        style: StrokeStyle,
        createdAt: Date,
        thickness: CGFloat,
        quads: [Quad] = []
    ) {
        self.bounds = bounds
        self.color = color
        self.style = style
        self.createdAt = createdAt
        self.thickness = thickness
        self.quads = quads
        self.penStyle = style.penStyle
    }

    convenience init(object: StrokeObject) {
        let style = StrokeStyle(rawValue: object.style) ?? .marker
        self.init(
            bounds: object.bounds,
            color: object.color,
            style: style,
            createdAt: object.createdAt,
            thickness: object.thickness
        )
        self.object = object
    }

    func loadQuads() {
        guard let object else { return }
        loadQuads(from: object)
    }

    func loadQuads(from object: StrokeObject) {
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
    }

    func addQuad(at point: CGPoint, rotation: CGFloat, shape: QuadShape) {
        let quad = Quad(
            origin: point,
            size: thickness,
            rotation: rotation,
            shape: shape.rawValue,
            color: color
        )
        quads.append(quad)
        bounds = [
            min(quad.originX.cgFloat, bounds[0]),
            min(quad.originY.cgFloat, bounds[1]),
            max(quad.originX.cgFloat, bounds[2]),
            max(quad.originY.cgFloat, bounds[3])
        ]
        withPersistence(\.backgroundContext) { [object, _quad = quad] context in
            let quad = QuadObject(\.backgroundContext)
            quad.originX = _quad.originX.cgFloat
            quad.originY = _quad.originY.cgFloat
            quad.size = _quad.size.cgFloat
            quad.rotation = _quad.rotation.cgFloat
            quad.shape = _quad.shape
            quad.color = _quad.getColor()
            quad.stroke = object
            object?.quads.add(quad)
        }
    }
}
