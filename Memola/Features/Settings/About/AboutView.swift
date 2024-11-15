//
//  AboutView.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/17/24.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("INFO") {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("v\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
                }
                #if os(macOS)
                .listRowSeparator(.hidden)
                #endif
            }
            Section("REPOSTORY") {
                Text("https://github.com/dscyrescotti/Memola")
                    #if os(macOS)
                    .listRowSeparator(.hidden)
                    #endif
            }
            Section("COPYRIGHT") {
                Text(Bundle.main.copyright)
                    .font(.callout)
                    #if os(macOS)
                    .listRowSeparator(.hidden)
                    #endif
            }
        }
        .navigationTitle("About")
        #if os(iOS)
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
