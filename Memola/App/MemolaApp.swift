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
            DashboardView()
                .persistence(\.viewContext)
                .onReceive(NotificationCenter.default.publisher(for: Platform.Application.willTerminateNotification)) { _ in
                    withPersistenceSync(\.viewContext) { context in
                        try context.saveIfNeeded()
                    }
                    withPersistenceSync(\.backgroundContext) { context in
                        try context.saveIfNeeded()
                    }
                }
                #if os(macOS)
                .frame(minWidth: 1000, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        #endif
        WindowGroup(id: "memo-view", for: URL.self) { url in
            if let url = url.wrappedValue, let memo = Persistence.loadMemo(of: url) {
                MemoView(memo: memo)
                    #if os(macOS)
                    .frame(minWidth: 1000, minHeight: 600)
                    #endif
            }
        }
        #if os(macOS)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}
