//
//  OnDismissSearchViewModifier.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/14/24.
//

import SwiftUI

private struct OnDismissSearchViewModifier: ViewModifier {
    @Environment(\.dismissSearch) var dismissSearch

    @Binding var isActive: Bool

    func body(content: Content) -> some View {
        content
            .onChange(of: isActive) { oldValue, newValue in
                if !newValue {
                    dismissSearch()
                }
            }
    }
}

extension View {
    func onDismissSearch(isActive: Binding<Bool>) -> some View {
        modifier(OnDismissSearchViewModifier(isActive: isActive))
    }
}
