//
//  ContextMenuableViewModifier.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/17/24.
//

import SwiftUI
import Foundation

struct ContextMenuableViewModifier<MenuContent: View>: ViewModifier {
    let condition: Bool
    let menuItems: () -> MenuContent

    @ViewBuilder
    func body(content: Content) -> some View {
        if condition {
            content.contextMenu(menuItems: menuItems)
        } else {
            content
        }
    }
}

public extension View {
    func contextMenu<MenuContent: View>(if condition: Bool, @ViewBuilder menuItems: @escaping () -> MenuContent) -> some View {
        modifier(ContextMenuableViewModifier(condition: condition, menuItems: menuItems))
    }
}
