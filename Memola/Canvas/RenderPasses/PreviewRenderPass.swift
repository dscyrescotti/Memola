//
//  PreviewRenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/4/24.
//

import MetalKit
import Foundation

final class PreviewRenderPass: RenderPass {
    var label: String = "Preview Render Pass"
    
    var descriptor: MTLRenderPassDescriptor?
    var previewPipelineState: MTLRenderPipelineState?
    var previewTexture: MTLTexture?

    weak var photoRenderPass: PhotoRenderPass?
    weak var strokeRenderPass: StrokeRenderPass?
    weak var eraserRenderPass: EraserRenderPass?

    init(renderer: Renderer) {
        descriptor = MTLRenderPassDescriptor()
        previewPipelineState = renderer.graphicRenderPass.graphicPipelineState
    }

    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer) { }

    @discardableResult
    func draw(into commandBuffer: any MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool {
        let tree = canvas.graphicContext.tree
        if !tree.isEmpty {
            var elementGroups: [ElementGroup] = []
            let start = Date.now.timeIntervalSince1970 * 1000
            var bounds: [CGFloat] = []
            for _element in tree.traverse() {
                if bounds.isEmpty {
                    bounds = [
                        _element.box.minX,
                        _element.box.minY,
                        _element.box.maxX,
                        _element.box.maxY
                    ]
                } else {
                    bounds = [
                        min(_element.box.minX, bounds[0]),
                        min(_element.box.minY, bounds[1]),
                        max(_element.box.maxX, bounds[2]),
                        max(_element.box.maxY, bounds[3])
                    ]
                }
                if elementGroups.isEmpty {
                    let _elementGroup = ElementGroup(_element)
                    elementGroups.append(_elementGroup)
                } else {
                    guard let _elementGroup = elementGroups.last else { continue }
                    if _elementGroup.isSameElement(_element) {
                        _elementGroup.add(_element)
                    } else {
                        let _elementGroup = ElementGroup(_element)
                        elementGroups.append(_elementGroup)
                    }
                }
            }
            let padding: CGFloat = 20
            let origin = CGPoint(x: bounds[0] - padding, y: bounds[1] - padding)
            let size = CGSize(width: (bounds[2] - origin.x) + padding, height: (bounds[3] - origin.y) + padding)
            previewTexture = createPreviewTexture(for: size, with: renderer)
            descriptor?.colorAttachments[0].texture = previewTexture
            descriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
            descriptor?.colorAttachments[0].storeAction = .store
            descriptor?.colorAttachments[0].loadAction = .clear
            canvas.updatePreviewTransform(to: CGRect(origin: origin, size: size))
            for elementGroup in elementGroups {
                draw(for: elementGroup, into: commandBuffer, on: canvas, with: renderer)
                descriptor?.colorAttachments[0].loadAction = .load
            }
            let end = Date.now.timeIntervalSince1970 * 1000
            NSLog("[Memola] - preview duration: \(end - start)")
        }

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        return true
    }

    private func createPreviewTexture(for size: CGSize, with renderer: Renderer) -> MTLTexture? {
        let ratio = size.width / size.height
        let dimension: CGFloat = 800
        let width: CGFloat
        let height: CGFloat
        if dimension * ratio > dimension {
            height = dimension
            width = dimension * ratio
        } else {
            height = dimension / ratio
            width = dimension
        }
        return Textures.createPreviewTexture(from: renderer, size: CGSize(width: width, height: height))
    }

    private func draw(for elementGroup: ElementGroup, into commandBuffer: MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) {
        switch elementGroup.type {
        case .stroke:
            strokeRenderPass?.elementGroup = elementGroup
            strokeRenderPass?.graphicDescriptor = descriptor
            strokeRenderPass?.graphicPipelineState = previewPipelineState
            strokeRenderPass?.drawPreview(into: commandBuffer, on: canvas, with: renderer)
        case .eraser:
            eraserRenderPass?.elementGroup = elementGroup
            eraserRenderPass?.descriptor = descriptor
            eraserRenderPass?.drawPreview(into: commandBuffer, on: canvas, with: renderer)
        case .photo:
            photoRenderPass?.elementGroup = elementGroup
            photoRenderPass?.descriptor = descriptor
            photoRenderPass?.drawPreview(into: commandBuffer, on: canvas, with: renderer)
        }
    }
}
