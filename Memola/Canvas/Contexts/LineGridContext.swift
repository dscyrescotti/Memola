//
//  LineGridContext.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/25/24.
//

import MetalKit
import Foundation

final class LineGridContext {
    var vertices: [LineGridVertex] = []
    var vertexCount: Int = 0
    var vertexBuffer: MTLBuffer?

    init() {
        generateVertices()
    }

    func generateVertices() {
        let steps = stride(from: -10, through: 110, by: 0.25)
        for y in steps {
            vertices.append(LineGridVertex(position: [-10, Float(y), 0, 0]))
            vertices.append(LineGridVertex(position: [110, Float(y), 0, 0]))
        }
        for x in steps {
            vertices.append(LineGridVertex(position: [Float(x), -10, 0, 0]))
            vertices.append(LineGridVertex(position: [Float(x), 110, 0, 0]))
        }
        vertexCount = vertices.count
    }
}

extension LineGridContext: Drawable {
    func prepare(device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<LineGridVertex>.stride, options: [])
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard vertexCount > .zero else { return }
        prepare(device: device)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexCount)
    }
}
