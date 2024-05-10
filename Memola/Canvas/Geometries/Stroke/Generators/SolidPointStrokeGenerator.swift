//
//  SolidPointStrokeGenerator.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

struct SolidPointStrokeGenerator: StrokeGenerator {
    var configuration: Configuration

    func begin(at point: CGPoint, on stroke: Stroke) {
        stroke.keyPoints.append(point)
        addPoint(point, on: stroke)
    }

    func append(to point: CGPoint, on stroke: Stroke) {
        guard stroke.keyPoints.count > 0 else {
            return
        }
        stroke.keyPoints.append(point)
        switch stroke.keyPoints.count {
        case 2:
            let start = stroke.keyPoints[0]
            let end = stroke.keyPoints[1]
            let control = CGPoint.middle(p1: start, p2: end)
            addCurve(from: start, to: end, by: control, on: stroke)
        case 3:
            discardVertices(upto: stroke.vertexIndex, quadIndex: stroke.quadIndex, on: stroke)
            let index = stroke.keyPoints.count - 1
            var start = stroke.keyPoints[index - 2]
            var end = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            var control = CGPoint.middle(p1: start, p2: end)
            addCurve(from: start, to: end, by: control, on: stroke)
            start = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            control = stroke.keyPoints[index - 1]
            end = CGPoint.middle(p1: stroke.keyPoints[index - 1], p2: stroke.keyPoints[index])
            addCurve(from: start, to: end, by: control, on: stroke)
        default:
            smoothOutPath(on: stroke)
            let index = stroke.keyPoints.count - 1
            let start = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let control = stroke.keyPoints[index - 1]
            let end = CGPoint.middle(p1: stroke.keyPoints[index - 1], p2: stroke.keyPoints[index])
            addCurve(from: start, to: end, by: control, on: stroke)
        }
    }

    func finish(at point: CGPoint, on stroke: Stroke) {
        switch stroke.keyPoints.count {
        case 0...1:
            break
        default:
            append(to: point, on: stroke)
            let index = stroke.keyPoints.count - 1
            let start = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let end = stroke.keyPoints[index]
            let control = CGPoint.middle(p1: start, p2: end)
            addCurve(from: start, to: end, by: control, on: stroke)
        }
    }

    private func smoothOutPath(on stroke: Stroke) {
        discardVertices(upto: stroke.vertexIndex, quadIndex: stroke.quadIndex, on: stroke)
        adjustPreviousKeyPoint(on: stroke)
        switch stroke.keyPoints.count {
        case 4:
            let index = stroke.keyPoints.count - 2
            let start = stroke.keyPoints[index - 2]
            let end = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let control = CGPoint.middle(p1: start, p2: end)
            addCurve(from: start, to: end, by: control, on: stroke)
            fallthrough
        default:
            let index = stroke.keyPoints.count - 2
            let start = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let control = stroke.keyPoints[index - 1]
            let end = CGPoint.middle(p1: stroke.keyPoints[index - 1], p2: stroke.keyPoints[index])
            addCurve(from: start, to: end, by: control, on: stroke)
        }
        stroke.quadIndex = stroke.quads.count - 1
        stroke.vertexIndex = stroke.vertices.endIndex - 1
    }

    private func adjustPreviousKeyPoint(on stroke: Stroke) {
        let index = stroke.keyPoints.count - 1
        let prev = stroke.keyPoints[index - 1]
        let current = stroke.keyPoints[index]
        let averageX = (prev.x + current.x) / 2
        let averageY = (prev.y + current.y) / 2
        let point = CGPoint(x: averageX, y: averageY)
        if index != 0 {
            stroke.keyPoints[index] = point
        }
        if index - 1 != 0 {
            stroke.keyPoints[index - 1] = point
        }
    }

    private func addPoint(_ point: CGPoint, on stroke: Stroke) {
        let rotation: CGFloat
        switch configuration.rotation {
        case .fixed:
            rotation = 0
        case .random:
            rotation = CGFloat.random(in: 0...360) * .pi / 180
        }
        let quad = stroke.addQuad(at: point, rotation: rotation, shape: .rounded)
        stroke.vertices.append(contentsOf: quad.generateVertices(stroke.color))
        stroke.vertexCount = stroke.vertices.endIndex
    }

    private func addCurve(from start: CGPoint, to end: CGPoint, by control: CGPoint, on stroke: Stroke) {
        let distance = start.distance(to: end)
        let factor: CGFloat
        switch configuration.granularity {
        case .automatic:
            factor = min(5, 1 / (stroke.thickness * 1 / 50))
        case .fixed:
            factor = 1 / (stroke.thickness * stroke.penStyle.anyPenStyle.stepRate)
        case .none:
            factor = 1 / (stroke.thickness * 10 / 500)
        }
        let segments = max(Int(distance * factor), 1)
        for i in 0..<segments {
            let t = CGFloat(i) / CGFloat(segments)
            let x = pow(1 - t, 2) * start.x + 2.0 * (1 - t) * t * control.x + t * t * end.x
            let y = pow(1 - t, 2) * start.y + 2.0 * (1 - t) * t * control.y + t * t * end.y
            let point = CGPoint(x: x, y: y)
            addPoint(point, on: stroke)
        }
    }

    #warning("TODO: remove later")
    private func addLine(from start: CGPoint, to end: CGPoint, on stroke: Stroke) {
        let distance = end.distance(to: start)
        let segments = max(distance / stroke.penStyle.anyPenStyle.stepRate, 2)
        for i in 0..<Int(segments) {
            let i = CGFloat(i)
            let x = start.x + (end.x - start.x) * (i / segments)
            let y = start.y + (end.y - start.y) * (i / segments)
            let point = CGPoint(x: x, y: y)
            addPoint(point, on: stroke)
        }
    }

    private func discardVertices(upto index: Int, quadIndex: Int, on stroke: Stroke) {
        if index < 0 {
            stroke.vertices.removeAll()
            discardQuads(from: quadIndex + 1, on: stroke)
        } else {
            let count = stroke.vertices.endIndex
            let dropCount = count - (max(0, index) + 1)
            stroke.vertices.removeLast(dropCount)
            discardQuads(from: quadIndex + 1, on: stroke)
        }
    }

    private func discardQuads(from start: Int, on stroke: Stroke) {
        let quads = stroke.quads.array
        Persistence.performe { context in
            for index in start..<quads.count {
                if let quad = quads[index] as? Quad {
                    quad.stroke = nil
                    context.delete(quad)
                    stroke.quads.remove(quad)
                }
            }
        }
    }
}

extension SolidPointStrokeGenerator {
    struct Configuration {
        var rotation: Rotation = .fixed
        var granularity: Granularity = .automatic
    }

    enum Rotation {
        case fixed
        case random
    }

    enum Granularity {
        case automatic
        case fixed
        case none
    }
}
