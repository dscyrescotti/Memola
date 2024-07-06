//
//  DashboardView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    #if os(iOS)
    @State var memo: MemoObject?
    #endif
    @State var sidebarItem: SidebarItem? = .memos

    var body: some View {
        NavigationSplitView {
            Sidebar(sidebarItem: $sidebarItem, horizontalSizeClass: horizontalSizeClass)
        } detail: {
            switch sidebarItem {
            case .memos:
                #if os(macOS)
                MemosView()
                #else
                MemosView(memo: $memo)
                #endif
            case .trash:
                #if os(macOS)
                TrashView(sidebarItem: $sidebarItem)
                #else
                TrashView(memo: $memo, sidebarItem: $sidebarItem)
                #endif
            default:
                #if os(macOS)
                MemosView()
                #else
                MemosView(memo: $memo)
                #endif
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $memo) { memo in
            MemoView(memo: memo)
                .onDisappear {
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                        context.refreshAllObjects()
                    }
                }
        }
        #else
        #endif
    }
}
