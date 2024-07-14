//
//  ViewCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct ViewCommands: Commands {
    @FocusedValue(\.activeSceneKey) var appScene

    var body: some Commands {
        CommandGroup(replacing: .toolbar) {
            if appScene == .trash || appScene == .memos {
                Button {
                    #if os(macOS)
                    guard let toolbar = NSApp.keyWindow?.toolbar else { return }
                    if let search = toolbar.items.first(where: { $0.itemIdentifier.rawValue == "com.apple.SwiftUI.search" }) as? NSSearchToolbarItem {
                        search.beginSearchInteraction()
                    }
                    #endif
                } label: {
                    Text("Find Memo")
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
        }
    }
}
