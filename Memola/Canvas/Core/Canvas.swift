//
//  Canvas.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import CoreData
import MetalKit
import Foundation

final class Canvas: ObservableObject, Identifiable, @unchecked Sendable {
    let size: CGSize
    let canvasID: NSManagedObjectID

    let gridContext = GridContext()
    var graphicContext = GraphicContext()
    let viewPortContext = ViewPortContext()

    let maximumZoomScale: CGFloat = 30
    let minimumZoomScale: CGFloat = 5
    let defaultZoomScale: CGFloat = 20

    var transform: simd_float4x4 = .init()
    var clipBounds: CGRect = .zero
    var zoomScale: CGFloat = .zero
    var bounds: CGRect = .zero
    var uniformsBuffer: MTLBuffer?

    init(size: CGSize, canvasID: NSManagedObjectID) {
        self.size = size
        self.canvasID = canvasID
    }

    @Published var state: State = .initial

    var hasValidStroke: Bool {
        if let currentStroke = graphicContext.currentStroke {
            return Date.now.timeIntervalSince(currentStroke.createdAt) * 1000 > 80
        }
        return false
    }
}

// MARK: - Actions
extension Canvas {
    func load() {
        withPersistence(\.backgroundContext) { [weak self, canvasID, bounds] context in
            DispatchQueue.main.async { [weak self] in
                NSLog(Date().formatted(.dateTime.minute().second().secondFraction(.fractional(2))))
                self?.state = .loading
            }
            guard let canvas = context.object(with: canvasID) as? CanvasObject else {
                return
            }
            let graphicContext = canvas.graphicContext
            self?.graphicContext.object = graphicContext
            self?.graphicContext.loadStrokes(bounds)
            context.refresh(canvas, mergeChanges: false)
            DispatchQueue.main.async { [weak self] in
                NSLog(Date().formatted(.dateTime.minute().second().secondFraction(.fractional(2))))
                self?.state = .loaded
            }
        }
    }

    func loadStrokes(_ bounds: CGRect) {
        withPersistence(\.backgroundContext) { [weak self, bounds] context in
            self?.graphicContext.loadQuads(bounds)
        }
    }
}

// MARK: - Dimension
extension Canvas {
    func updateTransform(on drawingView: DrawingView) {
        let bounds = CGRect(origin: .zero, size: size)
        let renderView = drawingView.renderView
        let targetRect = drawingView.convert(drawingView.bounds, to: renderView)
        let transform1 = bounds.transform(to: targetRect)
        let transform2 = renderView.bounds.transform(to: CGRect(x: -1.0, y: -1.0, width: 2.0, height: 2.0))
        let transform3 = CGAffineTransform.identity.translatedBy(x: 0, y: 1).scaledBy(x: 1, y: -1).translatedBy(x: 0, y: 1)
        self.transform = simd_float4x4(transform1 * transform2 * transform3)
    }

    func updateClipBounds(_ scrollView: UIScrollView, on drawingView: DrawingView) {
        let ratio = drawingView.ratio
        let bounds = scrollView.convert(scrollView.bounds, to: drawingView)
        clipBounds = CGRect(origin: bounds.origin.muliply(by: ratio), size: bounds.size.multiply(by: ratio))
    }
}

// MARK: - Zoom Scale
extension Canvas {
    func setZoomScale(_ zoomScale: CGFloat) {
        self.zoomScale = zoomScale
    }
}

// MARK: - Graphic Context
extension Canvas {
    func beginTouch(at point: CGPoint, pen: Pen) -> Stroke {
        graphicContext.beginStroke(at: point, pen: pen)
    }

    func moveTouch(to point: CGPoint) {
        graphicContext.appendStroke(with: point)
    }

    func endTouch(at point: CGPoint) {
        graphicContext.endStroke(at: point)
    }

    func cancelTouch() {
        graphicContext.cancelStroke()
    }

    func setGraphicRenderType(_ renderType: GraphicContext.RenderType) {
        graphicContext.renderType = renderType
    }

    func getNewlyAddedStroke() -> Stroke? {
        graphicContext.strokes.last
    }
}

// MARK: - Rendering
extension Canvas {
    func renderGrid(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = GridUniforms(
            ratio: size.width.float / 100,
            zoom: zoomScale.float,
            transform: transform
        )
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<GridUniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        gridContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderGraphic(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        graphicContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderViewPort(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        viewPortContext.setViewPortVertices()
        viewPortContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderViewPortUpdate(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = Uniforms(transform: transform)
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        viewPortContext.setViewPortUpdateVertices(from: clipBounds)
        viewPortContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func setUniformsBuffer(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = Uniforms(transform: transform)
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
    }
}

// MARK: - State
extension Canvas {
    enum State {
        case initial
        case loading
        case loaded
        case closing
        case closed
        case failed
    }
}
