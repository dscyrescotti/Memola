//
//  MemolaApp.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

@main
struct MemolaApp: App {
    var body: some Scene {
        WindowGroup {
            MemosView()
                .persistence(\.viewContext)
        }
    }
}
