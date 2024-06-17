//
//  PhotoRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/13/24.
//

import MetalKit
import Foundation

class PhotoRenderPass: RenderPass {
    var label: String = "Photo Render Pass"
    
    var descriptor: MTLRenderPassDescriptor?

    var photoPipelineState: MTLRenderPipelineState?
    weak var graphicTexture: MTLTexture?

    var photo: Photo?

    init(renderer: Renderer) {
        photoPipelineState = PipelineStates.createPhotoPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let descriptor else { return }

        guard let commandBuffer = renderer.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Photo Command Buffer"

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = label

        guard let photoPipelineState else { return }
        renderEncoder.setRenderPipelineState(photoPipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        photo?.draw(device: renderer.device, renderEncoder: renderEncoder)

        renderEncoder.endEncoding()
        commandBuffer.commit()
    }
}
