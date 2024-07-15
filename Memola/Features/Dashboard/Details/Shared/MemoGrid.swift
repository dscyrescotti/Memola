//
//  MemoGrid.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoGrid<Card: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let memoObjects: FetchedResults<MemoObject>
    private let placeholder: Placeholder.Info
    @ViewBuilder private let card: (MemoObject, CGFloat) -> Card

    init(memoObjects: FetchedResults<MemoObject>, placeholder: Placeholder.Info, @ViewBuilder card: @escaping (MemoObject, CGFloat) -> Card) {
        self.memoObjects = memoObjects
        self.placeholder = placeholder
        self.card = card
    }

    private var maxCellWidth: CGFloat {
        if horizontalSizeClass == .compact {
            return 180
        }
        return 200
    }

    var body: some View {
        Group {
            if memoObjects.isEmpty {
                Placeholder(info: placeholder)
            } else {
                GeometryReader { proxy in
                    let spacing: CGFloat = 15
                    let padding: CGFloat = 20
                    let count = Int(proxy.size.width / maxCellWidth)
                    let cellWidth = (proxy.size.width - spacing * CGFloat(count - 2) - padding * 2.0) / CGFloat(count)
                    let columns: [GridItem] = .init(repeating: GridItem(.flexible(), spacing: spacing), count: count)
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(memoObjects) { memoObject in
                                card(memoObject, cellWidth)
                            }
                        }
                        .padding(padding)
                    }
                }
            }
        }
        #if os(macOS)
        .background(Color(color: .windowBackgroundColor))
        #else
        .background(Color(color: .secondarySystemBackground))
        #endif
    }
}
