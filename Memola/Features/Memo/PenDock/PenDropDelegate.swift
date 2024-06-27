//
//  PenDropDelegate.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/16/24.
//

import SwiftUI
import Foundation

struct PenDropDelegate: DropDelegate {
    let id: String
    @ObservedObject var tool: Tool
    let action: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        tool.draggedPen = nil
        action()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedPen = tool.draggedPen else { return }
        if draggedPen.id != id {
            let fromIndex = tool.pens.firstIndex(where: { $0.id == draggedPen.id })!
            let toIndex = tool.pens.firstIndex(where: { $0.id == id })!
            guard tool.pens[toIndex].strokeStyle != .eraser else { return }
            withAnimation {
                tool.pens.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                tool.objectWillChange.send()
            }
            withPersistence(\.viewContext) { [weak object = tool.object] context in
                for (index, pen) in tool.pens.enumerated() {
                    pen.object?.orderIndex = Int16(index)
                }
                object?.memo?.updatedAt = .now
                try context.saveIfNeeded()
            }
        }
    }
}
