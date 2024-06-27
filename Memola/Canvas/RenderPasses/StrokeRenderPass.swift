//
//  StrokeRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class StrokeRenderPass: RenderPass {
    var label: String = "Stroke Render Pass"

    var descriptor: MTLRenderPassDescriptor?
    weak var graphicDescriptor: MTLRenderPassDescriptor?

    var strokePipelineState: MTLRenderPipelineState?
    var quadPipelineState: MTLComputePipelineState?
    weak var graphicPipelineState: MTLRenderPipelineState?

    var elementGroup: ElementGroup?
    var strokeTexture: MTLTexture?

    weak var eraserRenderPass: EraserRenderPass?

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        strokePipelineState = PipelineStates.createStrokePipelineState(from: renderer)
        quadPipelineState = PipelineStates.createQuadPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) {
        guard size != .zero else { return }
        strokeTexture = Textures.createStrokeTexture(from: renderer, size: size, pixelFormat: view.colorPixelFormat)
    }
    
    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        guard let elementGroup else { return false }
        guard let descriptor else { return false }

        // MARK: - Generating vertices
        guard !elementGroup.isEmpty, let quadPipelineState else { return false }
        let penStrokes = elementGroup.elements.compactMap { element -> PenStroke? in
            guard case .stroke(let anyStroke) = element else { return nil }
            return anyStroke.value as? PenStroke
        }
        let penStroke = penStrokes.first
        let quads = penStrokes.flatMap { $0.quads }
        let erasedQuads = Set(penStrokes.flatMap { $0.eraserStrokes }).flatMap { $0.quads }
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

        // MARK: - Rendering stroke
        guard let strokeTexture else { return false }
        descriptor.colorAttachments[0].texture = strokeTexture
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return false }
        renderEncoder.label = "Stroke Render Encoder"

        guard let strokePipelineState else { return false }
        renderEncoder.setRenderPipelineState(strokePipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        
        if let penStyle = penStroke?.penStyle, let indexBuffer {
            if penStyle.textureName != nil {
                let texture = penStyle.loadTexture(on: renderer.device)
                renderEncoder.setFragmentTexture(texture, index: 0)
            }
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

        // MARK: Erasing path
        if let eraserPipelineState = eraserRenderPass?.eraserPipelineState, !erasedQuads.isEmpty {
            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return false }

            computeEncoder.label = "Erased Quad Compute Encoder"

            let erasedQuadCount = erasedQuads.endIndex
            let erasedQuadBuffer = renderer.device.makeBuffer(bytes: erasedQuads, length: MemoryLayout<Quad>.stride * erasedQuadCount, options: [])
            let erasedIndexBuffer = renderer.device.makeBuffer(length: MemoryLayout<UInt>.stride * erasedQuadCount * 6, options: [.cpuCacheModeWriteCombined])
            let erasedVertexBuffer = renderer.device.makeBuffer(length: MemoryLayout<QuadVertex>.stride * erasedQuadCount * 4, options: [.cpuCacheModeWriteCombined])

            computeEncoder.setComputePipelineState(quadPipelineState)
            computeEncoder.setBuffer(erasedQuadBuffer, offset: 0, index: 0)
            computeEncoder.setBuffer(erasedIndexBuffer, offset: 0, index: 1)
            computeEncoder.setBuffer(erasedVertexBuffer, offset: 0, index: 2)

            let threadsPerGroup = MTLSize(width: 1, height: 1, depth: 1)
            let numThreadgroups = MTLSize(width: erasedQuadCount + 1, height: 1, depth: 1)
            computeEncoder.dispatchThreadgroups(numThreadgroups, threadsPerThreadgroup: threadsPerGroup)
            computeEncoder.endEncoding()

            descriptor.colorAttachments[0].loadAction = .load
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return false }
            renderEncoder.label = "Stroke Eraser Render Encoder"
            
            renderEncoder.setRenderPipelineState(eraserPipelineState)

            canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
            if let erasedIndexBuffer {
                renderEncoder.setVertexBuffer(erasedVertexBuffer, offset: 0, index: 0)
                renderEncoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: erasedQuadCount * 6,
                    indexType: .uint32,
                    indexBuffer: erasedIndexBuffer,
                    indexBufferOffset: 0
                )
            }
            renderEncoder.endEncoding()
        }

        // MARK: Drawing on graphic texture
        guard let graphicDescriptor, let graphicPipelineState else { return false }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: graphicDescriptor) else { return false }
        renderEncoder.label = "Stroke Graphic Render Encoder"
        renderEncoder.setRenderPipelineState(graphicPipelineState)

        renderEncoder.setFragmentTexture(strokeTexture, index: 0)
        var uniforms = GraphicUniforms(color: elementGroup.getPenColor() ?? [])
        let uniformsBuffer = renderer.device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        canvas.renderGraphic(device: renderer.device, renderEncoder: renderEncoder)
        renderEncoder.endEncoding()

        return true
    }
}
