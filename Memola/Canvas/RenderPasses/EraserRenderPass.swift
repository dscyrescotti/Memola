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

    var elementGroup: ElementGroup?
    weak var graphicTexture: MTLTexture?

    init(renderer: Renderer) {
        eraserPipelineState = PipelineStates.createEraserPipelineState(from: renderer)
        quadPipelineState = PipelineStates.createQuadPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) {
        guard let elementGroup else { return }
        guard let descriptor else { return }

        // MARK: - Generating vertices
        guard !elementGroup.isEmpty, let quadPipelineState else { return }
        let eraserStrokes = elementGroup.elements.compactMap { element -> EraserStroke? in
            guard case .stroke(let anyStroke) = element else { return nil }
            return anyStroke.value as? EraserStroke
        }
        let quads = eraserStrokes.flatMap { $0.quads }
        guard !quads.isEmpty else { return }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }

        computeEncoder.label = "Quad Compute Encoder"

        let quadCount = quads.endIndex
        let quadBuffer = renderer.device.makeBuffer(bytes: quads, length: MemoryLayout<Quad>.stride * quadCount, options: [])
        let indexBuffer = renderer.device.makeBuffer(length: MemoryLayout<UInt>.stride * quadCount * 6, options: [.cpuCacheModeWriteCombined])
        let vertexBuffer = renderer.device.makeBuffer(length: MemoryLayout<QuadVertex>.stride * quadCount * 4, options: [.cpuCacheModeWriteCombined])

        computeEncoder.setComputePipelineState(quadPipelineState)
        computeEncoder.setBuffer(quadBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 2)

        let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
        let numThreadgroups = MTLSize(width: quadCount + 1, height: 1, depth: 1)
        computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
        computeEncoder.endEncoding()

        // MARK: - Rendering eraser
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = "Stroke Render Encoder"

        guard let eraserPipelineState else { return }
        renderEncoder.setRenderPipelineState(eraserPipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)

        if let indexBuffer {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: quads.endIndex * 6,
                indexType: .uint32,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0
            )
        }
        renderEncoder.endEncoding()
    }
}
