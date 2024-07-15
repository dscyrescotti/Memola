//
//  DashboardView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @EnvironmentObject private var application: Application

    @State private var sidebarItem: SidebarItem? = .memos
    @AppStorage("memola.app.scene.side-bar.column-visibility") private var columnVisibility: NavigationSplitViewVisibility = .all

    @Namespace private var namespace

    var body: some View {
        #if os(macOS)
        ZStack {
            if let memo = application.memoObject {
                NavigationStack {
                    MemoView(memo: memo)
                        .onDisappear {
                            withPersistence(\.viewContext) { context in
                                try context.saveIfNeeded()
                                context.refreshAllObjects()
                            }
                        }
                        .navigationTitle("")
                }
                .transition(.opacity)
                .matchedGeometryEffect(id: "pop-up", in: namespace)
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
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
                .transition(.opacity)
                .matchedGeometryEffect(id: "pop-up", in: namespace)
            }
        }
        .animation(.easeIn, value: application.memoObject)
        .toolbar(application.memoObject == nil ? .visible : .hidden, for: .windowToolbar)
        .toolbarBackground(application.memoObject == nil ? .clear : Color(nsColor: .windowBackgroundColor), for: .windowToolbar)
        .onChange(of: columnVisibility) { oldValue, newValue in
            application.changeSidebarVisibility(newValue == .all ? .shown : .hidden)
        }
        #else
        NavigationSplitView(columnVisibility: $columnVisibility) {
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
        .fullScreenCover(item: $application.memoObject) { memo in
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
