//
//  EraserRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class EraserRenderPass: RenderPass {
    var label: String = "Eraser Render Pass"

    var descriptor: MTLRenderPassDescriptor?

    var eraserPipelineState: MTLRenderPipelineState?
    var quadPipelineState: MTLComputePipelineState?

    var stroke: PenStroke?
    weak var graphicTexture: MTLTexture?

    init(renderer: Renderer) {
        eraserPipelineState = PipelineStates.createEraserPipelineState(from: renderer)
        quadPipelineState = PipelineStates.createQuadPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let descriptor else { return }

        generateVertexBuffer(on: canvas, with: renderer)

        guard let commandBuffer = renderer.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Eraser Command Buffer"

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = label

        guard let eraserPipelineState else { return }
        renderEncoder.setRenderPipelineState(eraserPipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        stroke?.draw(device: renderer.device, renderEncoder: renderEncoder)

        renderEncoder.endEncoding()
        commandBuffer.commit()
    }

    private func generateVertexBuffer(on canvas: Canvas, with renderer: Renderer) {
        guard let stroke, !stroke.isEmpty, let quadPipelineState else { return }
        guard let quadCommandBuffer = renderer.commandQueue.makeCommandBuffer() else { return }
        guard let computeEncoder = quadCommandBuffer.makeComputeCommandEncoder() else { return }

        computeEncoder.label = "Quad Render Pass"

        let quadCount = stroke.quads.endIndex
        var quads = stroke.quads
        let quadBuffer = renderer.device.makeBuffer(bytes: &quads, length: MemoryLayout<Quad>.stride * quadCount, options: [])
        let indexBuffer = renderer.device.makeBuffer(length: MemoryLayout<UInt>.stride * quadCount * 6, options: [])
        let vertexBuffer = renderer.device.makeBuffer(length: MemoryLayout<QuadVertex>.stride * quadCount * 4, options: [])

        computeEncoder.setComputePipelineState(quadPipelineState)
        computeEncoder.setBuffer(quadBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 2)

        stroke.indexBuffer = indexBuffer
        stroke.vertexBuffer = vertexBuffer

        let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: quadCount + 1, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()
        quadCommandBuffer.commit()
        quadCommandBuffer.waitUntilCompleted()
    }
}
