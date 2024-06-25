//
//  GridContext.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class GridContext {
    var vertices: [GridVertex] = []
    var vertexCount: Int = 0
    var vertexBuffer: MTLBuffer?

    init() {
        generateVertices()
    }

    func generateVertices() {
        let steps = stride(from: -10, through: 110, by: 0.25)
        for y in steps {
            for x in steps {
                vertices.append(GridVertex(x: CGFloat(x), y: CGFloat(y)))
            }
        }
        vertexCount = vertices.count
    }
}

extension GridContext: Drawable {
    func prepare(device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<GridVertex>.stride, options: [])
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard vertexCount > .zero else { return }
        prepare(device: device)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: vertexCount)
    }
}
