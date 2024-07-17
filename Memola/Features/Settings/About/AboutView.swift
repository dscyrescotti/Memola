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
            Section {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("v\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
                }
            }
            Section("Copyright") {
                Text(Bundle.main.copyright)
                    .font(.callout)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
