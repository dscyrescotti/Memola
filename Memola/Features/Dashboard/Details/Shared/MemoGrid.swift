//
//  MemoGrid.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoGrid<Card: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let memoObjects: FetchedResults<MemoObject>
    let placeholder: Placeholder.Info
    @ViewBuilder let card: (MemoObject, CGFloat) -> Card

    var maxCellWidth: CGFloat {
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
        .background(Color(uiColor: .secondarySystemBackground))
    }
}
