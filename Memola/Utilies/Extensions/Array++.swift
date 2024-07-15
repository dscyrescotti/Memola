//
//  Array++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

extension Array {
    mutating func append(_ element: Element, capacity: Int) {
        if count >= capacity {
            remove(at: 0)
        }
        append(element)
    }
}
