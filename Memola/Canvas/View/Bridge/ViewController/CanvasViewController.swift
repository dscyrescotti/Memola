//
//  CanvasViewController.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import SwiftUI
import MetalKit
import Foundation

class CanvasViewController: Platform.ViewController {
    let drawingView: DrawingView
    let scrollView: Platform.ScrollView = Platform.ScrollView()
    var renderView: MTKView {
        drawingView.renderView
    }

    var photoInsertGesture: Platform.TapGestureRecognizer?

    let tool: Tool
    let canvas: Canvas
    let history: History
    let renderer: Renderer

    var cancellables: Set<AnyCancellable> = []

    init(tool: Tool, canvas: Canvas, history: History) {
        self.tool = tool
        self.canvas = canvas
        self.history = history
        self.drawingView = DrawingView(tool: tool, canvas: canvas, history: history)
        self.renderer = Renderer(canvasView: drawingView.renderView)
        super.init(nibName: nil, bundle: nil)
        self.canvas.renderer = renderer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        configureGestures()
        configureListeners()
    }

    #if os(macOS)
    override func viewWillAppear() {
        super.viewWillAppear()
        resizeDocumentView()
        updateDocumentBounds()
        loadMemo()
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        drawingView.disableUserInteraction()
        drawingView.updateDrawableSize(with: view.frame.size)
        renderer.resize(on: renderView, to: renderView.drawableSize)
        renderView.draw()
        drawingView.enableUserInteraction()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        history.resetRedo()
    }
    #else
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resizeDocumentView()
        updateDocumentBounds()
        loadMemo()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawingView.disableUserInteraction()
        drawingView.updateDrawableSize(with: view.frame.size)
        renderer.resize(on: renderView, to: renderView.drawableSize)
        renderView.draw()
        drawingView.enableUserInteraction()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        history.resetRedo()
    }
    #endif
}

extension CanvasViewController {
    func configureViews() {
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        view.backgroundColor = .white

        renderView.autoResizeDrawable = false
        renderView.enableSetNeedsDisplay = true
        renderView.translatesAutoresizingMaskIntoConstraints = false
        renderView.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        view.addSubview(renderView)
        NSLayoutConstraint.activate([
            renderView.topAnchor.constraint(equalTo: view.topAnchor),
            renderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            renderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            renderView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        scrollView.maximumZoomScale = canvas.maximumZoomScale
        scrollView.minimumZoomScale = canvas.minimumZoomScale
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.delegate = self
        scrollView.backgroundColor = .clear

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        scrollView.addSubview(drawingView)
        drawingView.backgroundColor = .clear
        drawingView.isUserInteractionEnabled = false
        #endif
    }

    func resizeDocumentView(to newSize: CGSize? = nil) {
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        scrollView.layoutIfNeeded()

        let size = canvas.size
        let widthScale = (newSize?.width ?? view.frame.width) / size.width
        let heightScale = (newSize?.height ?? view.frame.height) / size.height
        let scale = max(widthScale, heightScale)

        let width = size.width * scale
        let height = size.height * scale
        let newFrame = CGRect(x: 0, y: 0, width: width, height: height)
        drawingView.frame = newFrame

        scrollView.setZoomScale(canvas.defaultZoomScale, animated: true)
        centerDocumentView(to: newSize)

        let offsetX = (newFrame.width * canvas.defaultZoomScale - view.frame.width) / 2
        let offsetY = (newFrame.height * canvas.defaultZoomScale - view.frame.height) / 2

        let point = CGPoint(x: offsetX, y: offsetY)
        scrollView.setContentOffset(point, animated: true)

        drawingView.updateDrawableSize(with: view.frame.size)
        #endif
    }

    func centerDocumentView(to newSize: CGSize? = nil) {
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        let documentViewSize = drawingView.frame.size
        let scrollViewSize = newSize ?? view.frame.size
        let verticalPadding = documentViewSize.height < scrollViewSize.height ? (scrollViewSize.height - documentViewSize.height) / 2 : 0
        let horizontalPadding = documentViewSize.width < scrollViewSize.width ? (scrollViewSize.width - documentViewSize.width) / 2 : 0
        self.scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
        #endif
    }

    func updateDocumentBounds() {
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        var bounds = scrollView.bounds.muliply(by: drawingView.ratio / scrollView.zoomScale)
        let xDelta = bounds.minX * 0.0
        let yDelta = bounds.minY * 0.0
        bounds.origin.x -= xDelta
        bounds.origin.y -= yDelta
        bounds.size.width += xDelta * 2
        bounds.size.height += yDelta * 2
        canvas.bounds = bounds
        if canvas.state == .loaded {
            canvas.loadStrokes(bounds)
        }
        #endif
    }
}

extension CanvasViewController {
    func configureListeners() {
        canvas.$state
            .sink { [weak self] state in
                self?.canvasStateChanged(state)
            }
            .store(in: &cancellables)
        canvas.zoomPublisher
            .sink { [weak self] zoomScale in
                self?.zoomChanged(zoomScale)
            }
            .store(in: &cancellables)
        canvas.$locksCanvas
            .sink { [weak self] state in
                self?.lockModeChanged(state)
            }
            .store(in: &cancellables)
        canvas.$gridMode
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.gridModeChanged(mode)
            }
            .store(in: &cancellables)

        tool.$selectedPen
            .sink { [weak self] pen in
                self?.penChanged(to: pen)
            }
            .store(in: &cancellables)
        tool.$selection
            .sink { [weak self] selection in
                self?.toolSelectionChanged(to: selection)
            }
            .store(in: &cancellables)

        history.historyPublisher
            .sink { [weak self] action in
                switch action {
                case .undo:
                    self?.historyUndid()
                case .redo:
                    self?.historyRedid()
                }
            }
            .store(in: &cancellables)
    }
}

extension CanvasViewController {
    func loadMemo() {
        tool.load()
        canvas.load()
    }

    func canvasStateChanged(_ state: Canvas.State) {
        guard state == .loaded else { return }
        renderView.delegate = self
        renderer.resize(on: renderView, to: renderView.drawableSize)
        renderView.draw()
    }
}

extension CanvasViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func draw(in view: MTKView) {
        guard view.drawableSize != .zero else {
            return
        }
        canvas.updateTransform(on: drawingView)
        renderer.draw(in: view, on: canvas)
    }
}

extension CanvasViewController {
    func configureGestures() {
        let photoInsertGesture = Platform.TapGestureRecognizer(target: self, action: #selector(recognizeTapGesture))
        #if os(macOS)
        photoInsertGesture.numberOfClicksRequired = 1
        #else
        photoInsertGesture.numberOfTapsRequired = 1
        #endif
        self.photoInsertGesture = photoInsertGesture
        scrollView.addGestureRecognizer(photoInsertGesture)
    }

    @objc func recognizeTapGesture(_ gesture: Platform.TapGestureRecognizer) {
        guard let photoItem = tool.selectedPhotoItem else { return }
        withAnimation {
            tool.selectedPhotoItem = nil
        }
        let point = gesture.location(in: drawingView)
        let photo = canvas.insertPhoto(at: point.muliply(by: drawingView.ratio), photoItem: photoItem)
        history.addUndo(.photo(photo))
        drawingView.draw()
    }
}

#if os(macOS)
#else
extension CanvasViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        drawingView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        magnificationStarted()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        canvas.setZoomScale(scrollView.zoomScale)
        renderView.draw()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        updateDocumentBounds()
        centerDocumentView()
        magnificationEnded()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        draggingStarted()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        renderView.draw()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !scrollView.isTracking, !scrollView.isDragging, !scrollView.isDecelerating {
            scrollViewDidEndScrolling(scrollView)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, scrollView.isTracking, !scrollView.isDragging, !scrollView.isDecelerating {
            scrollViewDidEndScrolling(scrollView)
        }
    }

    func scrollViewDidEndScrolling(_ scrollView: UIScrollView) {
        updateDocumentBounds()
        draggingEnded()
    }
}
#endif

extension CanvasViewController {
    func magnificationStarted() {
        guard !renderer.updatesViewPort else { return }
        drawingView.touchCancelled()
        canvas.updateClipBounds(scrollView, on: drawingView)
        drawingView.disableUserInteraction()
        renderer.setUpdatesViewPort(true)
    }

    func magnificationEnded() {
        renderer.setUpdatesViewPort(false)
        renderer.setRedrawsGraphicRender()
        renderView.draw()
        drawingView.enableUserInteraction()
    }

    func draggingStarted() {
        guard !renderer.updatesViewPort else { return }
        canvas.updateClipBounds(scrollView, on: drawingView)
        drawingView.disableUserInteraction()
        renderer.setUpdatesViewPort(true)
    }

    func draggingEnded() {
        renderer.setUpdatesViewPort(false)
        renderer.setRedrawsGraphicRender()
        renderView.draw()
        drawingView.enableUserInteraction()
    }
}

extension CanvasViewController {
    func penChanged(to pen: Pen?) {
        if let pen, let device = drawingView.renderView.device {
            pen.style.loadTexture(on: device)
        }
    }

    func toolSelectionChanged(to selection: ToolSelection) {
        let enablesScrolling: Bool
        let enablesDrawing: Bool
        let enablesPhotoInsertion: Bool
        switch selection {
        case .hand:
            enablesScrolling = true
            enablesDrawing = false
            enablesPhotoInsertion = false
        case .pen:
            enablesScrolling = false
            enablesDrawing = true
            enablesPhotoInsertion = false
            penChanged(to: tool.selectedPen)
        case .photo:
            enablesScrolling = true
            enablesDrawing = false
            enablesPhotoInsertion = true
        }
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        scrollView.isScrollEnabled = enablesScrolling
        drawingView.isUserInteractionEnabled = enablesDrawing
        photoInsertGesture?.isEnabled = enablesPhotoInsertion
        enablesDrawing ? drawingView.enableUserInteraction() : drawingView.disableUserInteraction()
        #endif
    }
}

extension CanvasViewController {
    func zoomChanged(_ zoomScale: CGFloat) {
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        scrollView.setZoomScale(zoomScale, animated: true)
        #endif
    }

    func lockModeChanged(_ state: Bool) {
        #if os(macOS)
        #warning("TODO: implement for macos")
        #else
        scrollView.pinchGestureRecognizer?.isEnabled = !state
        #endif
    }

    func gridModeChanged(_ mode: GridMode) {
        drawingView.disableUserInteraction()
        renderer.setRedrawsGraphicRender()
        renderView.draw()
        drawingView.enableUserInteraction()
    }
}

extension CanvasViewController {
    func historyUndid() {
        guard let event = history.undo() else { return }
        drawingView.disableUserInteraction()
        canvas.graphicContext.undoGraphic(for: event)
        renderer.setRedrawsGraphicRender()
        renderView.draw()
        drawingView.enableUserInteraction()
    }

    func historyRedid() {
        guard let event = history.redo() else { return }
        drawingView.disableUserInteraction()
        canvas.graphicContext.redoGraphic(for: event)
        renderer.setRedrawsGraphicRender()
        renderView.draw()
        drawingView.enableUserInteraction()
    }
}
