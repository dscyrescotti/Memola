//
//  History.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import Foundation

class History: ObservableObject {
    @Published var undoStack: [HistoryEvent] = []
    @Published var redoStack: [HistoryEvent] = []

    let historyPublisher = PassthroughSubject<HistoryAction, Never>()

    var undoDisabled: Bool {
        undoStack.isEmpty
    }
    var redoDisabled: Bool {
        redoStack.isEmpty
    }

    func undo() -> Bool {
        guard let event = undoStack.popLast() else {
            return false
        }
        addRedo(event)
        return true
    }

    func redo() -> HistoryEvent? {
        guard let event = redoStack.popLast() else {
            return nil
        }
        addUndo(event)
        return event
    }

    func addUndo(_ event: HistoryEvent) {
        undoStack.append(event)
    }

    func addRedo(_ event: HistoryEvent) {
        redoStack.append(event)
    }

    func resetRedo() {
        redoStack.removeAll()
    }
}
