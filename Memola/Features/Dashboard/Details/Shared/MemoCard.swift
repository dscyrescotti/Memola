//
//  MemoCard.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoCard<Preview: View, Detail: View>: View {
    private let memoObject: MemoObject
    private let cellWidth: CGFloat
    private let modifyPreview: ((MemoPreview) -> Preview)?
    private let details: () -> Detail

    init(memoObject: MemoObject, cellWidth: CGFloat, modifyPreview: ((MemoPreview) -> Preview)?, @ViewBuilder details: @escaping () -> Detail) {
        self.memoObject = memoObject
        self.cellWidth = cellWidth
        self.modifyPreview = modifyPreview
        self.details = details
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let modifyPreview {
                modifyPreview(MemoPreview(preview: memoObject.preview, cellWidth: cellWidth))
            } else {
                MemoPreview(preview: memoObject.preview, cellWidth: cellWidth)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(memoObject.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                details()
            }
        }
    }
}
