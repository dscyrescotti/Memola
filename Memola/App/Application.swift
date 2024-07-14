//
//  Application.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import Combine
import SwiftUI

class Application: NSObject, ObservableObject {

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
