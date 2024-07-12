//
//  AppCommands.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button {
                
            } label: {
                Text("Services...")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
