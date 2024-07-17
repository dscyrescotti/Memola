//
//  DrawingView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import MetalKit
import Foundation

final class DrawingView: Platform.View {
    private let tool: Tool
    private let canvas: Canvas
    private let history: History
    let renderView: MTKView

    var ratio: CGFloat { canvas.size.width / bounds.width }

    private var disablesUserInteraction: Bool = false
    private var lastDrawTime: CFTimeInterval = 0
    private let minDrawInterval: CFTimeInterval = 1.0 / 60.0

    #if os(macOS)
    var isUserInteractionEnabled: Bool = true
    #endif

    required init(tool: Tool, canvas: Canvas, history: History) {
        self.tool = tool
        self.canvas = canvas
        self.history = history
        self.renderView = MTKView(frame: .zero)
        super.init(frame: .zero)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDrawableSize(with size: CGSize) {
        renderView.drawableSize = size.multiply(by: 2)
    }
    
    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        let pointInLeftBottomOrigin = convert(event.locationInWindow, from: nil)
        let point = CGPoint(x: pointInLeftBottomOrigin.x, y: bounds.height - pointInLeftBottomOrigin.y)
        touchBegan(at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        let pointInLeftBottomOrigin = convert(event.locationInWindow, from: nil)
        let point = CGPoint(x: pointInLeftBottomOrigin.x, y: bounds.height - pointInLeftBottomOrigin.y)
        touchMoved(to: point)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        let pointInLeftBottomOrigin = convert(event.locationInWindow, from: nil)
        let point = CGPoint(x: pointInLeftBottomOrigin.x, y: bounds.height - pointInLeftBottomOrigin.y)
        touchEnded(at: point)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        isUserInteractionEnabled ? super.hitTest(point) : nil
    }
    #else
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        !canvas.hasValidStroke
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if !canvas.hasValidStroke, let count = event?.allTouches?.count, count > 1 {
            touchCancelled()
            return
        }
        guard let touch = touches.first else { return }
        let point = touch.preciseLocation(in: self)
        touchBegan(at: point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if !canvas.hasValidStroke, let count = event?.allTouches?.count, count > 1 {
            touchCancelled()
            return
        }
        guard let touch = touches.first else { return }
        if let _touch = event?.coalescedTouches(for: touch)?.last {
            let point = _touch.preciseLocation(in: self)
            touchMoved(to: point)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.preciseLocation(in: self)
        touchEnded(at: point)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.preciseLocation(in: self)
        touchEnded(at: point)
    }
    #endif

    func touchBegan(at point: CGPoint) {
        guard !disablesUserInteraction else { return }
        guard let pen = tool.selectedPen else { return }
        let stroke = canvas.beginTouch(at: point.muliply(by: ratio), pen: pen)
        history.addUndo(.stroke(stroke))
        history.resetRedo()
    }

    func touchMoved(to point: CGPoint) {
        guard !disablesUserInteraction else { return }
        canvas.moveTouch(to: point.muliply(by: ratio))
        if canvas.hasValidStroke {
            let currentTime = CACurrentMediaTime()
            if currentTime - lastDrawTime < minDrawInterval {
                return
            }
            lastDrawTime = currentTime
            draw()
        }
    }

    func touchEnded(at point: CGPoint) {
        guard !disablesUserInteraction else { return }
        canvas.endTouch(at: point.muliply(by: ratio))
        draw()
    }

    func touchCancelled() {
        if canvas.graphicContext.currentElement != nil {
            canvas.cancelTouch()
            draw()
            history.restoreUndo()
        }
    }

    func disableUserInteraction() {
        disablesUserInteraction = true
    }

    func enableUserInteraction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.disablesUserInteraction = false
        }
    }

    func draw() {
        renderView.draw()
    }
}
