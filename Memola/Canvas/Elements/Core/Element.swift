//
//  Element.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/12/24.
//

import Foundation

enum Element: Equatable, Comparable {
    case stroke(AnyStroke)
    case photo(Photo)

    func stroke() -> (any Stroke)? {
        guard case let .stroke(anyStroke) = self else {
            return nil
        }
        return anyStroke.value
    }

    func stroke<S: Stroke>(as type: S.Type) -> S? {
        guard case let .stroke(anyStroke) = self else {
            return nil
        }
        return anyStroke.stroke(as: type)
    }

    func photo() -> Photo? {
        guard case let .photo(photo) = self else {
            return nil
        }
        return photo
    }

    var createdAt: Date {
        switch self {
        case .stroke(let anyStroke):
            anyStroke.value.createdAt
        case .photo(let photo):
            photo.createdAt
        }
    }

    var elementGroupType: ElementGroup.ElementGroupType {
        switch self {
        case .stroke(let anyStroke):
            switch anyStroke.value.style {
            case .marker: return .stroke
            case .eraser: return .eraser
            }
        case .photo:
            return .photo
        }
    }

    static func < (lhs: Element, rhs: Element) -> Bool {
        switch (lhs, rhs) {
        case let (.stroke(leftStroke), .stroke(rightStroke)):
            leftStroke < rightStroke
        case let (.photo(leftPhoto), .photo(rightPhoto)):
            leftPhoto < rightPhoto
        case let (.photo(photo), .stroke(stroke)):
            photo.createdAt < stroke.value.createdAt
        case let (.stroke(stroke), .photo(photo)):
            stroke.value.createdAt < photo.createdAt
        }
    }

    static func ^= (lhs: Element, rhs: Element) -> Bool {
        switch (lhs, rhs) {
        case let (.stroke(leftStroke), .stroke(rightStroke)):
            leftStroke ^= rightStroke
        case let (.photo(leftPhoto), .photo(rightPhoto)):
            leftPhoto == rightPhoto
        default:
            false
        }
    }
}
