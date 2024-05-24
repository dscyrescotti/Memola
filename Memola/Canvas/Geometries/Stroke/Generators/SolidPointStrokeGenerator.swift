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
        let point = stroke.movingAverage.addPoint(point)
        stroke.keyPoints.append(point)
        addPoint(point, on: stroke)
    }

    func append(to point: CGPoint, on stroke: Stroke) {
        guard stroke.keyPoints.endIndex > 0 else {
            return
        }
        let point = stroke.movingAverage.addPoint(point)
        stroke.keyPoints.append(point)
        switch stroke.keyPoints.endIndex {
        case 2:
            let start = stroke.keyPoints[0]
            let end = stroke.keyPoints[1]
            let control = CGPoint.middle(p1: start, p2: end)
            addCurve(from: start, to: end, by: control, on: stroke)
        case 3:
            stroke.removeQuads(from: stroke.quadIndex + 1)
            let index = stroke.keyPoints.endIndex - 1
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
            let index = stroke.keyPoints.endIndex - 1
            let start = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let control = stroke.keyPoints[index - 1]
            let end = CGPoint.middle(p1: stroke.keyPoints[index - 1], p2: stroke.keyPoints[index])
            addCurve(from: start, to: end, by: control, on: stroke)
        }
    }

    func finish(at point: CGPoint, on stroke: Stroke) {
        switch stroke.keyPoints.endIndex {
        case 0...1:
            break
        default:
            append(to: point, on: stroke)
        }
    }

    private func smoothOutPath(on stroke: Stroke) {
        stroke.removeQuads(from: stroke.quadIndex + 1)
        adjustKeyPoint(on: stroke)
        switch stroke.keyPoints.endIndex {
        case 4:
            let index = stroke.keyPoints.endIndex - 2
            let start = stroke.keyPoints[index - 2]
            let end = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let control = CGPoint.middle(p1: start, p2: end)
            addCurve(from: start, to: end, by: control, on: stroke)
            fallthrough
        default:
            let index = stroke.keyPoints.endIndex - 2
            let start = CGPoint.middle(p1: stroke.keyPoints[index - 2], p2: stroke.keyPoints[index - 1])
            let control = stroke.keyPoints[index - 1]
            let end = CGPoint.middle(p1: stroke.keyPoints[index - 1], p2: stroke.keyPoints[index])
            addCurve(from: start, to: end, by: control, on: stroke)
        }
        stroke.quadIndex = stroke.quads.endIndex - 1
    }

    private func adjustKeyPoint(on stroke: Stroke) {
        let index = stroke.keyPoints.endIndex - 1
        let prev = stroke.keyPoints[index - 1]
        let current = stroke.keyPoints[index]
        let averageX = (prev.x + current.x) / 2
        let averageY = (prev.y + current.y) / 2
        let point = CGPoint(x: averageX, y: averageY)
        stroke.keyPoints[index] = point
    }

    private func addPoint(_ point: CGPoint, on stroke: Stroke) {
        let rotation: CGFloat
        switch configuration.rotation {
        case .fixed:
            rotation = 0
        case .random:
            rotation = CGFloat.random(in: 0...360) * .pi / 180
        }
        stroke.addQuad(at: point, rotation: rotation, shape: .rounded)
    }

    private func addCurve(from start: CGPoint, to end: CGPoint, by control: CGPoint, on stroke: Stroke) {
        let distance = start.distance(to: end)
        let factor: CGFloat
        switch configuration.granularity {
        case .automatic:
            factor = min(5, 1 / (stroke.thickness * 1 / 50))
        case .fixed:
            factor = 1 / (stroke.thickness * stroke.penStyle.stepRate)
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
