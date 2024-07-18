//
//  Sidebar.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct Sidebar: View {
    private let sidebarItems: [SidebarItem] = [.memos, .trash]
    private let horizontalSizeClass: UserInterfaceSizeClass?

    @Binding private var sidebarItem: SidebarItem?
    
    @State private var presentsSettings: Bool = false

    #if os(macOS)
    @EnvironmentObject private var application: Application
    #endif

    init(sidebarItem: Binding<SidebarItem?>, horizontalSizeClass: UserInterfaceSizeClass?) {
        self._sidebarItem = sidebarItem
        self.horizontalSizeClass = horizontalSizeClass
    }

    var body: some View {
        #if os(macOS)
        regularList
        #else
        Group {
            if horizontalSizeClass == .compact {
                compactList
            } else {
                regularList
            }
        }
        .sheet(isPresented: $presentsSettings) {
            SettingsView()
        }
        #endif
    }

    private var regularList: some View {
        VStack(spacing: 10) {
            list
            Divider()
            settingsButton
                .buttonStyle(.unselected)
                .padding(.horizontal, 10)
        }
        #if os(macOS)
        .padding(.bottom, 10)
        .background(Color(color: .windowBackgroundColor))
        #else
        .background(Color(color: .secondarySystemBackground))
        #endif
        .navigationSplitViewColumnWidth(min: 250, ideal: 250, max: 250)
    }

    #if os(iOS)
    private var compactList: some View {
        list
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }
            }
    }
    #endif

    private var list: some View {
        List(selection: $sidebarItem) {
            ForEach(sidebarItems) { item in
                Group {
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
                #if os(macOS)
                .padding(.top, item == .memos ? 20 : 0)
                #else
                .padding(.top, horizontalSizeClass == .regular ? (item == .memos ? 20 : 0) : 0)
                #endif
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .automatic : .inline)
        #endif
    }

    private var settingsButton: some View {
        Button {
            #if os(macOS)
            application.openWindow(for: .settings)
            #else
            presentsSettings.toggle()
            #endif
        } label: {
            Label("Settings", systemImage: "gearshape.fill")
        }
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
