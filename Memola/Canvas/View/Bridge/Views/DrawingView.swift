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

    var beganTouches: Set<UITouch> = []

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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch Began - \(touches.count) & \(event?.allTouches?.count ?? -1)")
        super.touchesBegan(touches, with: event)
        for touch in touches {
            beganTouches.insert(touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch Moved - \(beganTouches.count) & \(event?.allTouches?.count ?? -1)")
        super.touchesMoved(touches, with: event)
        validateTouch()
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchMoved(to: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch Ended - \(beganTouches.count)")
        super.touchesEnded(touches, with: event)
        validateTouch()
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        touchEnded(at: point)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touch Cancelled - \(beganTouches.count)")
        super.touchesCancelled(touches, with: event)
        touchCancelled()
    }

//    func didCreateNewStroke() -> Bool {
//        switch beganTouches.count {
//        case 0:
//            return true
//        case 1:
//            if canvas.graphicContext.currentStroke == nil {
//                guard let touch = beganTouches.first else { return false }
//                let point = touch.location(in: self)
//                touchBegan(at: point)
//                beganTouches.removeAll()
//                return true
//            } else {
//                touchCancelled()
//                return false
//            }
//        default:
//            return false
//        }
//    }

    func validateTouch() {
        if beganTouches.count == 1 {
            if canvas.graphicContext.currentStroke == nil {
                guard let touch = beganTouches.first else { return }
                let point = touch.location(in: self)
                touchBegan(at: point)
                beganTouches.removeAll()
            } else {
                touchCancelled()
            }
        }
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
        renderView.draw()
    }

    func touchEnded(at point: CGPoint) {
        guard !disablesUserInteraction else { return }
        canvas.endTouch(at: point.muliply(by: ratio))
        renderView.draw()
        beganTouches.removeAll()
    }

    func touchCancelled() {
        if canvas.graphicContext.currentStroke != nil {
            canvas.cancelTouch()
            renderView.draw()
            history.restoreUndo()
        }
        beganTouches.removeAll()
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
