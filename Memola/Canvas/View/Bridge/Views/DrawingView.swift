//
//  DrawingView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import UIKit
import MetalKit
import Foundation

class DrawingView: UIView {
    let tool: Tool
    let canvas: Canvas
    let history: History
    let renderView: MTKView

    var ratio: CGFloat { canvas.size.width / bounds.width }

    private var disablesUserInteraction: Bool = false

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
        renderView.drawableSize = size.multiply(by: 2.5)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        !canvas.hasValidStroke
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchBegan(at: point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchMoved(to: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchEnded(at: point)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchEnded(at: point)
    }

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
            renderView.draw()
        }
    }

    func touchEnded(at point: CGPoint) {
        guard !disablesUserInteraction else { return }
        canvas.endTouch(at: point.muliply(by: ratio))
        renderView.draw()
    }

    func touchCancelled() {
        if canvas.graphicContext.currentStroke != nil {
            canvas.cancelTouch()
            renderView.draw()
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
}
