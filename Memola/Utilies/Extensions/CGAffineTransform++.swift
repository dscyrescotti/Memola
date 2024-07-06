//
//  CGAffineTransform++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

extension CGAffineTransform {
    static func * (lhs: CGAffineTransform, rhs: CGAffineTransform) -> CGAffineTransform {
        return lhs.concatenating(rhs)
    }
}
