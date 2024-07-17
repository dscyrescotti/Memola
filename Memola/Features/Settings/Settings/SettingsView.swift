//
//  SettingsView.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/17/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                #endif
            }
        }
        .focusedSceneValue(\.activeSceneKey, .settings)
        .interactiveDismissDisabled()
        #if os(macOS)
        .onAppear {
           DispatchQueue.main.async {
               NSApplication.shared.windows.forEach { window in
                   guard window.identifier?.rawValue.contains(AppWindow.settings.id) == true else { return }
                   window.standardWindowButton(.zoomButton)?.isEnabled = false
               }
           }
        }
        #endif
    }
}

