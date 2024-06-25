//
//  GridMode.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/25/24.
//

import Foundation

enum GridMode: Int16, Equatable {
    case none
    case point
    case line

    var title: String {
        switch self {
        case .none:
            return "No Grid"
        case .point:
            return "Point Grid"
        case .line:
            return "Line Grid"
        }
    }

    var icon: String {
        switch self {
        case .none:
            return "square.slash"
        case .point:
            return "circle.grid.3x3.fill"
        case .line:
            return "squareshape.split.3x3"
        }
    }

    static let all: [GridMode] = [.none, .point, line]
}
