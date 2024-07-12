//
//  ShortcutKey.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct ShortcutKey: EnvironmentKey {
    static var defaultValue: Shortcut = .shared
}

extension EnvironmentValues {
    var shortcut: Shortcut {
        get { self[ShortcutKey.self] }
    }
}
