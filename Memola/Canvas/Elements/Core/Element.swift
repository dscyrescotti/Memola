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
}
