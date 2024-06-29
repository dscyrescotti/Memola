//
//  MemoGrid.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoGrid<Card: View>: View {
    let cellWidth: CGFloat = 250
    let cellHeight: CGFloat = 150

    let memoObjects: FetchedResults<MemoObject>
    let placeholder: Placeholder.Info
    @ViewBuilder let card: (MemoObject) -> Card

    var body: some View {
        if memoObjects.isEmpty {
            Placeholder(info: placeholder)
        } else {
            GeometryReader { proxy in
                let count = Int(proxy.size.width / cellWidth)
                let columns: [GridItem] = .init(repeating: GridItem(.flexible(), spacing: 15), count: count)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(memoObjects) { memoObject in
                            card(memoObject)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
