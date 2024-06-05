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

    var redoCache: [HistoryEvent] = []

    let historyPublisher = PassthroughSubject<HistoryAction, Never>()

    var undoDisabled: Bool {
        undoStack.isEmpty
    }
    var redoDisabled: Bool {
        redoStack.isEmpty
    }

    func undo() -> HistoryEvent? {
        guard let event = undoStack.popLast() else {
            return nil
        }
        addRedo(event)
        return event
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
        redoCache = redoStack
        for event in redoStack {
            switch event {
            case .stroke(let _stroke):
                withPersistence(\.backgroundContext) { context in
                    if let stroke = _stroke.stroke(as: PenStroke.self)?.object {
                        context.delete(stroke)
                    }
                    try context.saveIfNeeded()
                }
            }
        }
        redoStack.removeAll()
    }

    func restoreUndo() {
        if !undoStack.isEmpty {
            undoStack.removeLast()
        }
        redoStack = redoCache
        redoCache.removeAll()
    }
}
