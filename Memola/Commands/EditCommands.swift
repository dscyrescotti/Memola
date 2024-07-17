//
//  EditCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct EditCommands: Commands {
    @FocusedValue(\.activeSceneKey) private var appScene

    @FocusedObject var tool: Tool?
    @FocusedObject var history: History?

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            if appScene == .memo {
                if let history {
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
                Divider()
                if let tool {
                    Button {
                        tool.selectTool(.hand)
                    } label: {
                        Text("Hand Tool")
                    }
                    .keyboardShortcut("h", modifiers: [.option])
                    Button {
                        tool.selectTool(.pen)
                    } label: {
                        Text("Pen Tool")
                    }
                    .keyboardShortcut("p", modifiers: [.option])
                    Button {
                        tool.selectTool(.photo)
                    } label: {
                        Text("Photo Tool")
                    }
                    .keyboardShortcut("p", modifiers: [.option, .shift])
                }
            }
        }
        CommandGroup(replacing: .pasteboard) { }
    }
}

