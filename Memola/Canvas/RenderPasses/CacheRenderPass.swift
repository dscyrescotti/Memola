//
//  CacheRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class CacheRenderPass: RenderPass {
    var label: String = "Cache Render Pass"

    var descriptor: MTLRenderPassDescriptor?

    var cachePipelineState: MTLComputePipelineState?
    var graphicPipelineState: MTLRenderPipelineState?

    weak var graphicTexture: MTLTexture?
    var cacheTexture: MTLTexture?

    weak var strokeRenderPass: StrokeRenderPass?
    weak var eraserRenderPass: EraserRenderPass?
    var clearsTexture: Bool = true

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        cachePipelineState = PipelineStates.createCachePipelineState(from: renderer)
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) {
        guard size != .zero else { return }
        cacheTexture = Textures.createCacheTexture(from: renderer, size: size, pixelFormat: view.colorPixelFormat)
    }

    func draw(on canvas: Canvas, with renderer: Renderer) {
        guard let descriptor, let strokeRenderPass, let eraserRenderPass else { return }

        copyTexture(on: canvas, with: renderer)

        guard let graphicPipelineState else { return }
        descriptor.colorAttachments[0].texture = cacheTexture
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
        descriptor.colorAttachments[0].storeAction = .store

        let graphicContext = canvas.graphicContext
        if let stroke = graphicContext.currentStroke {
            switch stroke.style {
            case .eraser:
                eraserRenderPass.stroke = stroke
                eraserRenderPass.descriptor = descriptor
                eraserRenderPass.draw(on: canvas, with: renderer)
            case .marker:
                canvas.setGraphicRenderType(.inProgress)
                strokeRenderPass.stroke = stroke
                strokeRenderPass.graphicDescriptor = descriptor
                strokeRenderPass.graphicPipelineState = graphicPipelineState
                strokeRenderPass.draw(on: canvas, with: renderer)
            }
            clearsTexture = false
        }
    }

    private func copyTexture(on canvas: Canvas, with renderer: Renderer) {
        guard let graphicTexture, let cacheTexture else { return }
        guard let cachePipelineState else { return }
        guard let copyCommandBuffer = renderer.commandQueue.makeCommandBuffer() else {
            return
        }
        guard let computeEncoder = copyCommandBuffer.makeComputeCommandEncoder() else {
            return
        }
        computeEncoder.label = label

        computeEncoder.setComputePipelineState(cachePipelineState)
        computeEncoder.setTexture(graphicTexture, index: 0)
        computeEncoder.setTexture(cacheTexture, index: 1)
        let threadgroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let threadgroupCount = MTLSize(
            width: (graphicTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (graphicTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        computeEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        copyCommandBuffer.commit()
    }
}
