//
//  Box.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/4/24.
//

import Foundation

struct Box: Equatable, Decodable {
    var minX: Double
    var minY: Double
    var maxX: Double
    var maxY: Double

    init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }

    var area: Double {
        (maxX - minX) * (maxY - minY)
    }

    var margin: Double {
        (maxX - minX) + (maxY - minY)
    }

    func enlargedArea(for box: Box) -> Double {
        (max(box.maxX, maxX) - min(box.minX, minX)) * (max(box.maxY, maxY) - min(box.minY, minY))
    }

    func intersects(with box: Box) -> Bool {
        box.minX <= maxX && box.minY <= maxY && box.maxX >= minX && box.maxY >= minY
    }

    func contains(with box: Box) -> Bool {
        minX <= box.minX && minY <= box.minY && box.maxX <= maxX && box.maxY <= maxY
    }

    func intersectedArea(on box: Box) -> Double {
        let minX = max(minX, box.minX)
        let minY = max(minY, box.minY)
        let maxX = min(maxX, box.maxX)
        let maxY = min(maxY, box.maxY)

        return max(0, maxX - minX) * max(0, maxY - minY)
    }

    mutating func enlarge(for box: Box) {
        minX = min(minX, box.minX)
        minY = min(minY, box.minY)
        maxX = max(maxX, box.maxX)
        maxY = max(maxY, box.maxY)
    }

    static var infinity = Box(minX: .infinity, minY: .infinity, maxX: -.infinity, maxY: -.infinity)
}
