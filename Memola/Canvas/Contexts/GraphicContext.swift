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

@objc(GraphicContext)
class GraphicContext: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var canvas: Canvas?
    @NSManaged var strokes: NSMutableOrderedSet

    var currentStroke: Stroke?
    var previousStroke: Stroke?
    var currentPoint: CGPoint?
    var renderType: RenderType = .finished
    var vertices: [ViewPortVertex] = []
    var vertexCount: Int = 4
    var vertexBuffer: MTLBuffer?

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
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
        guard let stroke = strokes.lastObject as? Stroke else { return }
        strokes.remove(stroke)
        stroke.graphicContext = nil
        previousStroke = nil
        do {
            try Persistence.shared.viewContext.save()
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
        }
    }

    func redoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            strokes.add(stroke)
            stroke.graphicContext = self
            previousStroke = nil
        }
        do {
            try Persistence.shared.viewContext.save()
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
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
        let stroke = Stroke(context: Persistence.shared.viewContext)
        stroke.id = UUID()
        stroke.color = pen.color
        stroke.style = pen.strokeStyle.rawValue
        stroke.thickness = pen.thickness
        stroke.createdAt = .now
        stroke.strokeQuads = []
        stroke.graphicContext = self
        strokes.add(stroke)
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
        currentStroke.saveQuads()
        do {
            try Persistence.shared.viewContext.save()
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
        }
        previousStroke = currentStroke
        self.currentStroke = nil
        self.currentPoint = nil
    }

    func cancelStroke() {
        if let stroke = strokes.lastObject as? Stroke {
            do {
                let viewContext = Persistence.shared.viewContext
                strokes.remove(stroke)
                viewContext.delete(stroke)
                try viewContext.save()
            } catch {
                NSLog("[Memola] - \(error.localizedDescription)")
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
