//
//  Collection++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Collection where Index == Int {
    subscript(fromEnd index: Index) -> Element? {
        let i = count - (index + 1)
        return self[safe: i]
    }
}
