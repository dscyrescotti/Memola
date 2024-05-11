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
        Persistence.backgroundContext.perform {
            stroke.object?.graphicContext = nil
            Persistence.saveIfNeededInBackground()
        }
        previousStroke = nil
    }

    func redoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            strokes.append(stroke)
            Persistence.backgroundContext.perform { [weak self] in
                stroke.object?.graphicContext = self?.object
                Persistence.saveIfNeededInBackground()
            }
            previousStroke = nil
        }
    }
}

extension GraphicContext {
    func load() {
        guard let object else { return }
        self.strokes = object.strokes.compactMap { stroke -> Stroke? in
            guard let stroke = stroke as? StrokeObject else { return nil }
            let _stroke = Stroke(object: stroke)
            _stroke.loadVertices()
            return _stroke
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
            color: pen.color,
            style: pen.strokeStyle.rawValue,
            createdAt: .now,
            thickness: pen.thickness
        )
        Persistence.backgroundContext.perform { [graphicContext = object, _stroke = stroke] in
            let stroke = StrokeObject(context: Persistence.backgroundContext)
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
        guard let currentPoint, point.distance(to: currentPoint) > currentStroke.thickness * currentStroke.penStyle.anyPenStyle.stepRate else { return }
        currentStroke.append(to: point)
        self.currentPoint = point
    }

    func endStroke(at point: CGPoint) {
        guard currentPoint != nil, let currentStroke else { return }
        currentStroke.finish(at: point)
        let saveIndex = currentStroke.batchIndex
        let quads = Array(currentStroke.quads[saveIndex..<currentStroke.quads.count])
        Persistence.backgroundContext.perform { [currentStroke, quads] in
            currentStroke.saveQuads(for: quads)
            Persistence.saveIfNeededInBackground()
            if let stroke = currentStroke.object {
                currentStroke.quads.removeAll()
                Persistence.backgroundContext.refresh(stroke, mergeChanges: false)
            }
        }
        previousStroke = currentStroke
        self.currentStroke = nil
        self.currentPoint = nil
    }

    func cancelStroke() {
        if !strokes.isEmpty {
            let stroke = strokes.removeLast()
            Persistence.backgroundContext.perform { [graphicContext = object, _stroke = stroke] in
                if let stroke = _stroke.object {
                    graphicContext?.strokes.remove(stroke)
                    Persistence.backgroundContext.delete(stroke)
                }
                Persistence.saveIfNeededInBackground()
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
