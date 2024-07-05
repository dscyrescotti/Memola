//
//  MemoPreview.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoPreview: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let preview: Data?
    let cellWidth: CGFloat
    var cellHeight: CGFloat {
        if horizontalSizeClass == .compact {
            return 120
        }
        return 150
    }

    var body: some View {
        Group {
            if let preview, let previewImage = UIImage(data: preview) {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.white)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
