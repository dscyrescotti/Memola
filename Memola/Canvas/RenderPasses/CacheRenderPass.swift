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

    weak var photoRenderPass: PhotoRenderPass?
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

    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        guard let descriptor else { return false }

        // MARK: - Copying texture
        guard let graphicTexture, let cacheTexture else { return false }
        guard let cachePipelineState else { return false }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return false
        }
        computeEncoder.label = "Cache Compute Encoder"

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

        // MARK: - Drawing 
        guard let graphicPipelineState else { return false }
        descriptor.colorAttachments[0].texture = cacheTexture
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
        descriptor.colorAttachments[0].loadAction = clearsTexture ? .clear : .load
        descriptor.colorAttachments[0].storeAction = .store

        let graphicContext = canvas.graphicContext
        if let element = graphicContext.currentElement {
            let elementGroup = ElementGroup(element)
            var status: Bool?
            switch elementGroup.type {
            case .stroke:
                canvas.setGraphicRenderType(.inProgress)
                strokeRenderPass?.elementGroup = elementGroup
                strokeRenderPass?.graphicDescriptor = descriptor
                strokeRenderPass?.graphicPipelineState = graphicPipelineState
                status = strokeRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)
            case .eraser:
                eraserRenderPass?.elementGroup = elementGroup
                eraserRenderPass?.descriptor = descriptor
                status = eraserRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)
            case .photo:
                photoRenderPass?.elementGroup = elementGroup
                photoRenderPass?.descriptor = descriptor
                status = photoRenderPass?.draw(into: commandBuffer, on: canvas, with: renderer)
            }
            clearsTexture = !(status ?? false)
        }
        return true
    }
}
