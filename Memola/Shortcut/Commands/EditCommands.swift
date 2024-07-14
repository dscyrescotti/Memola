//
//  EditCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct EditCommands: Commands {
    @FocusedValue(\.activeSceneKey) private var appScene

    @FocusedObject var history: History?

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            if appScene == .memo, let history {
                Button {
                    history.historyPublisher.send(.undo)
                } label: {
                    Text("Undo")
                }
                .keyboardShortcut("z", modifiers: [.command])
                .disabled(history.undoDisabled)
                Button {
                    history.historyPublisher.send(.redo)
                } label: {
                    Text("Redo")
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(history.redoDisabled)
            }
        }
        CommandGroup(replacing: .pasteboard) { }
    }
}

