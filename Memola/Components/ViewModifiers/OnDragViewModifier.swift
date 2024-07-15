//
//  OnDragViewModifier.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/16/24.
//

import SwiftUI
import Foundation

private struct OnDragViewModifier<Preview: View>: ViewModifier {
    private let condition: Bool
    private let data: () -> NSItemProvider
    private let preview: () -> Preview

    init(condition: Bool, data: @escaping () -> NSItemProvider, @ViewBuilder preview: @escaping () -> Preview) {
        self.condition = condition
        self.data = data
        self.preview = preview
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if condition {
            content.onDrag(data, preview: preview)
        } else {
            content
        }
    }
}

public extension View {
    func onDrag<Preview: View>(if condition: Bool, data: @escaping () -> NSItemProvider, @ViewBuilder preview: @escaping () -> Preview) -> some View {
        modifier(OnDragViewModifier(condition: condition, data: data, preview: preview))
    }
}
