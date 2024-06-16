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
    var tree: RTree = RTree<Element>(maxEntries: 8)
    var eraserStrokes: Set<EraserStroke> = []
    var object: GraphicContextObject?
    
    var currentElement: Element?
    var previousElement: Element?

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
                tree.remove(penStroke.element, in: penStroke.strokeBox)
                withPersistence(\.backgroundContext) { [weak penStroke] context in
                    penStroke?.object?.element?.graphicContext = nil
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            case .eraser:
                guard let eraserStroke = stroke.stroke(as: EraserStroke.self) else { return }
                eraserStrokes.remove(eraserStroke)
                withPersistence(\.backgroundContext) { [weak eraserStroke] context in
                    guard let eraserStroke else { return }
                    for penStroke in eraserStroke.penStrokes.allObjects {
                        penStroke.eraserStrokes.remove(eraserStroke)
                        if let object = eraserStroke.object {
                            penStroke.object?.erasers.remove(object)
                        }
                    }
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            }
            previousElement = nil
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
                tree.insert(penStroke.element, in: penStroke.strokeBox)
                withPersistence(\.backgroundContext) { [weak self, weak penStroke] context in
                    penStroke?.object?.element?.graphicContext = self?.object
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            case .eraser:
                guard let eraserStroke = stroke.stroke(as: EraserStroke.self) else {
                    break
                }
                eraserStrokes.insert(eraserStroke)
                withPersistence(\.backgroundContext) { [weak eraserStroke] context in
                    guard let eraserStroke else { return }
                    for penStroke in eraserStroke.penStrokes.allObjects {
                        penStroke.eraserStrokes.insert(eraserStroke)
                        if let object = eraserStroke.object {
                            penStroke.object?.erasers.add(object)
                        }
                    }
                    try context.saveIfNeeded()
                    context.refreshAllObjects()
                }
            }
            previousElement = nil
        }
    }
}

extension GraphicContext {
    func loadStrokes(_ bounds: CGRect) {
        guard let object else { return }
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        object.elements.forEach { element in
            guard let element = element as? ElementObject else { return }
            switch element.type {
            case 0:
                guard let stroke = element.stroke, stroke.style == 0 else { return }
                let _stroke = PenStroke(object: stroke)
                tree.insert(_stroke.element, in: _stroke.strokeBox)
                if _stroke.isVisible(in: bounds) {
                    let id = stroke.objectID
                    queue.addOperation { [weak self] in
                        guard let self else { return }
                        withPersistenceSync(\.newBackgroundContext) { [weak _stroke] context in
                            guard let stroke = try? context.existingObject(with: id) as? StrokeObject else { return }
                            _stroke?.loadQuads(from: stroke, with: self)
                            context.refreshAllObjects()
                        }
                    }
                } else {
                    withPersistence(\.backgroundContext) { [weak self, weak _stroke] context in
                        guard let self else { return }
                        _stroke?.loadQuads(with: self)
                        context.refreshAllObjects()
                    }
                }
            case 1:
                guard let photo = element.photo, photo.imageURL != nil else { return }
                let _photo = Photo(object: photo)
                tree.insert(_photo.element, in: _photo.photoBox)
            default:
                break
            }

        }
        queue.waitUntilAllOperationsAreFinished()
    }

    func loadQuads(_ bounds: CGRect, on context: NSManagedObjectContext) {
        for element in self.tree.search(box: bounds.box) {
            guard let stroke = element.stroke(as: PenStroke.self), stroke.isEmpty else { continue }
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

// MARK: - Stroke
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
            withPersistence(\.backgroundContext) { [weak graphicContext = object, weak _stroke = penStroke] context in
                guard let _stroke else { return }
                let stroke = StrokeObject(\.backgroundContext)
                stroke.bounds = _stroke.bounds
                stroke.color = _stroke.color
                stroke.style = _stroke.style.rawValue
                stroke.thickness = _stroke.thickness
                stroke.createdAt = _stroke.createdAt
                stroke.quads = []
                stroke.erasers = .init()
                let element = ElementObject(\.backgroundContext)
                element.createdAt = _stroke.createdAt
                element.type = 0
                element.graphicContext = graphicContext
                stroke.element = element
                element.stroke = stroke
                graphicContext?.elements.add(element)
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
            withPersistence(\.backgroundContext) { [weak _stroke = eraserStroke] context in
                guard let _stroke else { return }
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
        currentElement = .stroke(stroke.anyStroke)
        currentPoint = point
        currentElement?.stroke()?.begin(at: point)
        return stroke
    }

    func appendStroke(with point: CGPoint) {
        guard let currentStroke = currentElement?.stroke() else { return }
        guard let currentPoint, point.distance(to: currentPoint) > currentStroke.thickness * currentStroke.penStyle.stepRate else {
            return
        }
        currentStroke.append(to: point)
        self.currentPoint = point
    }

    func endStroke(at point: CGPoint) {
        guard currentPoint != nil, let currentStroke = currentElement?.stroke() else { return }
        currentStroke.finish(at: point)
        if let penStroke = currentStroke.stroke(as: PenStroke.self) {
            penStroke.saveQuads()
            tree.insert(currentStroke.element, in: currentStroke.strokeBox)
            withPersistence(\.backgroundContext) { [weak penStroke] context in
                guard let penStroke else { return }
                penStroke.object?.bounds = penStroke.bounds
                try context.saveIfNeeded()
                context.refreshAllObjects()
            }
        } else if let eraserStroke = currentStroke.stroke(as: EraserStroke.self) {
            eraserStroke.saveQuads()
            eraserStrokes.insert(eraserStroke)
            withPersistence(\.backgroundContext) { [weak eraserStroke] context in
                guard let eraserStroke else { return }
                eraserStroke.object?.bounds = eraserStroke.bounds
                try context.saveIfNeeded()
                context.refreshAllObjects()
            }
        }
        previousElement = currentElement
        self.currentElement = nil
        self.currentPoint = nil
    }

    func cancelStroke() {
        if let stroke = currentElement?.stroke() {
            switch stroke.style {
            case .marker:
                guard let _stroke = stroke.stroke(as: PenStroke.self) else { break }
                withPersistence(\.backgroundContext) { [weak graphicContext = object, weak _stroke] context in
                    guard let _stroke else { return }
                    if let element = _stroke.object?.element {
                        graphicContext?.elements.remove(element)
                    }
                    try context.saveIfNeeded()
                }
            case .eraser:
                guard let eraserStroke = stroke.stroke(as: EraserStroke.self) else { break }
                eraserStrokes.remove(eraserStroke)
                withPersistence(\.backgroundContext) { [weak eraserStroke] context in
                    if let stroke = eraserStroke?.object {
                        context.delete(stroke)
                    }
                    try context.saveIfNeeded()
                }
            }
        }
        currentElement = nil
        currentPoint = nil
    }
}

// MARK: - Photo
extension GraphicContext {
    func insertPhoto(at point: CGPoint, photoItem: PhotoItem) {
        let size = photoItem.dimension
        let origin = point
        let bounds = [origin.x - size.width / 2, origin.y - size.height / 2, origin.x + size.width / 2, origin.y + size.height / 2]
        let photo = Photo(url: photoItem.id, size: size, origin: origin, bounds: bounds, createdAt: .now, bookmark: photoItem.bookmark)
        tree.insert(photo.element, in: photo.photoBox)
        withPersistence(\.backgroundContext) { [_photo = photo, graphicContext = object] context in
            let photo = PhotoObject(\.backgroundContext)
            photo.imageURL = _photo.url
            photo.bounds = _photo.bounds
            photo.width = _photo.size.width
            photo.originY = _photo.origin.y
            photo.originX = _photo.origin.x
            photo.height = _photo.size.height
            photo.createdAt = _photo.createdAt
            photo.bookmark = _photo.bookmark
            let element = ElementObject(\.backgroundContext)
            element.createdAt = _photo.createdAt
            element.type = 1
            element.graphicContext = graphicContext
            photo.element = element
            element.photo = photo
            graphicContext?.elements.add(element)
            _photo.object = photo
            try context.saveIfNeeded()
        }
        self.previousElement = .photo(photo)
    }
}

extension GraphicContext {
    enum RenderType {
        case inProgress
        case newlyFinished
        case finished
    }
}
