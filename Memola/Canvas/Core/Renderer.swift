//
//  Renderer.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

final class Renderer {
    var device: MTLDevice
    var library: MTLLibrary
    var pixelFormat: MTLPixelFormat
    var commandQueue: MTLCommandQueue

    var redrawsGraphicRender: Bool = true
    var updatesViewPort: Bool = false

    var canvasView: MTKView

    lazy var strokeRenderPass: StrokeRenderPass = {
        StrokeRenderPass(renderer: self)
    }()
    lazy var eraserRenderPass: EraserRenderPass = {
        EraserRenderPass(renderer: self)
    }()
    lazy var photoRenderPass: PhotoRenderPass = {
        PhotoRenderPass(renderer: self)
    }()
    lazy var graphicRenderPass: GraphicRenderPass = {
        GraphicRenderPass(renderer: self)
    }()
    lazy var cacheRenderPass: CacheRenderPass = {
        CacheRenderPass(renderer: self)
    }()
    lazy var viewPortRenderPass: ViewPortRenderPass = {
        ViewPortRenderPass(renderer: self)
    }()
    lazy var photoBackgroundRenderPass: PhotoBackgroundRenderPass = {
        PhotoBackgroundRenderPass(renderer: self)
    }()
    lazy var previewRenderPass: PreviewRenderPass = {
        PreviewRenderPass(renderer: self)
    }()

    init(canvasView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("[Error]: Unable to create system default device.")
        }
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("[Error]: Unable to create command queue.")
        }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("[Error]: Unable to create default library.")
        }
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
        self.pixelFormat = canvasView.colorPixelFormat
        self.canvasView = canvasView
        canvasView.device = device
        self.viewPortRenderPass.view = canvasView
    }

    func setUpdatesViewPort(_ value: Bool) {
        updatesViewPort = value
    }

    func setRedrawsGraphicRender() {
        redrawsGraphicRender = true
    }

    func resize(on view: MTKView, to size: CGSize) {
        photoBackgroundRenderPass.resize(on: view, to: size, with: self)
        strokeRenderPass.resize(on: view, to: size, with: self)
        graphicRenderPass.resize(on: view, to: size, with: self)
        cacheRenderPass.resize(on: view, to: size, with: self)
        viewPortRenderPass.resize(on: view, to: size, with: self)
        setRedrawsGraphicRender()
    }

    func draw(in view: MTKView, on canvas: Canvas) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("[Memola] - Unable to create command buffer")
            return
        }
        if !updatesViewPort {
            strokeRenderPass.eraserRenderPass = eraserRenderPass
            graphicRenderPass.photoRenderPass = photoRenderPass
            graphicRenderPass.strokeRenderPass = strokeRenderPass
            graphicRenderPass.eraserRenderPass = eraserRenderPass
            graphicRenderPass.photoBackgroundRenderPass = photoBackgroundRenderPass
            graphicRenderPass.draw(into: commandBuffer, on: canvas, with: self)
        }

        cacheRenderPass.clearsTexture = graphicRenderPass.clearsTexture
        cacheRenderPass.photoRenderPass = photoRenderPass
        cacheRenderPass.strokeRenderPass = strokeRenderPass
        cacheRenderPass.eraserRenderPass = eraserRenderPass
        cacheRenderPass.graphicTexture = graphicRenderPass.graphicTexture
        cacheRenderPass.graphicPipelineState = graphicRenderPass.graphicPipelineState
        cacheRenderPass.draw(into: commandBuffer, on: canvas, with: self)

        viewPortRenderPass.descriptor = view.currentRenderPassDescriptor
        viewPortRenderPass.excludesPhotoBackground = photoBackgroundRenderPass.clearsTexture
        viewPortRenderPass.excludesGraphic = cacheRenderPass.clearsTexture
        viewPortRenderPass.photoBackgroundTexture = photoBackgroundRenderPass.photoBackgroundTexture
        viewPortRenderPass.cacheTexture = cacheRenderPass.cacheTexture
        viewPortRenderPass.draw(into: commandBuffer, on: canvas, with: self)
    }

    func drawPreview(on canvas: Canvas) -> Platform.Image? {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("[Memola] - Unable to create command buffer for preview")
            return nil
        }
        strokeRenderPass.eraserRenderPass = eraserRenderPass
        previewRenderPass.photoRenderPass = photoRenderPass
        previewRenderPass.strokeRenderPass = strokeRenderPass
        previewRenderPass.eraserRenderPass = eraserRenderPass
        previewRenderPass.draw(into: commandBuffer, on: canvas, with: self)

        guard let cgImage = previewRenderPass.previewTexture?.getImage() else {
            return nil
        }
        #if os(macOS)
        return NSImage(cgImage: cgImage, size: .init(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))).flipped(flipVertically: true)
        #else
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .downMirrored)
        #endif
    }
}
