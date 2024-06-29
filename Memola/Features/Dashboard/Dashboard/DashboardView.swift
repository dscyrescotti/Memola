//
//  DashboardView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State var sidebarItem: SidebarItem? = .memos

    var body: some View {
        NavigationSplitView {
            Sidebar(sidebarItem: $sidebarItem, horizontalSizeClass: horizontalSizeClass)
        } detail: {
            switch sidebarItem {
            case .memos:
                MemosView()
            case .trash:
                TrashView()
            default:
                MemosView()
            }
        }
    }
}