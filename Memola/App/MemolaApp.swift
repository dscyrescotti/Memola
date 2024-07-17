//
//  MemolaApp.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

@main
struct MemolaApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(Application.self) private var application
    #else
    @UIApplicationDelegateAdaptor(Application.self) private var application
    #endif

    var body: some Scene {
        WindowGroup(id: AppWindow.dashboard.id) {
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
                .environmentObject(application)
        }
        #if os(macOS)
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .windowToolbarStyle(.unified)
        .handlesExternalEvents(matching: [AppWindow.dashboard.id])
        #endif
        .commands {
            #if os(macOS)
            AppCommands(application: application)
            #endif
            FileCommands(application: application)
            EditCommands()
            ViewCommands(application: application)
        }
        #if os(macOS)
        WindowGroup(id: AppWindow.settings.id) {
            SettingsView()
                .onReceive(NotificationCenter.default.publisher(for: Platform.Application.willTerminateNotification)) { _ in
                    withPersistenceSync(\.viewContext) { context in
                        try context.saveIfNeeded()
                    }
                    withPersistenceSync(\.backgroundContext) { context in
                        try context.saveIfNeeded()
                    }
                }
                #if os(macOS)
                .frame(minWidth: 700, minHeight: 500)
                #endif
                .environmentObject(application)
        }
        .defaultPosition(.center)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 400)
        .windowToolbarStyle(.unifiedCompact)
        .handlesExternalEvents(matching: [AppWindow.settings.id])
        #endif
    }
}
