//
//  AnyStroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/5/24.
//

import Foundation

struct AnyStroke: Equatable, Comparable {
    var value: any Stroke

    init(_ value: any Stroke) {
        self.value = value
    }

    static func == (lhs: AnyStroke, rhs: AnyStroke) -> Bool {
        lhs.value.id == rhs.value.id
    }

    static func < (lhs: AnyStroke, rhs: AnyStroke) -> Bool {
        lhs.value.createdAt < rhs.value.createdAt
    }

    func stroke<S: Stroke>(as type: S.Type) -> S? {
        value.stroke(as: type)
    }
}
