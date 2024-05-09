//
//  Stroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import CoreData
import Foundation

@objc(Stroke)
final class Stroke: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var color: [CGFloat]
    @NSManaged var style: Int16
    @NSManaged var createdAt: Date
    @NSManaged var thickness: CGFloat
    @NSManaged var strokeQuads: Array<StrokeQuad>
    @NSManaged var graphicContext: GraphicContext?

    var angle: CGFloat = 0

    var penStyle: Style {
        Style(rawValue: style) ?? .marker
    }

    var quadIndex: Int = -1
    var vertexIndex: Int = -1
    var keyPoints: [CGPoint] = []
    var thicknessFactor: CGFloat = 0.7

    var vertices: [QuadVertex] = []
    var _quads: [Quad] = []
    var vertexBuffer: MTLBuffer?
    var vertexCount: Int = 0

    var texture: MTLTexture?

    var isEmpty: Bool {
        vertices.isEmpty
    }

    var isEraserPenStyle: Bool {
        penStyle == .eraser
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

    func loadVertices() {
        vertices = strokeQuads
            .flatMap { $0.quad.generateVertices() }
        vertexCount = vertices.endIndex
    }

    func saveQuads() {
        strokeQuads = _quads.map(StrokeQuad.init)
        _quads.removeAll()
    }
}

extension Stroke: Drawable {
    func prepare(device: MTLDevice) {
        if texture == nil {
            texture = penStyle.anyPenStyle.loadTexture(on: device)
        }
        vertexBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<QuadVertex>.stride * vertexCount, options: .cpuCacheModeWriteCombined)
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmpty else { return }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
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
