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
    var tree: RTree = RTree<AnyStroke>(maxEntries: 8)
    var object: GraphicContextObject?
    
    var currentStroke: (any Stroke)?
    var previousStroke: (any Stroke)?

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

    func undoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            guard let _stroke = stroke.stroke(as: PenStroke.self) else { return }
            let deletedStroke = tree.remove(_stroke.anyStroke, in: _stroke.strokeBox)
            withPersistence(\.backgroundContext) { [stroke = deletedStroke] context in
                stroke?.stroke(as: PenStroke.self)?.object?.graphicContext = nil
                try context.saveIfNeeded()
            }
            previousStroke = nil
        }

    }

    func redoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            if let stroke = stroke.stroke(as: PenStroke.self) {
                tree.insert(stroke.anyStroke, in: stroke.strokeBox)
            }
            withPersistence(\.backgroundContext) { [weak self, stroke] context in
                stroke.stroke(as: PenStroke.self)?.object?.graphicContext = self?.object
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
        object.strokes.forEach { stroke in
            guard let stroke = stroke as? StrokeObject else { return }
            let _stroke = PenStroke(object: stroke)
            tree.insert(_stroke.anyStroke, in: _stroke.strokeBox)
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
        }
        queue.waitUntilAllOperationsAreFinished()
    }

    func loadQuads(_ bounds: CGRect) {
        for _stroke in self.tree.search(box: bounds.box) {
            guard let stroke = _stroke.stroke(as: PenStroke.self), stroke.isEmpty else { continue }
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
    func beginStroke(at point: CGPoint, pen: Pen) -> any Stroke {
        let stroke = PenStroke(
            bounds: [point.x - pen.thickness, point.y - pen.thickness, point.x + pen.thickness, point.y + pen.thickness],
            color: pen.rgba,
            style: pen.strokeStyle,
            createdAt: .now,
            thickness: pen.thickness
        )
        withPersistence(\.backgroundContext) { [graphicContext = object, _stroke = stroke] context in
            let stroke = StrokeObject(\.backgroundContext)
            stroke.bounds = _stroke.bounds
            stroke.color = _stroke.color
            stroke.style = _stroke.style.rawValue
            stroke.thickness = _stroke.thickness
            stroke.createdAt = _stroke.createdAt
            stroke.quads = []
            stroke.graphicContext = graphicContext
            graphicContext?.strokes.add(stroke)
            _stroke.object = stroke
        }
        currentStroke = stroke
        currentPoint = point
        currentStroke?.begin(at: point)
        return stroke
    }

    func appendStroke(with point: CGPoint) {
        guard let currentStroke else { return }
        guard let currentPoint, point.distance(to: currentPoint) > currentStroke.thickness * currentStroke.penStyle.stepRate else {
            return
        }
        currentStroke.append(to: point)
        self.currentPoint = point
    }

    func endStroke(at point: CGPoint) {
        guard currentPoint != nil, let currentStroke = currentStroke?.stroke(as: PenStroke.self) else { return }
        currentStroke.finish(at: point)
        tree.insert(currentStroke.anyStroke, in: currentStroke.strokeBox)
        currentStroke.saveQuads()
        withPersistence(\.backgroundContext) { [currentStroke] context in
            guard let stroke = currentStroke.stroke(as: PenStroke.self) else { return }
            stroke.object?.bounds = stroke.bounds
            try context.saveIfNeeded()
            if let object = stroke.object {
                context.refresh(object, mergeChanges: false)
            }
        }
        previousStroke = currentStroke
        self.currentStroke = nil
        self.currentPoint = nil
    }

    func cancelStroke() {
        if !tree.isEmpty, let stroke = currentStroke?.stroke(as: PenStroke.self) {
            let _stroke = tree.remove(stroke.anyStroke, in: stroke.strokeBox)
            withPersistence(\.backgroundContext) { [graphicContext = object, _stroke] context in
                if let stroke = _stroke?.stroke(as: PenStroke.self)?.object {
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
