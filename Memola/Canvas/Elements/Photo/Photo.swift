//
//  Photo.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/13/24.
//

import MetalKit
import Foundation

final class Photo: @unchecked Sendable, Equatable, Comparable {
    var id: UUID = UUID()
    var size: CGSize
    var origin: CGPoint
    var bounds: [CGFloat]
    var createdAt: Date

    var object: PhotoObject?

    var vertices: [PhotoVertex] = []
    var vertexCount: Int = 0
    var vertexBuffer: MTLBuffer?

    init(size: CGSize, origin: CGPoint, bounds: [CGFloat], createdAt: Date) {
        self.size = size
        self.origin = origin
        self.bounds = bounds
        self.createdAt = createdAt
        generateVertices()
    }

    convenience init(object: PhotoObject) {
        self.init(
            size: .init(width: object.width, height: object.height),
            origin: .init(x: object.originX, y: object.originY),
            bounds: object.bounds,
            createdAt: object.createdAt ?? .now
        )
        self.object = object
    }

    func generateVertices() {
        let minX = origin.x - size.width / 2
        let maxX = origin.x + size.width / 2
        let minY = origin.y - size.height / 2
        let maxY = origin.y + size.height / 2
        vertices = [
            PhotoVertex(x: minX, y: minY, textCoord: CGPoint(x: 0, y: 1)),
            PhotoVertex(x: minX, y: maxY, textCoord: CGPoint(x: 0, y: 0)),
            PhotoVertex(x: maxX, y: minY, textCoord: CGPoint(x: 1, y: 1)),
            PhotoVertex(x: maxX, y: maxY, textCoord: CGPoint(x: 1, y: 0)),
        ]
    }
}

extension Photo: Drawable {
    func prepare(device: any MTLDevice) {
        guard vertexBuffer == nil else { return }
        vertexCount = vertices.endIndex
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<PhotoVertex>.stride, options: [])
    }
    
    func draw(device: any MTLDevice, renderEncoder: any MTLRenderCommandEncoder) {
        prepare(device: device)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
    }
}

extension Photo {
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func < (lhs: Photo, rhs: Photo) -> Bool {
        lhs.createdAt < rhs.createdAt
    }
}

extension Photo {
    var photoBounds: CGRect {
        let x = bounds[0]
        let y = bounds[1]
        let width = bounds[2] - x
        let height = bounds[3] - y
        return CGRect(x: x, y: y, width: width, height: height)
    }

    var photoBox: Box {
        Box(minX: bounds[0], minY: bounds[1], maxX: bounds[2], maxY: bounds[3])
    }

    func isVisible(in bounds: CGRect) -> Bool {
        bounds.contains(photoBounds) || bounds.intersects(photoBounds)
    }
}
