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

    func resize(on view: MTKView, to size: CGSize) {
        if !updatesViewPort {
            strokeRenderPass.resize(on: view, to: size, with: self)
            graphicRenderPass.resize(on: view, to: size, with: self)
            cacheRenderPass.resize(on: view, to: size, with: self)
        }
        viewPortRenderPass.resize(on: view, to: size, with: self)
        redrawsGraphicRender = true
    }

    func draw(in view: MTKView, on canvas: Canvas) {
        if !updatesViewPort {
            strokeRenderPass.eraserRenderPass = eraserRenderPass
            graphicRenderPass.photoRenderPass = photoRenderPass
            graphicRenderPass.strokeRenderPass = strokeRenderPass
            graphicRenderPass.eraserRenderPass = eraserRenderPass
            graphicRenderPass.draw(on: canvas, with: self)
        }

        cacheRenderPass.clearsTexture = graphicRenderPass.clearsTexture
        cacheRenderPass.photoRenderPass = photoRenderPass
        cacheRenderPass.strokeRenderPass = strokeRenderPass
        cacheRenderPass.eraserRenderPass = eraserRenderPass
        cacheRenderPass.graphicTexture = graphicRenderPass.graphicTexture
        cacheRenderPass.graphicPipelineState = graphicRenderPass.graphicPipelineState
        cacheRenderPass.draw(on: canvas, with: self)

        viewPortRenderPass.descriptor = view.currentRenderPassDescriptor
        viewPortRenderPass.cacheTexture = cacheRenderPass.cacheTexture
        viewPortRenderPass.draw(on: canvas, with: self)
    }
}
