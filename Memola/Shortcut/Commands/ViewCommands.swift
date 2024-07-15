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

    @FocusedObject var canvas: Canvas?

    init(application: Application) {
        self.application = application
    }

    var body: some Commands {
        CommandGroup(replacing: .toolbar) {
            switch appScene {
            case .memos, .trash:
                Button {
                    application.activateSearchBar()
                } label: {
                    Text("Find Memo")
                }
                .keyboardShortcut("f", modifiers: [.command])
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
            case .memo:
                Button {
                    canvas?.toggleGridMode()
                } label: {
                    Text("Change Grid Layout")
                }
                .keyboardShortcut("g", modifiers: [.option])
            default:
                EmptyView()
            }
        }
    }
}
