//
//  Filter.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/27/24.
//

import Foundation

enum Filter: String, Identifiable, Hashable, Equatable {
    var id: String {
        rawValue
    }

    case none
    case favorites

    var name: String {
        switch self {
        case .none: return "All"
        case .favorites: return "Favorites"
        }
    }

    static let all: [Filter] = [.none, .favorites]
}
