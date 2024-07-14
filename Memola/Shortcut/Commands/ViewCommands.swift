//
//  ViewCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct ViewCommands: Commands {
    @ObservedObject private var application: Application
    @FocusedValue(\.activeSceneKey) private var appScene

    init(application: Application) {
        self.application = application
    }

    var body: some Commands {
        CommandGroup(replacing: .toolbar) {
            if appScene == .memos || appScene == .trash {
                Button {
                    application.activateSearchBar()
                } label: {
                    Text("Find Memo")
                }
                .keyboardShortcut("f", modifiers: [.command])
            }
            if appScene == .memos || appScene == .trash {
                Button {
                    application.toggleSidebar()
                } label: {
                    switch application.sidebarVisibility {
                    case .shown:
                        Text("Hide Sidebar")
                    case .hidden:
                        Text("Show Sidebar")
                    }
                }
                .keyboardShortcut("o", modifiers: [.command])
            }
        }
    }
}
