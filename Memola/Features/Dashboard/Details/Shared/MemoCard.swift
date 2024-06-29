//
//  MemoCard.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoCard<Preview: View, Detail: View>: View {
    let memoObject: MemoObject
    let modifyPreview: ((MemoPreview) -> Preview)?
    let details: () -> Detail

    init(memoObject: MemoObject, @ViewBuilder modifyPreview: @escaping (MemoPreview) -> Preview, @ViewBuilder details: @escaping () -> Detail) {
        self.memoObject = memoObject
        self.modifyPreview = modifyPreview
        self.details = details
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let modifyPreview {
                modifyPreview(MemoPreview())
            } else {
                MemoPreview()
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
