//
//  CGPoint++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

extension CGPoint {
    func muliply(by factor: CGFloat) -> CGPoint {
        CGPoint(x: x * factor, y: y * factor)
    }

    func distance(to point: CGPoint) -> CGFloat {
        let p = pow(x - point.x, 2) + pow(y - point.y, 2)
        return sqrt(p)
    }

    static func middle(p1: CGPoint, p2: CGPoint) -> CGPoint {
        return CGPoint(x: (p1.x + p2.x) * 0.5, y: (p1.y + p2.y) * 0.5)
    }

    func angle(to point: CGPoint) -> CGFloat {
        let deltaX = point.x - x
        let deltaY = point.y - y
        return atan2(deltaY, deltaX)
    }
}
