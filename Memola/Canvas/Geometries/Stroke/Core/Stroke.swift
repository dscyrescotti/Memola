//
//  Stroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/24/24.
//

import MetalKit
import Foundation

protocol Stroke: AnyObject, Drawable, Hashable, Equatable {
    var id: UUID { get set }
    var bounds: [CGFloat] { get set }
    var color: [CGFloat] { get set }
    var style: StrokeStyle { get set }
    var createdAt: Date { get set }
    var thickness: CGFloat { get set }
    var quads: [Quad] { get set }
    var penStyle: any PenStyle { get set }

    var batchIndex: Int { get set }
    var quadIndex: Int { get set }
    var keyPoints: [CGPoint] { get set }
    var movingAverage: MovingAverage { get set }

    var texture: MTLTexture? { get set }
    var indexBuffer: MTLBuffer? { get set }
    var vertexBuffer: MTLBuffer? { get set }

    func begin(at point: CGPoint)
    func append(to point: CGPoint)
    func finish(at point: CGPoint)

    func addQuad(at point: CGPoint, rotation: CGFloat, shape: QuadShape)
    func removeQuads(from index: Int)
    func saveQuads(to index: Int)
}

extension Stroke {
    var isEmpty: Bool { quads.isEmpty }

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
}

extension Stroke {
    func begin(at point: CGPoint) {
        penStyle.generator.begin(at: point, on: self)
    }

    func append(to point: CGPoint) {
        penStyle.generator.append(to: point, on: self)
    }

    func finish(at point: CGPoint) {
        penStyle.generator.finish(at: point, on: self)
        keyPoints.removeAll()
    }
}

extension Stroke {
    func addQuad(at point: CGPoint, rotation: CGFloat, shape: QuadShape) {
        let quad = Quad(
            origin: point,
            size: thickness,
            rotation: rotation,
            shape: shape.rawValue,
            color: color
        )
        quads.append(quad)
    }

    func removeQuads(from index: Int) {
        let dropCount = quads.endIndex - max(1, index)
        quads.removeLast(dropCount)
    }
}

extension Stroke {
    func prepare(device: MTLDevice) {
        guard texture == nil else { return }
        texture = penStyle.loadTexture(on: device)
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmpty, let indexBuffer else { return }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: quads.endIndex * 6,
            indexType: .uint32,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
        self.vertexBuffer = nil
        self.indexBuffer = nil
    }
}

extension Stroke {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
