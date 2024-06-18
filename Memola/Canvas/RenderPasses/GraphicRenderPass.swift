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
        clearsTexture = true
    }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let strokeRenderPass, let eraserRenderPass, let photoRenderPass, let photoBackgroundRenderPass else { return }
        guard let descriptor else { return }

        guard let graphicPipelineState else { return }
        guard let graphicTexture else { return }

        descriptor.colorAttachments[0].texture = graphicTexture
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor.colorAttachments[0].storeAction = .store

        let graphicContext = canvas.graphicContext
        if renderer.redrawsGraphicRender {
            canvas.setGraphicRenderType(.finished)
            for _element in graphicContext.tree.search(box: canvas.bounds.box) {
                if graphicContext.previousElement == _element || graphicContext.currentElement == _element {
                    continue
                }
                switch _element {
                case .stroke(let _stroke):
                    let stroke = _stroke.value
                    guard stroke.isVisible(in: canvas.bounds) else { continue }
                    descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
                    switch stroke.style {
                    case .eraser:
                        eraserRenderPass.stroke = stroke
                        eraserRenderPass.descriptor = descriptor
                        eraserRenderPass.draw(on: canvas, with: renderer)
                    case .marker:
                        canvas.setGraphicRenderType(.finished)
                        strokeRenderPass.stroke = stroke
                        strokeRenderPass.graphicDescriptor = descriptor
                        strokeRenderPass.graphicPipelineState = graphicPipelineState
                        strokeRenderPass.draw(on: canvas, with: renderer)
                    }
                    clearsTexture = false
                case .photo(let photo):
                    descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
                    photoRenderPass.photo = photo
                    photoRenderPass.descriptor = descriptor
                    photoRenderPass.draw(on: canvas, with: renderer)

                    photoBackgroundRenderPass.photo = photo
                    photoBackgroundRenderPass.clearsTexture = clearsTexture
                    photoBackgroundRenderPass.draw(on: canvas, with: renderer)

                    clearsTexture = false
                }
            }
            renderer.redrawsGraphicRender = false
        }

        if let element = graphicContext.previousElement {
            descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
            switch element {
            case .stroke(let anyStroke):
                let stroke = anyStroke.value
                switch stroke.style {
                case .eraser:
                    eraserRenderPass.stroke = stroke
                    eraserRenderPass.descriptor = descriptor
                    eraserRenderPass.draw(on: canvas, with: renderer)
                case .marker:
                    canvas.setGraphicRenderType(.newlyFinished)
                    strokeRenderPass.stroke = stroke
                    strokeRenderPass.graphicDescriptor = descriptor
                    strokeRenderPass.graphicPipelineState = graphicPipelineState
                    strokeRenderPass.draw(on: canvas, with: renderer)
                }
            case .photo(let photo):
                photoRenderPass.photo = photo
                photoRenderPass.descriptor = descriptor
                photoRenderPass.draw(on: canvas, with: renderer)

                photoBackgroundRenderPass.photo = photo
                photoBackgroundRenderPass.clearsTexture = clearsTexture
                photoBackgroundRenderPass.draw(on: canvas, with: renderer)
            }
            clearsTexture = false
            graphicContext.previousElement = nil
        }

        let eraserStrokes = graphicContext.eraserStrokes
        for eraserStroke in eraserStrokes {
            if eraserStroke.finishesSaving {
                graphicContext.eraserStrokes.remove(eraserStroke)
                continue
            }
        }
    }
}
