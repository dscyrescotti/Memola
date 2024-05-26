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

    weak var strokeRenderPass: StrokeRenderPass?
    weak var eraserRenderPass: EraserRenderPass?

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
        guard let strokeRenderPass, let eraserRenderPass else { return }
        guard let descriptor else { return }

        guard let graphicPipelineState else { return }
        guard let graphicTexture else { return }

        descriptor.colorAttachments[0].texture = graphicTexture
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor.colorAttachments[0].storeAction = .store

        let graphicContext = canvas.graphicContext
        if renderer.redrawsGraphicRender {
            canvas.setGraphicRenderType(.finished)
            let boundingBox = canvas.bounds.boundingBox
            for stroke in graphicContext.strokes.elements(inBoundingRectMin: boundingBox.min, rectMax: boundingBox.max) {
                guard let stroke = stroke as? (any Stroke) else { return }
                if graphicContext.previousStroke === stroke || graphicContext.currentStroke === stroke {
                    continue
                }
                descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
                clearsTexture = false
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
            }
            renderer.redrawsGraphicRender = false
        }

        if let stroke = graphicContext.previousStroke {
            descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
            clearsTexture = false
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
            graphicContext.previousStroke = nil
        }
    }
}
