//
//  EraserStroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/24/24.
//

import CoreData
import MetalKit
import Foundation

final class EraserStroke: Stroke, @unchecked Sendable {
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

    let batchSize: Int = 50
    var batchIndex: Int = 0

    var object: EraserObject?

    weak var graphicContext: GraphicContext?

    var finishesSaving: Bool = false
    var penStrokes: Set<PenStroke> = []

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

    convenience init(object: EraserObject) {
        let style = StrokeStyle(rawValue: object.style) ?? .marker
        self.init(
            bounds: object.bounds,
            color: object.color,
            style: style,
            createdAt: object.createdAt ?? .now,
            thickness: object.thickness
        )
        self.object = object
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

    func loadQuads(from object: EraserObject) {
        quads = object.quads.compactMap { quad in
            guard let quad = quad as? QuadObject else { return nil }
            return Quad(object: quad)
        }
    }

    func saveQuads(to endIndex: Int? = nil) {
        let isEnded: Bool = endIndex == nil
        guard let graphicContext else { return }
        let endIndex = endIndex ?? quads.endIndex
        let batch = quads[batchIndex..<endIndex]
        batchIndex = endIndex
        withPersistence(\.backgroundContext) { [weak self, eraser = object, quads = batch] context in
            guard let self, let eraser else { return }
            for _quad in quads {
                let quad = QuadObject(\.backgroundContext)
                quad.originX = _quad.originX.cgFloat
                quad.originY = _quad.originY.cgFloat
                quad.size = _quad.size.cgFloat
                quad.rotation = _quad.rotation.cgFloat
                quad.shape = _quad.shape
                quad.color = _quad.getColor()
                quad.eraser = eraser
                for stroke in graphicContext.tree.search(box: _quad.quadBox) {
                    if let _penStroke = stroke.stroke(as: PenStroke.self), !_penStroke.eraserStrokes.contains(self) {
                        _penStroke.eraserStrokes.insert(self)
                        penStrokes.insert(_penStroke)
                        if let penStroke = _penStroke.object {
                            penStroke.erasers.add(eraser)
                            eraser.strokes.add(penStroke)
                        }
                    }
                }
            }
            if isEnded {
                finishesSaving = true
            }
        }
    }
}
