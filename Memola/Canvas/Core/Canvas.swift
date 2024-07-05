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
    var object: CanvasObject?

    let pointGridContext = PointGridContext()
    let lineGridContext = LineGridContext()
    var graphicContext = GraphicContext()
    let viewPortContext = ViewPortContext()

    let maximumZoomScale: CGFloat = 35
    let minimumZoomScale: CGFloat = 8
    let defaultZoomScale: CGFloat = 20

    var transform: simd_float4x4 = .init()
    var previewTransform: simd_float4x4 = .init()
    var clipBounds: CGRect = .zero
    var bounds: CGRect = .zero
    var uniformsBuffer: MTLBuffer?

    @Published var state: State = .initial
    @Published var zoomScale: CGFloat = .zero
    @Published var locksCanvas: Bool = false

    @Published var gridMode: GridMode = .point

    let zoomPublisher = PassthroughSubject<CGFloat, Never>()

    weak var renderer: Renderer?

    init(size: CGSize, canvasID: NSManagedObjectID, gridMode: Int16) {
        self.size = size
        self.canvasID = canvasID
        self.gridMode = GridMode(rawValue: gridMode) ?? .point
    }

    var hasValidStroke: Bool {
        if let currentElement = graphicContext.currentElement {
            return Date.now.timeIntervalSince(currentElement.createdAt) * 1000 > 80
        }
        return false
    }
}

// MARK: - Actions
extension Canvas {
    func load() {
        withPersistence(\.backgroundContext) { [weak self, canvasID, bounds] context in
            DispatchQueue.main.async { [weak self] in
                self?.state = .loading
            }
            guard let canvas = context.object(with: canvasID) as? CanvasObject else {
                return
            }
            self?.object = canvas
            let graphicContext = canvas.graphicContext
            self?.graphicContext.object = graphicContext
            self?.graphicContext.loadStrokes(bounds)
            context.refresh(canvas, mergeChanges: false)
            DispatchQueue.main.async { [weak self] in
                self?.state = .loaded
            }
        }
    }

    func loadStrokes(_ bounds: CGRect) {
        withPersistence(\.backgroundContext) { [weak self, bounds] context in
            self?.graphicContext.loadQuads(bounds, on: context)
            context.refreshAllObjects()
        }
    }

    func save(for memoObject: MemoObject, completion: @escaping () -> Void) {
        state = .closing
        let previewImage = renderer?.drawPreview(on: self)
        memoObject.preview = previewImage?.jpegData(compressionQuality: 0.8)
        withPersistenceSync(\.viewContext) { context in
            try context.saveIfNeeded()
        }
        withPersistence(\.backgroundContext) { [weak self] context in
            try context.saveIfNeeded()
            context.refreshAllObjects()
            DispatchQueue.main.async { [weak self] in
                self?.state = .closed
                completion()
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

    func updatePreviewTransform(to targetRect: CGRect) {
        let bounds = CGRect(origin: .zero, size: size)
        let translationTransform = CGAffineTransform(translationX: -targetRect.origin.x, y: -targetRect.origin.y)

        let scaleX = bounds.width / targetRect.width
        let scaleY = bounds.height / targetRect.height
        let scalingTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        let combinedTransform = translationTransform.concatenating(scalingTransform)

        let normalizeX = CGAffineTransform(scaleX: 1.0 / bounds.width, y: 1.0)
        let normalizeY = CGAffineTransform(scaleX: 1.0, y: 1.0 / bounds.height)
        let normalizeTransform = normalizeX.concatenating(normalizeY)

        let normalizedTransform = combinedTransform.concatenating(normalizeTransform)

        let renderScale = CGAffineTransform(scaleX: 2.0, y: 2.0)
        let renderTranslation = CGAffineTransform(translationX: -1.0, y: -1.0)
        let transform = normalizedTransform.concatenating(renderScale).concatenating(renderTranslation)

        self.previewTransform = simd_float4x4(transform)
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
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.zoomScale = min(max(zoomScale, minimumZoomScale), maximumZoomScale)
        }
    }
}

// MARK: - Grid Mode
extension Canvas {
    func setGridMode(_ gridMode: GridMode) {
        guard self.gridMode != gridMode else { return }
        self.gridMode = gridMode
        withPersistence(\.backgroundContext) { [weak object] context in
            object?.gridMode = gridMode.rawValue
            try context.saveIfNeeded()
        }
    }
}

// MARK: - Stroke
extension Canvas {
    func beginTouch(at point: CGPoint, pen: Pen) -> any Stroke {
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
}

// MARK: - Photo
extension Canvas {
    func insertPhoto(at point: CGPoint, photoItem: PhotoItem) -> Photo {
        graphicContext.insertPhoto(at: point, photoItem: photoItem)
    }
}

// MARK: - Rendering
extension Canvas {
    func renderPointGrid(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = GridUniforms(
            ratio: size.width.float / 100,
            zoom: zoomScale.float,
            transform: transform
        )
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<GridUniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        pointGridContext.draw(device: device, renderEncoder: renderEncoder)
    }

    func renderLineGrid(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = GridUniforms(
            ratio: size.width.float / 100,
            zoom: zoomScale.float,
            transform: transform
        )
        uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<GridUniforms>.size)
        renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 11)
        lineGridContext.draw(device: device, renderEncoder: renderEncoder)
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

    func setPreviewUniformsBuffer(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        var uniforms = Uniforms(transform: previewTransform)
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
