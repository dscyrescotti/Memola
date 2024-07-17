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
            List {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle.fill")
                        .foregroundStyle(.primary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .focusedSceneValue(\.activeSceneKey, .settings)
        .interactiveDismissDisabled()
    }
}

