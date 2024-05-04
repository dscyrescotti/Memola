//
//  GraphicContext.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import MetalKit
import Foundation

protocol GraphicContextDelegate: AnyObject {
    var didUpdate: PassthroughSubject<Void, Never> { get set }
}

class GraphicContext: Codable {
    var strokes: [Stroke] = []
    var currentStroke: Stroke?
    var previousStroke: Stroke?
    var currentPoint: CGPoint?

    var renderType: RenderType = .finished

    var vertices: [ViewPortVertex] = []
    var vertexCount: Int = 4
    var vertexBuffer: MTLBuffer?

    weak var delegate: GraphicContextDelegate?

    init() {
        setViewPortVertices()
    }

    enum CodingKeys: CodingKey {
        case strokes
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.strokes = try container.decode([Stroke].self, forKey: .strokes)
        setViewPortVertices()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.strokes, forKey: .strokes)
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
        strokes.removeLast()
        previousStroke = nil
        delegate?.didUpdate.send()
    }

    func redoGraphic(for event: HistoryEvent) {
        switch event {
        case .stroke(let stroke):
            strokes.append(stroke)
            previousStroke = nil
        }
        delegate?.didUpdate.send()
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
            style: pen.style,
            thickness: pen.thickness
        )
        strokes.append(stroke)
        currentStroke = stroke
        currentPoint = point
        currentStroke?.begin(at: point)
        return stroke
    }

    func appendStroke(with point: CGPoint) {
        guard let currentStroke else { return }
        guard let currentPoint, point.distance(to: currentPoint) > currentStroke.thickness * currentStroke.style.stepRate else { return }
        currentStroke.append(to: point)
        self.currentPoint = point
    }

    func endStroke(at point: CGPoint) {
        guard currentPoint != nil else { return }
        currentStroke?.finish(at: point)
        previousStroke = currentStroke
        currentStroke = nil
        self.currentPoint = nil
        delegate?.didUpdate.send()
    }
}

extension GraphicContext {
    enum RenderType {
        case inProgress
        case newlyFinished
        case finished
    }
}
