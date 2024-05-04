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

    func touchBegan(on point: CGPoint) {
        guard !disablesUserInteraction else { return }
        guard let pen = tool.selectedPen else { return }
        let stroke = canvas.beginTouch(at: point.muliply(by: ratio), pen: pen)
        renderView.draw()
        history.addUndo(.stroke(stroke))
        history.resetRedo()
    }

    func touchMoved(to point: CGPoint) {
        guard !disablesUserInteraction else { return }
        canvas.moveTouch(to: point.muliply(by: ratio))
        renderView.draw()
    }

    func touchEnded(to point: CGPoint) {
        guard !disablesUserInteraction else { return }
        canvas.endTouch(at: point.muliply(by: ratio))
        renderView.draw()
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
