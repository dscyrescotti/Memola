//
//  DashboardView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var memo: MemoObject?
    @State var sidebarItem: SidebarItem? = .memos

    var body: some View {
        NavigationSplitView {
            Sidebar(sidebarItem: $sidebarItem, horizontalSizeClass: horizontalSizeClass)
        } detail: {
            switch sidebarItem {
            case .memos:
                MemosView(memo: $memo)
            case .trash:
                TrashView(memo: $memo, sidebarItem: $sidebarItem)
            default:
                MemosView(memo: $memo)
            }
        }
        .fullScreenCover(item: $memo) { memo in
            MemoView(memo: memo)
                .onDisappear {
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                        context.refreshAllObjects()
                    }
                }
        }
    }
}
