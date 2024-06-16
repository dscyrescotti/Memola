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
}
