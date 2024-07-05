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

    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        draw(into: commandBuffer, on: canvas, with: renderer, isPreview: false)
    }

    @discardableResult
    func drawPreview(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        draw(into: commandBuffer, on: canvas, with: renderer, isPreview: true)
    }

    private func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer, isPreview: Bool) -> Bool {
        guard let elementGroup else { return false }
        guard let descriptor else { return false }

        // MARK: - Generating vertices
        guard !elementGroup.isEmpty, let quadPipelineState else { return false }
        let eraserStrokes = elementGroup.elements.compactMap { element -> EraserStroke? in
            guard case .stroke(let anyStroke) = element else { return nil }
            return anyStroke.value as? EraserStroke
        }
        let quads = eraserStrokes.flatMap { $0.quads }
        guard !quads.isEmpty else { return false }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return false }

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
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return false }
        renderEncoder.label = "Stroke Render Encoder"

        guard let eraserPipelineState else { return false }
        renderEncoder.setRenderPipelineState(eraserPipelineState)

        if isPreview {
            canvas.setPreviewUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        } else {
            canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        }

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
        return true
    }
}
