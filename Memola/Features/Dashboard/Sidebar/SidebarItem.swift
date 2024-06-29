//
//  SidebarItem.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import Foundation

enum SidebarItem: String, Identifiable, Hashable, Equatable {
    var id: String { rawValue }

    case memos
    case trash

    var title: String {
        switch self {
        case .memos:
            "Memos"
        case .trash:
            "Trash"
        }
    }

    var icon: String {
        switch self {
        case .memos:
            "rectangle.3.group"
        case .trash:
            "trash"
        }
    }

    static let all: [SidebarItem] = [.memos, .trash]
}
