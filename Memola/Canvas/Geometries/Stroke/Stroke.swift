//
//  Stroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import CoreData
import Foundation

final class Stroke: @unchecked Sendable {
    var object: StrokeObject?
    var bounds: [CGFloat]
    var color: [CGFloat]
    var style: Int16
    var createdAt: Date
    var thickness: CGFloat
    var quads: [Quad]

    init(object: StrokeObject) {
        self.object = object
        self.bounds = object.bounds
        self.color = object.color
        self.style = object.style
        self.createdAt = object.createdAt
        self.thickness = object.thickness
        self.quads = []
    }

    init(
        bounds: [CGFloat],
        color: [CGFloat],
        style: Int16,
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
    }

    var angle: CGFloat = 0
    var penStyle: Style {
        Style(rawValue: style) ?? .marker
    }

    var batchIndex: Int = 0
    var quadIndex: Int = -1
    var keyPoints: [CGPoint] = []
    var thicknessFactor: CGFloat = 0.7

    let movingAverage = MovingAverage(windowSize: 3)

    var vertexBuffer: MTLBuffer?
    var texture: MTLTexture?

    var isEmpty: Bool {
        quads.isEmpty
    }
    var isEraserPenStyle: Bool {
        penStyle == .eraser
    }
    var strokeBounds: CGRect {
        let x = bounds[0]
        let y = bounds[1]
        let width = bounds[2] - x
        let height = bounds[3] - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func isVisible(in bounds: CGRect) -> Bool {
        bounds.contains(strokeBounds) || bounds.intersects(strokeBounds)
    }

    func begin(at point: CGPoint) {
        penStyle.anyPenStyle.generator.begin(at: point, on: self)
    }

    func append(to point: CGPoint) {
        penStyle.anyPenStyle.generator.append(to: point, on: self)
    }

    func finish(at point: CGPoint) {
        penStyle.anyPenStyle.generator.finish(at: point, on: self)
        keyPoints.removeAll()
    }
}

extension Stroke {
    func loadQuads() {
        guard let object else { return }
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
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
        withPersistence(\.backgroundContext) { [weak self, _quad = quad, object, bounds] context in
            let quad = QuadObject(\.backgroundContext)
            quad.originX = _quad.originX.cgFloat
            quad.originY = _quad.originY.cgFloat
            quad.size = _quad.size.cgFloat
            quad.rotation = _quad.rotation.cgFloat
            quad.shape = _quad.shape
            quad.color = _quad.getColor()
            quad.stroke = object
            object?.quads.add(quad)
            self?.bounds[0] = min(_quad.originX.cgFloat, bounds[0])
            self?.bounds[1] = min(_quad.originY.cgFloat, bounds[1])
            self?.bounds[2] = max(_quad.originX.cgFloat, bounds[2])
            self?.bounds[3] = max(_quad.originY.cgFloat, bounds[3])
        }
    }
}

extension Stroke: Drawable {
    func prepare(device: MTLDevice) {
        if texture == nil {
            texture = penStyle.anyPenStyle.loadTexture(on: device)
        }
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmpty else { return }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: quads.endIndex * 6)
        vertexBuffer = nil
    }
}

extension Stroke {
    enum Style: Int16 {
        case marker
        case eraser

        var anyPenStyle: any PenStyle {
            switch self {
            case .marker:
                return MarkerPenStyle.marker
            case .eraser:
                return EraserPenStyle.eraser
            }
        }
    }
}
