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
    var eraserStrokes: Set<EraserStroke> = []
    var object: GraphicContextObject?
    
    var currentStroke: (any Stroke)?
    var previousStroke: (any Stroke)?

    var currentPoint: CGPoint?
    var renderType: RenderType = .finished
    var vertices: [ViewPortVertex] = []
    var vertexCount: Int = 4
    var vertexBuffer: MTLBuffer?

    var erasers: [URL: EraserStroke] = [:]

    let barrierQueue = DispatchQueue(label: "com.memola.app.graphic-context", attributes: .concurrent)

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
            switch stroke.style {
            case .marker:
                guard let penStroke = stroke.stroke(as: PenStroke.self) else { return }
                let deletedStroke = tree.remove(penStroke.anyStroke, in: penStroke.strokeBox)
                withPersistence(\.backgroundContext) { [stroke = deletedStroke] context in
                    stroke?.stroke(as: PenStroke.self)?.object?.graphicContext = nil
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            case .eraser:
                guard let eraserStroke = stroke.stroke(as: EraserStroke.self) else { return }
                eraserStrokes.remove(eraserStroke)
                let penStrokes = eraserStroke.penStrokes
                withPersistence(\.backgroundContext) { [penStrokes] context in
                    for penStroke in penStrokes {
                        penStroke.eraserStrokes.remove(eraserStroke)
                        if let object = eraserStroke.object {
                            penStroke.object?.erasers.remove(object)
                        }
                    }
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            }
            previousStroke = nil
        }
    }

    func redoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            switch stroke.style {
            case .marker:
                guard let penStroke = stroke.stroke(as: PenStroke.self) else {
                    break
                }
                tree.insert(penStroke.anyStroke, in: penStroke.strokeBox)
                withPersistence(\.backgroundContext) { [weak self, penStroke] context in
                    penStroke.object?.graphicContext = self?.object
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            case .eraser:
                guard let eraserStroke = stroke.stroke(as: EraserStroke.self) else {
                    break
                }
                eraserStrokes.insert(eraserStroke)
                let penStrokes = eraserStroke.penStrokes
                withPersistence(\.backgroundContext) { [eraserStroke, penStrokes] context in
                    for penStroke in penStrokes {
                        penStroke.eraserStrokes.insert(eraserStroke)
                        if let object = eraserStroke.object {
                            penStroke.object?.erasers.add(object)
                        }
                    }
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
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
            guard let stroke = stroke as? StrokeObject, stroke.style == 0 else { return }
            let _stroke = PenStroke(object: stroke)
            tree.insert(_stroke.anyStroke, in: _stroke.strokeBox)
            if _stroke.isVisible(in: bounds) {
                let id = stroke.objectID
                queue.addOperation { [weak self] in
                    guard let self else { return }
                    withPersistenceSync(\.newBackgroundContext) { [_stroke] context in
                        guard let stroke = try? context.existingObject(with: id) as? StrokeObject else { return }
                        _stroke.loadQuads(from: stroke, with: self)
                        context.refreshAllObjects()
                    }
                }
            } else {
                withPersistence(\.backgroundContext) { [weak self] context in
                    guard let self else { return }
                    _stroke.loadQuads(with: self)
                    context.refreshAllObjects()
                }
            }
        }
        queue.waitUntilAllOperationsAreFinished()
    }

    func loadQuads(_ bounds: CGRect, on context: NSManagedObjectContext) {
        for _stroke in self.tree.search(box: bounds.box) {
            guard let stroke = _stroke.stroke(as: PenStroke.self), stroke.isEmpty else { continue }
            stroke.loadQuads(with: self)
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
        let stroke: any Stroke
        switch pen.strokeStyle {
        case .marker:
            let penStroke = PenStroke(
                bounds: [point.x - pen.thickness, point.y - pen.thickness, point.x + pen.thickness, point.y + pen.thickness],
                color: pen.rgba,
                style: pen.strokeStyle,
                createdAt: .now,
                thickness: pen.thickness
            )
            withPersistence(\.backgroundContext) { [graphicContext = object, _stroke = penStroke] context in
                let stroke = StrokeObject(\.backgroundContext)
                stroke.bounds = _stroke.bounds
                stroke.color = _stroke.color
                stroke.style = _stroke.style.rawValue
                stroke.thickness = _stroke.thickness
                stroke.createdAt = _stroke.createdAt
                stroke.quads = []
                stroke.erasers = .init()
                stroke.graphicContext = graphicContext
                graphicContext?.strokes.add(stroke)
                _stroke.object = stroke
                try context.saveIfNeeded()
            }
            stroke = penStroke
        case .eraser:
            let eraserStroke = EraserStroke(
                bounds: [point.x - pen.thickness, point.y - pen.thickness, point.x + pen.thickness, point.y + pen.thickness],
                color: pen.rgba,
                style: pen.strokeStyle,
                createdAt: .now,
                thickness: pen.thickness
            )
            eraserStroke.graphicContext = self
            withPersistence(\.backgroundContext) { [_stroke = eraserStroke] context in
                let stroke = EraserObject(\.backgroundContext)
                stroke.bounds = _stroke.bounds
                stroke.color = _stroke.color
                stroke.style = _stroke.style.rawValue
                stroke.thickness = _stroke.thickness
                stroke.createdAt = _stroke.createdAt
                stroke.quads = []
                stroke.strokes = .init()
                _stroke.object = stroke
                try context.saveIfNeeded()
            }
            stroke = eraserStroke
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
        guard currentPoint != nil, let currentStroke = currentStroke else { return }
        currentStroke.finish(at: point)
        if let penStroke = currentStroke.stroke(as: PenStroke.self) {
            penStroke.saveQuads()
            tree.insert(currentStroke.anyStroke, in: currentStroke.strokeBox)
            withPersistence(\.backgroundContext) { [penStroke] context in
                penStroke.object?.bounds = penStroke.bounds
                try context.saveIfNeeded()
                context.refreshAllObjects()
            }
        } else if let eraserStroke = currentStroke.stroke(as: EraserStroke.self) {
            eraserStroke.saveQuads()
            eraserStrokes.insert(eraserStroke)
            withPersistence(\.backgroundContext) { [eraserStroke] context in
                eraserStroke.object?.bounds = eraserStroke.bounds
                try context.saveIfNeeded()
                context.refreshAllObjects()
            }
        }
        previousStroke = currentStroke
        self.currentStroke = nil
        self.currentPoint = nil
    }

    func cancelStroke() {
        if let stroke = currentStroke {
            switch stroke.style {
            case .marker:
                guard let _stroke = stroke.stroke(as: PenStroke.self) else { break }
                withPersistence(\.backgroundContext) { [graphicContext = object, _stroke] context in
                    if let stroke = _stroke.object {
                        graphicContext?.strokes.remove(stroke)
                        context.delete(stroke)
                    }
                    try context.saveIfNeeded()
                }
            case .eraser:
                guard let eraserStroke = stroke.stroke(as: EraserStroke.self) else { break }
                eraserStrokes.remove(eraserStroke)
                withPersistence(\.backgroundContext) { [eraserStroke] context in
                    if let stroke = eraserStroke.object {
                        context.delete(stroke)
                    }
                    try context.saveIfNeeded()
                }
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
