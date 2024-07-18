//
//  History.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import Foundation

final class History: ObservableObject {
    var memo: MemoObject?

    init(memo: MemoObject?) {
        self.memo = memo
    }

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
        withPersistence(\.viewContext) { [weak memo] context in
            memo?.updatedAt = .now
            try context.saveIfNeeded()
        }
    }

    func addRedo(_ event: HistoryEvent) {
        redoStack.append(event)
        withPersistence(\.viewContext) { [weak memo] context in
            memo?.updatedAt = .now
            try context.saveIfNeeded()
        }
    }

    func resetRedo() {
        redoCache = redoStack
        for event in redoStack {
            switch event {
            case .stroke(let _stroke):
                switch _stroke.style {
                case .marker:
                    guard let penStroke = _stroke.stroke(as: PenStroke.self) else { return }
                    withPersistence(\.backgroundContext) { context in
                        if let stroke = penStroke.object {
                            context.delete(stroke)
                        }
                        try context.saveIfNeeded()
                    }
                case .eraser:
                    guard let eraserStroke = _stroke.stroke(as: EraserStroke.self) else { return }
                    withPersistence(\.backgroundContext) { context in
                        if let stroke = eraserStroke.object {
                            context.delete(stroke)
                        }
                        try context.saveIfNeeded()
                    }
                }
            case .photo(let _photo):
                if let url = _photo.bookmark?.getBookmarkURL() {
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        NSLog("[Memola] - \(error.localizedDescription)")
                    }
                }
                withPersistence(\.backgroundContext) { context in
                    if let photo = _photo.object {
                        context.delete(photo)
                    }
                    try context.saveIfNeeded()
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.redoStack.removeAll()
        }
        withPersistence(\.viewContext) { [weak memo] context in
            memo?.updatedAt = .now
            try context.saveIfNeeded()
        }
    }

    func restoreUndo() {
        if !undoStack.isEmpty {
            undoStack.removeLast()
        }
        redoStack = redoCache
        redoCache.removeAll()
    }
}
