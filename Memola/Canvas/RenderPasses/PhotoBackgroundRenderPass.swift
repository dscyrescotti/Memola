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
    var elementGroup: ElementGroup?

    var clearsTexture: Bool = true

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        photoBackgroundPipelineState = PipelineStates.createPhotoPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { 
        photoBackgroundTexture = Textures.createPhotoBackgroundTexture(from: renderer, size: size, pixelFormat: renderer.pixelFormat)
    }

    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) {
        guard let elementGroup else { return }
        guard let descriptor else { return }

        descriptor.colorAttachments[0].texture = photoBackgroundTexture
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)

        guard !elementGroup.isEmpty else { return }

        let photos = elementGroup.elements.compactMap { element -> Photo? in
            guard case .photo(let photo) = element else { return nil }
            return photo
        }

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        renderEncoder.label = "Photo Background Render Encoder"

        guard let photoBackgroundPipelineState else { return }
        renderEncoder.setRenderPipelineState(photoBackgroundPipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)

        for photo in photos {
            photo.draw(device: renderer.device, renderEncoder: renderEncoder)
        }

        renderEncoder.endEncoding()
    }
}
