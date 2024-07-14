//
//  MemoPreview.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct MemoPreview: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let preview: Data?
    private let cellWidth: CGFloat

    init(preview: Data?, cellWidth: CGFloat) {
        self.preview = preview
        self.cellWidth = cellWidth
    }

    private var cellHeight: CGFloat {
        if horizontalSizeClass == .compact {
            return 120
        }
        return 150
    }

    var body: some View {
        Group {
            if let preview, let previewImage = Platform.Image(data: preview) {
                Image(image: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(.white)
            }
        }
        .frame(width: cellWidth, height: cellHeight)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
