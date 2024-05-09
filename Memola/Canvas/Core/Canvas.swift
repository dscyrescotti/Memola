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

@objc(Canvas)
final class Canvas: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var width: CGFloat
    @NSManaged var height: CGFloat
    @NSManaged var memo: Memo?
    @NSManaged var graphicContext: GraphicContext

    let gridContext = GridContext()
    let viewPortContext = ViewPortContext()
    let maximumZoomScale: CGFloat = 25
    let minimumZoomScale: CGFloat = 3.1

    var transform: simd_float4x4 = .init()
    var clipBounds: CGRect = .zero
    var zoomScale: CGFloat = .zero
    var uniformsBuffer: MTLBuffer?

    @Published var state: State = .initial

    var size: CGSize { CGSize(width: width, height: height) }
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
        state = .loading
        let start = Date().formatted(.dateTime.minute().second().secondFraction(.fractional(5)))
        Task(priority: .high) { [start] in
            await withTaskGroup(of: Void.self) { taskGroup in
                for stroke in graphicContext.strokes {
                    guard let stroke = stroke as? Stroke else { continue }
                    taskGroup.addTask {
                        stroke.loadVertices()
                    }
                }
            }

            let end = Date().formatted(.dateTime.minute().second().secondFraction(.fractional(5)))
            NSLog("[Memola] - Loaded from \(start) to \(end)")
            await MainActor.run {
                state = .loaded
            }
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
        graphicContext.strokes.lastObject as? Stroke
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
