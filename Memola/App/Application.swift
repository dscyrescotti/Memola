//
//  Application.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import Combine
import SwiftUI

final class Application: NSObject, ObservableObject {
    
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
}

#if os(macOS)
extension Application: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        UserDefaults.standard.register(defaults: ["NSQuitAlwaysKeepsWindows": false])
    }
}
#else
extension Application: UIApplicationDelegate {
    func applicationDidFinishLaunching(_ application: UIApplication) { }
}
#endif
