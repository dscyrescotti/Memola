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

    var stroke: Stroke?
    weak var graphicTexture: MTLTexture?

    init(renderer: Renderer) {
        eraserPipelineState = PipelineStates.createEraserPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let descriptor else { return }

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
}
