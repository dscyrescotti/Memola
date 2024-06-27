//
//  GraphicRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class GraphicRenderPass: RenderPass {
    var label: String { "Graphic Render Pass" }
    var descriptor: MTLRenderPassDescriptor?
    var graphicTexture: MTLTexture?

    var graphicPipelineState: MTLRenderPipelineState?

    weak var photoRenderPass: PhotoRenderPass?
    weak var strokeRenderPass: StrokeRenderPass?
    weak var eraserRenderPass: EraserRenderPass?
    weak var photoBackgroundRenderPass: PhotoBackgroundRenderPass?

    var clearsTexture: Bool = true

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        graphicPipelineState = PipelineStates.createGraphicPipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) {
        guard size != .zero else { return }
        graphicTexture = Textures.createGraphicTexture(from: renderer, size: size, pixelFormat: view.colorPixelFormat)
    }

    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        descriptor?.colorAttachments[0].texture = graphicTexture
        descriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor?.colorAttachments[0].storeAction = .store

        let graphicContext = canvas.graphicContext
        if renderer.redrawsGraphicRender {
            clearsTexture = true
            photoBackgroundRenderPass?.clearsTexture = true
            canvas.setGraphicRenderType(.finished)
            var elementGroup: ElementGroup?
            let start = Date.now.timeIntervalSince1970 * 1000
            for _element in graphicContext.tree.search(box: canvas.bounds.box) {
                if graphicContext.previousElement == _element || graphicContext.currentElement == _element {
                    continue
                }
                if elementGroup == nil {
                    let _elementGroup = ElementGroup(_element)
                    elementGroup = _elementGroup
                } else {
                    guard let _elementGroup = elementGroup else { continue }
                    if _elementGroup.isSameElement(_element) {
                        _elementGroup.add(_element)
                    } else {
                        if let elementGroup {
                            draw(for: elementGroup, into: commandBuffer, on: canvas, with: renderer)
                        }
                        let _elementGroup = ElementGroup(_element)
                        elementGroup = _elementGroup
                    }
                }
            }
            if let elementGroup {
                draw(for: elementGroup, into: commandBuffer, on: canvas, with: renderer)
            }
            let end = Date.now.timeIntervalSince1970 * 1000
            NSLog("[Memola] - duration: \(end - start)")
            renderer.redrawsGraphicRender = false
        }
        if let element = graphicContext.previousElement {
            let elementGroup = ElementGroup(element)
            draw(for: elementGroup, into: commandBuffer, on: canvas, with: renderer)
            graphicContext.previousElement = nil
        }
        return true
    }

    private func draw(for elementGroup: ElementGroup, into commandBuffer: MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) {
        switch elementGroup.type {
        case .stroke:
            descriptor?.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
            strokeRenderPass?.elementGroup = elementGroup
            strokeRenderPass?.graphicDescriptor = descriptor
            strokeRenderPass?.graphicPipelineState = graphicPipelineState
            let status = strokeRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)
            if clearsTexture, let status {
                clearsTexture = !status
            }
        case .eraser:
            descriptor?.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
            eraserRenderPass?.elementGroup = elementGroup
            eraserRenderPass?.descriptor = descriptor
            let status = eraserRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)
            if clearsTexture, let status {
                clearsTexture = !status
            }
        case .photo:
            descriptor?.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
            photoRenderPass?.elementGroup = elementGroup
            photoRenderPass?.descriptor = descriptor
            let photoStatus = photoRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)

            photoBackgroundRenderPass?.elementGroup = elementGroup
            let photoBackgroundStatus = photoBackgroundRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)

            if clearsTexture, let photoStatus {
                clearsTexture = !photoStatus
            }
            if photoBackgroundRenderPass?.clearsTexture == true, let photoBackgroundStatus {
                photoBackgroundRenderPass?.clearsTexture = !photoBackgroundStatus
            }
        }
    }
}
