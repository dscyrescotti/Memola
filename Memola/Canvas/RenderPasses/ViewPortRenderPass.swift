//
//  ViewPortRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

final class ViewPortRenderPass: RenderPass {
    var label: String { "View Port Render Pass"}
    var descriptor: MTLRenderPassDescriptor?

    var pointGridPipelineState: MTLRenderPipelineState?
    var lineGridPipelineState: MTLRenderPipelineState?
    var viewPortPipelineState: MTLRenderPipelineState?
    var viewPortUpdatePipelineState: MTLRenderPipelineState?

    weak var cacheTexture: MTLTexture?
    weak var photoBackgroundTexture: MTLTexture?

    weak var view: MTKView?

    var excludesGraphic: Bool = false
    var excludesPhotoBackground: Bool = false

    init(renderer: Renderer) {
        pointGridPipelineState = PipelineStates.createPointGridPipelineState(from: renderer)
        lineGridPipelineState = PipelineStates.createLineGridPipelineState(from: renderer)
        viewPortPipelineState = PipelineStates.createViewPortPipelineState(from: renderer)
        viewPortUpdatePipelineState = PipelineStates.createViewPortPipelineState(from: renderer, isUpdate: true)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        guard let descriptor else {
            return false
        }
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return false
        }
        renderEncoder.label = "View Port Render Encoder"

        switch canvas.gridMode {
        case .none:
            break
        case .point:
            guard let pointGridPipelineState else { return false }
            renderEncoder.setRenderPipelineState(pointGridPipelineState)
            canvas.renderPointGrid(device: renderer.device, renderEncoder: renderEncoder)
        case .line:
            guard let lineGridPipelineState else { return false }
            renderEncoder.setRenderPipelineState(lineGridPipelineState)
            canvas.renderLineGrid(device: renderer.device, renderEncoder: renderEncoder)
        }

        if renderer.updatesViewPort {
            guard let viewPortUpdatePipelineState else {
                return false
            }

            renderEncoder.setRenderPipelineState(viewPortUpdatePipelineState)

            if !excludesPhotoBackground {
                renderEncoder.setFragmentTexture(photoBackgroundTexture, index: 0)
                canvas.renderViewPortUpdate(device: renderer.device, renderEncoder: renderEncoder)
            }

            if !excludesGraphic {
                renderEncoder.setFragmentTexture(cacheTexture, index: 0)
                canvas.renderViewPortUpdate(device: renderer.device, renderEncoder: renderEncoder)
            }
        } else {
            guard let viewPortPipelineState else {
                return false
            }

            renderEncoder.setRenderPipelineState(viewPortPipelineState)

            if !excludesPhotoBackground {
                renderEncoder.setFragmentTexture(photoBackgroundTexture, index: 0)
                canvas.renderViewPort(device: renderer.device, renderEncoder: renderEncoder)
            }

            if !excludesGraphic {
                renderEncoder.setFragmentTexture(cacheTexture, index: 0)
                canvas.renderViewPort(device: renderer.device, renderEncoder: renderEncoder)
            }
        }

        renderEncoder.endEncoding()

        guard let drawable = view?.currentDrawable else {
            return false
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        return true
    }
}
