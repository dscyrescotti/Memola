//
//  ContextMenuViewModifier.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/17/24.
//

import SwiftUI
import Foundation

private struct ContextMenuViewModifier<MenuContent: View, Preview: View>: ViewModifier {
    private let condition: Bool
    private let menuItems: () -> MenuContent
    private let preview: () -> Preview

    init(condition: Bool, @ViewBuilder menuItems: @escaping () -> MenuContent, @ViewBuilder preview: @escaping () -> Preview) {
        self.condition = condition
        self.menuItems = menuItems
        self.preview = preview
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if condition {
            content.contextMenu(menuItems: menuItems, preview: preview)
        } else {
            content
        }
    }
}

public extension View {
    func contextMenu<MenuContent: View, Preview: View>(if condition: Bool, @ViewBuilder menuItems: @escaping () -> MenuContent, @ViewBuilder preview: @escaping () -> Preview) -> some View {
        modifier(ContextMenuViewModifier(condition: condition, menuItems: menuItems, preview: preview))
    }
}
