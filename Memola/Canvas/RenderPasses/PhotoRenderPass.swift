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

    var elementGroup: ElementGroup?

    init(renderer: Renderer) {
        photoPipelineState = PipelineStates.createPhotoPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        guard let elementGroup else { return false }
        guard let descriptor else { return false }

        guard !elementGroup.isEmpty else { return false }

        let photos = elementGroup.elements.compactMap { element -> Photo? in
            guard case .photo(let photo) = element else { return nil }
            return photo
        }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else { return false }
        renderEncoder.label = "Photo Render Encoder"

        guard let photoPipelineState else { return false }
        renderEncoder.setRenderPipelineState(photoPipelineState)

        canvas.setUniformsBuffer(device: renderer.device, renderEncoder: renderEncoder)

        for photo in photos {
            photo.draw(device: renderer.device, renderEncoder: renderEncoder)
        }

        renderEncoder.endEncoding()
        return true
    }
}
