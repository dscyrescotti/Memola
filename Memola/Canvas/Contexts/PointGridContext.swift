//
//  PointGridContext.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class PointGridContext {
    var vertices: [PointGridVertex] = []
    var vertexCount: Int = 0
    var vertexBuffer: MTLBuffer?

    init() {
        generateVertices()
    }

    func generateVertices() {
        let steps = stride(from: -10, through: 110, by: 0.25)
        for y in steps {
            for x in steps {
                vertices.append(PointGridVertex(x: CGFloat(x), y: CGFloat(y)))
            }
        }
        vertexCount = vertices.count
    }
}

extension PointGridContext: Drawable {
    func prepare(device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<PointGridVertex>.stride, options: [])
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard vertexCount > .zero else { return }
        prepare(device: device)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
    }
}
