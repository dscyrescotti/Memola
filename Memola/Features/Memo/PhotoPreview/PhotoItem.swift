//
//  PhotoItem.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/16/24.
//

import SwiftUI
import Foundation

struct PhotoItem: Identifiable, Equatable {
    var id: URL
    let image: Platform.Image
    let previewImage: Platform.Image
    let dimension: CGSize
    let bookmark: Data

    func getDimension() -> CGSize {
        let maxSize = max(dimension.width, dimension.height)
        let width = dimension.width * 100 / maxSize
        let height = dimension.height * 100 / maxSize
        return CGSize(width: width, height: height)
    }
}
