//
//  AppCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

#if os(macOS)
import SwiftUI

struct AppCommands: Commands {
    @ObservedObject private var application: Application

    init(application: Application) {
        self.application = application
    }

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button {
                application.openWindow(for: .settings)
            } label: {
                Text("Services...")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
#endif
