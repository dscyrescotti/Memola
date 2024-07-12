//
//  EditCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct EditCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {
            // memo view
            Button {
                
            } label: {
                Text("Undo")
            }
            .keyboardShortcut("z", modifiers: [.command])
            Button {
                
            } label: {
                Text("Redo")
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
        }
        CommandGroup(replacing: .pasteboard) { }
    }
}

