//
//  Sort.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/27/24.
//

import Foundation

enum Sort: String, Identifiable, Hashable, Equatable {
    var id: String {
        rawValue
    }

    case recent
    case aToZ
    case zToA
    case newest
    case oldest

    var name: String {
        switch self {
        case .recent: return "Recent"
        case .aToZ: return "A to Z"
        case .zToA: return "Z to A"
        case .newest: return "Newest"
        case .oldest: return "Oldest"
        }
    }

    static let all: [Sort] = [.recent, .aToZ, .zToA, .newest, .oldest]
}

extension Sort {
    var memoSortDescriptors: [SortDescriptor<MemoObject>] {
        switch self {
        case .recent:
            return [SortDescriptor(\.updatedAt, order: .reverse)]
        case .aToZ:
            return [SortDescriptor(\.title), SortDescriptor(\.updatedAt, order: .reverse)]
        case .zToA:
            return [SortDescriptor(\.title, order: .reverse), SortDescriptor(\.updatedAt, order: .reverse)]
        case .newest:
            return [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldest:
            return [SortDescriptor(\.createdAt)]
        }
    }

    var trashSortDescriptors: [SortDescriptor<MemoObject>] {
        switch self {
        case .recent:
            return [SortDescriptor(\.updatedAt, order: .reverse)]
        case .aToZ:
            return [SortDescriptor(\.title), SortDescriptor(\.updatedAt, order: .reverse)]
        case .zToA:
            return [SortDescriptor(\.title, order: .reverse), SortDescriptor(\.updatedAt, order: .reverse)]
        case .newest:
            return [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldest:
            return [SortDescriptor(\.createdAt)]
        }
    }
}
