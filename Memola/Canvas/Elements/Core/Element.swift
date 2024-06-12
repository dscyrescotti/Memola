//
//  Element.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/12/24.
//

import Foundation

enum Element: Equatable, Comparable {
    case stroke(AnyStroke)
    case photo

    func stroke<S: Stroke>(as type: S.Type) -> S? {
        guard case let .stroke(anyStroke) = self else {
            return nil
        }
        return anyStroke.stroke(as: type)
    }
}
