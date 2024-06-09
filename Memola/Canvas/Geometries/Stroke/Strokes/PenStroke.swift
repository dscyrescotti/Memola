//
//  PenStroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import CoreData
import MetalKit
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
    var erasedIndexBuffer: (any MTLBuffer)?
    var erasedVertexBuffer: (any MTLBuffer)?

    var object: StrokeObject?

    let batchSize: Int = 50
    var batchIndex: Int = 0
    var erasedQuadCount: Int = 0

    var eraserStrokes: Set<EraserStroke> = []

    var isEmptyErasedQuads: Bool {
        eraserStrokes.isEmpty
    }

    weak var graphicContext: GraphicContext?

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

    func loadQuads(with graphicContext: GraphicContext) {
        guard let object else { return }
        loadQuads(from: object, with: graphicContext)
    }

    func loadQuads(from object: StrokeObject, with graphicContext: GraphicContext) {
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
        let erasers = fetchErasers(of: object)
        eraserStrokes = Set(erasers.compactMap { [graphicContext] eraser -> EraserStroke? in
            let url = eraser.objectID.uriRepresentation()
            return graphicContext.barrierQueue.sync(flags: .barrier) {
                if graphicContext.erasers[url] == nil {
                    let _stroke = EraserStroke(object: eraser)
                    _stroke.loadQuads(from: eraser)
                    graphicContext.erasers[url] = _stroke
                    return _stroke
                }
                return graphicContext.erasers[url]
            }
        })
    }

    func fetchErasers(of stroke: StrokeObject) -> [EraserObject] {
        let fetchRequest: NSFetchRequest<EraserObject> = .init(entityName: "EraserObject")
        fetchRequest.predicate = NSPredicate(format: "ANY strokes == %@", stroke)

        do {
            let erasers = try Persistence.shared.backgroundContext.fetch(fetchRequest)
            return erasers
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
        }
        return []
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
        if quads.endIndex >= batchIndex + batchSize {
            saveQuads(to: batchIndex + batchSize)
        }
    }

    func saveQuads(to endIndex: Int? = nil) {
        let endIndex = endIndex ?? quads.endIndex
        let batch = quads[batchIndex..<endIndex]
        batchIndex = endIndex
        withPersistence(\.backgroundContext) { [object, quads = batch] context in
            for _quad in quads {
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

    func getAllErasedQuads() -> [Quad] {
        eraserStrokes.flatMap { $0.quads }
    }

    func erase(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmptyErasedQuads, let erasedIndexBuffer else {
            return
        }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(erasedVertexBuffer, offset: 0, index: 0)
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: erasedQuadCount * 6,
            indexType: .uint32,
            indexBuffer: erasedIndexBuffer,
            indexBufferOffset: 0
        )
        self.erasedIndexBuffer = nil
        self.erasedVertexBuffer = nil
    }
}
