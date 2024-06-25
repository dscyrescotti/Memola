//
//  ViewPortContext.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class ViewPortContext {
    var vertices: [ViewPortVertex] = []
    let vertexCount: Int = 4
    var vertexBuffer: MTLBuffer?

    func setViewPortVertices() {
        vertexBuffer = nil
        vertices = [
            ViewPortVertex(x: -1, y: -1, textCoord: CGPoint(x: 0, y: 1)),
            ViewPortVertex(x: -1, y: 1, textCoord: CGPoint(x: 0, y: 0)),
            ViewPortVertex(x: 1, y: -1, textCoord: CGPoint(x: 1, y: 1)),
            ViewPortVertex(x: 1, y: 1, textCoord: CGPoint(x: 1, y: 0)),
        ]
    }

    func setViewPortUpdateVertices(from bounds: CGRect) {
        vertexBuffer = nil
        vertices = [
            ViewPortVertex(x: bounds.minX, y: bounds.minY, textCoord: CGPoint(x: 0, y: 0)),
            ViewPortVertex(x: bounds.minX, y: bounds.maxY, textCoord: CGPoint(x: 0, y: 1)),
            ViewPortVertex(x: bounds.maxX, y: bounds.minY, textCoord: CGPoint(x: 1, y: 0)),
            ViewPortVertex(x: bounds.maxX, y: bounds.maxY, textCoord: CGPoint(x: 1, y: 1)),
        ]
    }
}

extension ViewPortContext: Drawable {
    func prepare(device: MTLDevice) {
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertexCount * MemoryLayout<ViewPortVertex>.stride, options: [])
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        prepare(device: device)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
    }
}
