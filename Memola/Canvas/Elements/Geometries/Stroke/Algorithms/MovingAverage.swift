//
//  MovingAverage.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/22/24.
//

import Foundation

class MovingAverage {
    private var sum: CGPoint
    private var points: [CGPoint]
    private var windowSize: Int

    init(windowSize: Int) {
        self.windowSize = windowSize
        self.points = []
        self.sum = CGPoint.zero
    }

    func addPoint(_ point: CGPoint) -> CGPoint {
        points.append(point)
        sum.x += point.x
        sum.y += point.y

        if points.count > windowSize {
            let removedValue = points.remove(at: 0)
            sum.x -= removedValue.x
            sum.y -= removedValue.y
        }

        return currentAverage()
    }

    func currentAverage() -> CGPoint {
        guard !points.isEmpty else { return CGPoint.zero }
        let count = CGFloat(points.count)
        return CGPoint(x: sum.x / count, y: sum.y / count)
    }
}
