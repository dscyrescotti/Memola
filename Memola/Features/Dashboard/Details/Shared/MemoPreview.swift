//
//  MemoPreview.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoPreview: View {
    let cellHeight: CGFloat = 150

    var body: some View {
        Rectangle()
            .frame(height: cellHeight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
