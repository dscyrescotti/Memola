//
//  ElementGroup.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/21/24.
//

import Foundation

final class ElementGroup {
    #if DEBUG
    let id = UUID()
    #endif
    var elements: [Element] = []
    var type: ElementGroupType
    var eraserStrokes: Set<EraserStroke> = []

    init(_ element: Element) {
        elements = [element]
        type = element.elementGroupType
        collect(element)
    }

    var isEmpty: Bool { elements.isEmpty }

    func add(_ element: Element) {
        elements.append(element)
        collect(element)
    }

    private func collect(_ element: Element) {
        if let stroke = element.stroke(as: PenStroke.self) {
            eraserStrokes.formUnion(stroke.eraserStrokes)
        }
        #if DEBUG
        NSLog("[Memola] - \(id) eraser count - \(eraserStrokes.count)")
        #endif
    }

    func isSameElement(_ element: Element) -> Bool {
        guard let last = elements.last else { return false }
        guard element ^= last else {
            return false
        }
        if let stroke = element.stroke(as: PenStroke.self) {
            if eraserStrokes.count <= stroke.eraserStrokes.count {
                return true
            }
            return eraserStrokes.intersection(stroke.eraserStrokes).count == eraserStrokes.count
        }
        return true
    }

    func getPenStyle() -> PenStyle? {
        if case let .stroke(penStyle, _) = type {
            return penStyle
        }
        return nil
    }

    func getPenColor() -> [CGFloat]? {
        if case let .stroke(_, color) = type {
            return color
        }
        return nil
    }
}

extension ElementGroup {
    enum ElementGroupType {
        case stroke(penStyle: PenStyle, color: [CGFloat])
        case eraser
        case photo
    }
}
