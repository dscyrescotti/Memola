//
//  UIImage++.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/15/24.
//

import UIKit
import Foundation

extension UIImage {
    func imageWithUpOrientation() -> UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
    }
}
