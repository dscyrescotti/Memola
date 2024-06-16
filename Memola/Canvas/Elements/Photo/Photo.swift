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
    var image: UIImage?
    var url: URL?
    var bounds: [CGFloat]
    var createdAt: Date
    var bookmark: Data?

    var object: PhotoObject?

    var texture: MTLTexture?
    var vertices: [PhotoVertex] = []
    var vertexCount: Int = 0
    var vertexBuffer: MTLBuffer?

    init(url: URL?, size: CGSize, origin: CGPoint, bounds: [CGFloat], createdAt: Date, bookmark: Data?) {
        self.size = size
        self.origin = origin
        self.url = url
        self.bounds = bounds
        self.createdAt = createdAt
        self.bookmark = bookmark
        generateVertices()
    }

    convenience init(object: PhotoObject) {
        self.init(
            url: object.imageURL,
            size: .init(width: object.width, height: object.height),
            origin: .init(x: object.originX, y: object.originY),
            bounds: object.bounds,
            createdAt: object.createdAt ?? .now,
            bookmark: object.bookmark
        )
        self.object = object
    }

    func generateVertices() {
        let minX = origin.x - size.width / 2
        let maxX = origin.x + size.width / 2
        let minY = origin.y - size.height / 2
        let maxY = origin.y + size.height / 2
        vertices = [
            PhotoVertex(x: minX, y: minY, textCoord: CGPoint(x: 0, y: 0)),
            PhotoVertex(x: minX, y: maxY, textCoord: CGPoint(x: 0, y: 1)),
            PhotoVertex(x: maxX, y: minY, textCoord: CGPoint(x: 1, y: 0)),
            PhotoVertex(x: maxX, y: maxY, textCoord: CGPoint(x: 1, y: 1)),
        ]
    }

    func getBookmarkURL() -> URL? {
        var isStale = false
        guard let bookmark else {
            return nil
        }
        guard let bookmarkURL = try? URL(resolvingBookmarkData: bookmark, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        return bookmarkURL
    }
}

extension Photo: Drawable {
    func prepare(device: any MTLDevice) {
        if vertexBuffer == nil {
            vertexCount = vertices.endIndex
            vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<PhotoVertex>.stride, options: [])
        }
        if texture == nil, let url = getBookmarkURL() {
            texture = Textures.createPhotoTexture(for: url, on: device)
        }
    }
    
    func draw(device: any MTLDevice, renderEncoder: any MTLRenderCommandEncoder) {
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
        texture = nil
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

    var element: Element {
        .photo(self)
    }
}
