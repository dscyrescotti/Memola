//
//  PhotoBackgroundRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/18/24.
//

import MetalKit
import Foundation

class PhotoBackgroundRenderPass: RenderPass {
    var label: String = "Photo Background Render Pass"

    var descriptor: MTLRenderPassDescriptor?

    var photoBackgroundPipelineState: MTLRenderPipelineState?

    var photoBackgroundTexture: MTLTexture?

    var photo: Photo?

    var clearsTexture: Bool = true

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        photoBackgroundPipelineState = PipelineStates.createPhotoPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { 
        photoBackgroundTexture = Textures.createPhotoBackgroundTexture(from: renderer, size: size, pixelFormat: renderer.pixelFormat)
    }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let descriptor else { return }

        descriptor.colorAttachments[0].texture = photoBackgroundTexture
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)

        guard let commandBuffer = renderer.commandQueue.makeCommandBuffer() else { return }
        commandBuffer.label = "Photo Background Command Buffer"

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = label

        guard let photoBackgroundPipelineState else { return }
        renderEncoder.setRenderPipelineState(photoBackgroundPipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)
        photo?.draw(device: renderer.device, renderEncoder: renderEncoder)

        renderEncoder.endEncoding()
        commandBuffer.commit()
    }
}
