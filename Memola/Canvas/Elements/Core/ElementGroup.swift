//
//  ElementGroup.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/21/24.
//

import Foundation

class ElementGroup {
    var elements: [Element] = []
    var type: ElementGroupType

    init(_ element: Element) {
        elements = [element]
        type = element.elementGroupType
    }

    var isEmpty: Bool { elements.isEmpty }

    func add(_ element: Element) {
        elements.append(element)
    }

    func isSameElement(_ element: Element) -> Bool {
        guard let last = elements.last else { return false }
        return element ^= last
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
