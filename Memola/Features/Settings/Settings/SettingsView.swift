//
//  SettingsView.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/17/24.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings View")
                .navigationTitle("Settings")
        }
        .focusedSceneValue(\.activeSceneKey, .settings)
    }
}

