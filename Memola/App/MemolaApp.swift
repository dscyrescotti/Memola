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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    withPersistenceSync(\.viewContext) { context in
                        try context.saveIfNeeded()
                    }
                    withPersistenceSync(\.backgroundContext) { context in
                        try context.saveIfNeeded()
                    }
                }
        }
    }
}
