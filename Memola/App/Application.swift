//
//  Application.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import Combine
import SwiftUI

final class Application: NSObject, ObservableObject {
    @Published var memoObject: MemoObject?
    @Published private(set) var sidebarVisibility: SidebarVisibility = .shown
}

extension Application {
    func openMemo(_ memoObject: MemoObject?) {
        self.memoObject = memoObject
    }

    func closeMemo() {
        self.memoObject = nil
    }
}

extension Application {
    func activateSearchBar() {
        #if os(macOS)
        guard let toolbar = NSApp.keyWindow?.toolbar else { return }
        if let search = toolbar.items.first(where: { $0.itemIdentifier.rawValue == "com.apple.SwiftUI.search" }) as? NSSearchToolbarItem {
            search.beginSearchInteraction()
        }
        #else
        #warning("TODO: implement for ipad")
        #endif
    }

    func toggleSidebar() {
        #if os(macOS)
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
        #else
        #warning("TODO: implement for ipad")
        #endif
    }

    func changeSidebarVisibility(_ visibility: SidebarVisibility) {
        self.sidebarVisibility = visibility
    }
}

#if os(macOS)
extension Application: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])
    }

    func openWindow(for appWindow: AppWindow) {
        let window = NSApplication.shared.windows.first { window in
            window.identifier?.rawValue.contains(appWindow.id) == true
        }
        if window == nil, let url = appWindow.url {
            NSWorkspace.shared.open(url)
        } else {
            window?.makeKeyAndOrderFront(nil)
        }
    }
}
#else
extension Application: UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) { }
}
#endif
