//
//  FileCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct FileCommands: Commands {
    @Environment(\.shortcut) private var shortcut
    @FocusedValue(\.activeSceneKey) private var appScene

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            if appScene == .memos {
                Button {
                    shortcut.trigger(.newMemo)
                } label: {
                    Text("New Memo")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
