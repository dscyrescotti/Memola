//
//  CGSize++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

extension CGSize {
    func multiply(by scale: CGFloat) -> CGSize {
        CGSize(width: width * scale, height: height * scale)
    }
}
