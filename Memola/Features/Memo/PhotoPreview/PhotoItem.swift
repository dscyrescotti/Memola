//
//  PhotoItem.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/16/24.
//

import UIKit
import Foundation

struct PhotoItem: Identifiable, Equatable {
    var id: URL
    let image: UIImage
    let bookmark: Data

    var dimension: CGSize {
        let size = image.size
        let maxSize = max(size.width, size.height)
        let width = size.width * 128 / maxSize
        let height = size.height * 128 / maxSize
        return CGSize(width: width, height: height)
    }
}
