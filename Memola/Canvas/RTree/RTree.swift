//
//  RTree.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/4/24.
//

import Foundation

class RTree<T> where T: Equatable & Comparable {
    private var root: Node<T>
    private let maxEntries: Int
    private let minEntries: Int

    init(maxEntries: Int = 9) {
        self.maxEntries = max(4, maxEntries)
        self.minEntries = max(2, Int(ceil(Double(maxEntries) * 0.4)))
        self.root = Node<T>.createNode()
    }

    // MARK: - Retrival
    func traverse() -> [T] {
        _traverse(from: root)
    }

    private func _traverse(from _root: Node<T>) -> [T] {
        var result: [T] = []
        var queue: [Node<T>] = [_root]
        while let node = queue.first {
            queue.removeFirst()
            if node.isLeaf {
                let children = node.children
                    .compactMap { $0.value }
                    .sorted(by: <)
                result = _merge(result, children)
            } else {
                queue.append(contentsOf: node.children)
            }
        }
        return result
    }

    func _merge(_ left: [T], _ right: [T]) -> [T] {
        var mergedArray: [T] = []
        var leftIndex = 0
        var rightIndex = 0

        while leftIndex < left.count && rightIndex < right.count {
            if left[leftIndex] < right[rightIndex] {
                mergedArray.append(left[leftIndex])
                leftIndex += 1
            } else {
                mergedArray.append(right[rightIndex])
                rightIndex += 1
            }
        }

        mergedArray.append(contentsOf: left[leftIndex...])
        mergedArray.append(contentsOf: right[rightIndex...])

        return mergedArray
    }

    // MARK: - Search
    func search(box: Box) -> [T] {
        guard box.intersects(with: root.box) else { return [] }
        var result: [T] = []
        var queue: [Node<T>] = [root]
        while let node = queue.first {
            queue.removeFirst()
            for childNode in node.children {
                if box.intersects(with: childNode.box) {
                    if node.isLeaf {
                        if let value = childNode.value {
                            result = _merge(result, [value])
                        }
                    } else if box.contains(with: childNode.box) {
                        result = _merge(result, _traverse(from: childNode))
                    } else {
                        queue.append(childNode)
                    }
                }
            }
        }
        return result
    }

    // MARK: - Insertion
    func insert(_ value: T, in box: Box) {
        let node: Node = Node<T>.createNode(in: box, for: value)
        _insert(node, level: root.height - 1)
    }

    private func _insert(_ node: Node<T>, level: Int) {
        let box = node.box
        var path: [Node<T>] = []
        var level = level
        let leafNode = _chooseSubtree(for: box, from: root, at: level, into: &path)
        leafNode.children.append(node)
        leafNode.box.enlarge(for: box)
        while level >= 0 {
            guard path[level].children.count > maxEntries else {
                break
            }
            _split(on: path, at: level)
            level -= 1
        }
        _adjustParentBoxes(with: box, through: path, at: level)
    }

    private func _chooseSubtree(for box: Box, from rootNode: Node<T>, at level: Int, into path: inout [Node<T>]) -> Node<T> {
        var node = rootNode
        while true {
            path.append(node)
            if node.isLeaf || path.count - 1 == level { break }
            var minArea: Double = .infinity
            var minEnlargement: Double = .infinity
            var targetNode: Node<T>?
            for node in node.children {
                let area = node.box.area
                let enlargement = box.enlargedArea(for: node.box) - area
                if enlargement < minEnlargement {
                    minEnlargement = enlargement
                    minArea = area < minArea ? area : minArea;
                    targetNode = node
                } else if enlargement == minEnlargement {
                    if area < minArea {
                        minArea = area
                        targetNode = node
                    }
                }
            }
            node = targetNode ?? node.children[0]
        }
        return node
    }

    // MARK: - Removal
    @discardableResult
    func remove(_ value: T, in box: Box) -> T? {
        var node: Node<T>? = root

        var path: [Node<T>] = []
        var indices: [Int] = []
        var parent: Node<T>?
        var i: Int = 0
        var goingUp: Bool = false

        while node != nil || !path.isEmpty {
            guard let currentNode = node else {
                node = path.popLast()
                parent = path.last
                i = indices.popLast() ?? 0
                goingUp = true
                continue
            }
            if currentNode.isLeaf, let index = _findIndex(of: value, nodes: currentNode.children) {
                let removedNode = currentNode.children.remove(at: index)
                path.append(currentNode)
                _condense(path)
                return removedNode.value
            }
            if !goingUp && !currentNode.isLeaf && currentNode.box.contains(with: box) {
                path.append(currentNode)
                indices.append(i)
                i = 0
                parent = currentNode
                node = currentNode.children[0]
            } else if let parent {
                i += 1
                node = parent.children[safe: i]
                goingUp = false
            } else {
                node = nil
            }
        }
        return nil
    }

    private func _findIndex(of value: T, nodes: [Node<T>]) -> Int? {
        for (index, node) in nodes.enumerated() {
            if node.value == value { return index }
        }
        return nil
    }

    private func _condense(_ path: [Node<T>]) {
        var i = path.count - 1
        while i >= 0 {
            let node = path[i]
            if node.children.isEmpty {
                if i > 0 {
                    var siblings = path[i - 1].children
                    if let index = siblings.firstIndex(where: { $0 === node }) {
                        siblings.remove(at: index)
                    }
                } else {
                    root = .createNode()
                }
            } else {
                _calculateBox(of: node)
            }
            i -= 1
        }
    }

    // MARK: - Splitting
    private func _split(on path: [Node<T>], at level: Int) {
        let node = path[level]
        let numOfChildren = node.children.count
        let minNumOfChildren = minEntries

        _chooseSplitAxis(for: node, with: numOfChildren, by: minNumOfChildren)
        let splitIndex = _chooseSplitIndex(for: node, with: numOfChildren, by: minNumOfChildren)

        let children = Array(node.children[splitIndex..<node.children.count])
        node.children.removeSubrange(splitIndex..<node.children.count)
        let newNode: Node = Node<T>.createNode(with: children)
        newNode.height = node.height
        newNode.isLeaf = node.isLeaf

        node.updateBox()
        newNode.updateBox()

        if level > 0 {
            path[level - 1].children.append(newNode)
        } else {
            _splitRoot(with: node, and: newNode)
        }
    }

    private func _splitRoot(with node: Node<T>, and newNode: Node<T>) {
        root = Node<T>.createNode(with: [node, newNode])
        root.height = node.height + 1
        root.isLeaf = false
        root.updateBox()
    }

    private func _chooseSplitAxis(for node: Node<T>, with numOfChildren: Int, by minEntries: Int) {
        let comparatorX: (Node<T>, Node<T>) -> Bool = { $0.box.minX < $1.box.minX }
        let comparatorY: (Node<T>, Node<T>) -> Bool = { $0.box.minY < $1.box.minY }
        let xMargin = _calculateDistributionMargin(for: node, with: numOfChildren, by: minEntries, using: comparatorX)
        let yMargin = _calculateDistributionMargin(for: node, with: numOfChildren, by: minEntries, using: comparatorY)
        if xMargin < yMargin {
            node.children.sort(by: comparatorX)
        }
    }

    private func _calculateDistributionMargin(for node: Node<T>, with numOfChildren: Int, by minEntries: Int, using comparator: (Node<T>, Node<T>) -> Bool) -> Double {
        node.children.sort(by: comparator)
        let leftNode = _mergeChildNodes(of: node, from: 0, to: minEntries)
        let rightNode = _mergeChildNodes(of: node, from: numOfChildren - minEntries, to: numOfChildren)
        var margin = leftNode.box.margin + rightNode.box.margin

        for index in minEntries..<numOfChildren - minEntries {
            let node = node.children[index]
            leftNode.box.enlarge(for: node.box)
            margin += leftNode.box.margin
        }
        for index in stride(from: numOfChildren - minEntries - 1, through: minEntries, by: -1) {
            let node = node.children[index]
            rightNode.box.enlarge(for: node.box)
            margin += rightNode.box.margin
        }
        return margin
    }

    private func _chooseSplitIndex(for node: Node<T>, with numOfChildren: Int, by minEntries: Int) -> Int {
        var index: Int?
        var minOverlap: Double = .infinity
        var minArea: Double = .infinity
        for idx in minEntries...numOfChildren - minEntries {
            let node1 = _mergeChildNodes(of: node, from: 0, to: idx)
            let node2 = _mergeChildNodes(of: node, from: idx, to: numOfChildren)

            let overlap = node1.box.intersectedArea(on: node2.box)
            let area = node1.box.area + node2.box.area

            if overlap < minOverlap {
                minOverlap = overlap
                index = idx
                minArea = min(area, minArea)
            } else if overlap == minOverlap {
                if area < minArea {
                    minArea = area
                    index = idx
                }
            }
        }
        return index ?? numOfChildren - minEntries
    }

    private func _adjustParentBoxes(with box: Box, through path: [Node<T>], at level: Int) {
        for index in stride(from: level, through: 0, by: -1) {
            path[index].box.enlarge(for: box)
        }
    }

    private func _calculateBox(of node: Node<T>) {
        _mergeChildNodes(of: node, from: 0, to: node.children.count, into: node)
    }

    @discardableResult
    private func _mergeChildNodes(of node: Node<T>, from start: Int, to end: Int, into newNode: Node<T> = .createNode()) -> Node<T> {
        newNode.box = .infinity
        for index in start..<end {
            let node = node.children[index]
            newNode.box.enlarge(for: node.box)
        }
        return newNode
    }
}
