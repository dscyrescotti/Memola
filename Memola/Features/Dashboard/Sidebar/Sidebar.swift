//
//  Sidebar.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct Sidebar: View {
    private let sidebarItems: [SidebarItem] = [.memos, .trash]
    @Binding private var sidebarItem: SidebarItem?

    private let horizontalSizeClass: UserInterfaceSizeClass?

    init(sidebarItem: Binding<SidebarItem?>, horizontalSizeClass: UserInterfaceSizeClass?) {
        self._sidebarItem = sidebarItem
        self.horizontalSizeClass = horizontalSizeClass
    }

    var body: some View {
        List(selection: $sidebarItem) {
            ForEach(sidebarItems) { item in
                if horizontalSizeClass == .compact {
                    Button {
                        sidebarItem = item
                    } label: {
                        Label(item.title, systemImage: item.icon)
                            .foregroundColor(.primary)
                    }
                } else {
                    Button {
                        sidebarItem = item
                    } label: {
                        Label(item.title, systemImage: item.icon)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(sidebarItem == item ? .selected : .unselected)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(horizontalSizeClass == .compact ? "Memola" : "")
        .scrollContentBackground(.hidden)
        #if os(macOS)
        .background(Color(color: .windowBackgroundColor))
        #else
        .background(Color(color: .secondarySystemBackground))
        #endif
        .navigationSplitViewColumnWidth(min: 250, ideal: 250, max: 250)
        #if os(iOS)
        .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .automatic : .inline)
        #endif
    }
}

extension Sidebar {
    fileprivate struct SidebarItemButtonStyle: ButtonStyle {
        let state: State

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity, alignment: .leading)
                #if os(macOS)
                .padding(10)
                #else
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                #endif
                .contentShape(RoundedRectangle(cornerRadius: 10))
                .background {
                    switch state {
                    case .selected:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.primary.opacity(0.08))
                    case .unselected:
                        EmptyView()
                    }
                }
        }

        enum State {
            case selected
            case unselected
        }
    }
}

extension ButtonStyle where Self == Sidebar.SidebarItemButtonStyle {
    static var selected: Sidebar.SidebarItemButtonStyle {
        Sidebar.SidebarItemButtonStyle(state: .selected)
    }

    static var unselected: Sidebar.SidebarItemButtonStyle {
        Sidebar.SidebarItemButtonStyle(state: .unselected)
    }
}
