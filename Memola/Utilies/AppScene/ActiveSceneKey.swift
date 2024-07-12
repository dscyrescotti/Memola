//
//  ActiveSceneKey.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import SwiftUI

struct ActiveSceneKey: FocusedValueKey {
    typealias Value = AppScene
}

extension FocusedValues {
    var activeSceneKey: AppScene? {
        get { self[ActiveSceneKey.self] }
        set { self[ActiveSceneKey.self] = newValue }
    }
}
