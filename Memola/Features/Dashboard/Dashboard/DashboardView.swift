//
//  DashboardView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @StateObject var memoManager: MemoManager = .shared

    @State var sidebarItem: SidebarItem? = .memos

    @Namespace var namespace

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            Sidebar(sidebarItem: $sidebarItem, horizontalSizeClass: horizontalSizeClass)
        } detail: {
            switch sidebarItem {
            case .memos:
                MemosView()
            case .trash:
                TrashView(sidebarItem: $sidebarItem)
            default:
                MemosView()
            }
        }
        .toolbar(memoManager.memoObject == nil ? .visible : .hidden, for: .windowToolbar)
        .toolbarBackground(memoManager.memoObject == nil ? .clear : Color(nsColor: .windowBackgroundColor), for: .windowToolbar)
        .overlay {
            if let memo = memoManager.memoObject {
                MemoView(memo: memo)
                    .onDisappear {
                        withPersistence(\.viewContext) { context in
                            try context.saveIfNeeded()
                            context.refreshAllObjects()
                        }
                    }
                    .transition(.move(edge: .bottom))
            }
        }
        #else
        NavigationSplitView {
            Sidebar(sidebarItem: $sidebarItem, horizontalSizeClass: horizontalSizeClass)
        } detail: {
            switch sidebarItem {
            case .memos:
                MemosView()
            case .trash:
                TrashView(sidebarItem: $sidebarItem)
            default:
                MemosView()
            }
        }
        .fullScreenCover(item: $memoManager.memo) { memo in
            MemoView(memo: memo)
                .onDisappear {
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                        context.refreshAllObjects()
                    }
                }
        }
        #endif
    }
}
