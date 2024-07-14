//
//  Node.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/4/24.
//

import Foundation

final class Node<T> where T: Equatable & Comparable {
    var box: Box
    var value: T?
    var isLeaf: Bool
    var height: Int
    var children: [Node]

    init(box: Box, value: T? = nil, isLeaf: Bool, height: Int, children: [Node] = []) {
        self.box = box
        self.value = value
        self.isLeaf = isLeaf
        self.height = height
        self.children = children
    }

    func updateBox() {
        box = .infinity
        for node in children {
            box.enlarge(for: node.box)
        }
    }

    static func createNode(in box: Box = .infinity, for value: T? = nil, with children: [Node] = []) -> Node {
        Node(box: box, value: value, isLeaf: true, height: 1, children: children)
    }
}
