//
//  GraphicContext.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import MetalKit
import CoreData
import Foundation

final class GraphicContext: @unchecked Sendable {
    var strokes: [Stroke] = []
    var object: GraphicContextObject?

    var currentStroke: Stroke?
    var previousStroke: Stroke?
    var currentPoint: CGPoint?
    var renderType: RenderType = .finished
    var vertices: [ViewPortVertex] = []
    var vertexCount: Int = 4
    var vertexBuffer: MTLBuffer?

    init() {
        setViewPortVertices()
    }

    func setViewPortVertices() {
        vertexBuffer = nil
        vertices = [
            ViewPortVertex(x: -1, y: -1, textCoord: CGPoint(x: 0, y: 1)),
            ViewPortVertex(x: -1, y: 1, textCoord: CGPoint(x: 0, y: 0)),
            ViewPortVertex(x: 1, y: -1, textCoord: CGPoint(x: 1, y: 1)),
            ViewPortVertex(x: 1, y: 1, textCoord: CGPoint(x: 1, y: 0)),
        ]
    }

    func undoGraphic() {
        guard !strokes.isEmpty else { return }
        let stroke = strokes.removeLast()
        withPersistence(\.backgroundContext) { [stroke] context in
            stroke.object?.graphicContext = nil
            try context.saveIfNeeded()
        }
        previousStroke = nil
    }

    func redoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            strokes.append(stroke)
            withPersistence(\.backgroundContext) { [weak self, stroke] context in
                stroke.object?.graphicContext = self?.object
                try context.saveIfNeeded()
            }
            previousStroke = nil
        }
    }
}

extension GraphicContext {
    func loadStrokes(_ bounds: CGRect) {
        guard let object else { return }
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        self.strokes = object.strokes.compactMap { stroke -> Stroke? in
            guard let stroke = stroke as? StrokeObject else { return nil }
            let _stroke = Stroke(object: stroke)
            if _stroke.isVisible(in: bounds) {
                let id = stroke.objectID
                queue.addOperation {
                    withPersistenceSync(\.newBackgroundContext) { [_stroke] context in
                        guard let stroke = try? context.existingObject(with: id) as? StrokeObject else { return }
                        _stroke.loadQuads(from: stroke)
                    }
                    withPersistence(\.backgroundContext) { [stroke] context in
                        context.refresh(stroke, mergeChanges: false)
                    }
                }
            } else {
                withPersistence(\.backgroundContext) { [stroke] context in
                    _stroke.loadQuads()
                    context.refresh(stroke, mergeChanges: false)
                }
            }
            return _stroke
        }
        queue.waitUntilAllOperationsAreFinished()
    }

    func loadQuads(_ bounds: CGRect) {
        for stroke in self.strokes {
            guard stroke.isVisible(in: bounds), stroke.quads.isEmpty else { continue }
            stroke.loadQuads()
        }
    }
}

extension GraphicContext: Drawable {
    func prepare(device: MTLDevice) {
        guard vertexBuffer == nil else {
            return
        }
        vertexCount = vertices.count
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<ViewPortVertex>.stride, options: [])
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        prepare(device: device)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
    }
}

extension GraphicContext {
    func beginStroke(at point: CGPoint, pen: Pen) -> Stroke {
        let stroke = Stroke(
            bounds: [point.x - pen.thickness, point.y - pen.thickness, point.x + pen.thickness, point.y + pen.thickness],
            color: pen.rgba,
            style: pen.strokeStyle.rawValue,
            createdAt: .now,
            thickness: pen.thickness
        )
        withPersistence(\.backgroundContext) { [graphicContext = object, _stroke = stroke] context in
            let stroke = StrokeObject(\.backgroundContext)
            stroke.bounds = _stroke.bounds
            stroke.color = _stroke.color
            stroke.style = _stroke.style
            stroke.thickness = _stroke.thickness
            stroke.createdAt = _stroke.createdAt
            stroke.quads = []
            stroke.graphicContext = graphicContext
            graphicContext?.strokes.add(stroke)
            _stroke.object = stroke
        }
        strokes.append(stroke)
        currentStroke = stroke
        currentPoint = point
        currentStroke?.begin(at: point)
        return stroke
    }

    func appendStroke(with point: CGPoint) {
        guard let currentStroke else { return }
        guard let currentPoint, point.distance(to: currentPoint) > currentStroke.thickness * currentStroke.penStyle.anyPenStyle.stepRate else {
            return
        }
        currentStroke.append(to: point)
        self.currentPoint = point
    }

    func endStroke(at point: CGPoint) {
        guard currentPoint != nil, let currentStroke else { return }
        currentStroke.finish(at: point)
        let batchIndex = currentStroke.batchIndex
        let quads = Array(currentStroke.quads[batchIndex..<currentStroke.quads.count])
        currentStroke.saveQuads(for: quads)
        withPersistence(\.backgroundContext) { context in
            try context.saveIfNeeded()
            if let stroke = currentStroke.object {
                context.refresh(stroke, mergeChanges: false)
            }
        }
        previousStroke = currentStroke
        self.currentStroke = nil
        self.currentPoint = nil
    }

    func cancelStroke() {
        if !strokes.isEmpty {
            let stroke = strokes.removeLast()
            withPersistence(\.backgroundContext) { [graphicContext = object, _stroke = stroke] context in
                if let stroke = _stroke.object {
                    graphicContext?.strokes.remove(stroke)
                    context.delete(stroke)
                }
                try context.saveIfNeeded()
            }
        }
        currentStroke = nil
        currentPoint = nil
    }
}

extension GraphicContext {
    enum RenderType {
        case inProgress
        case newlyFinished
        case finished
    }
}
