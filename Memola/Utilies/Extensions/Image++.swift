//
//  Image++.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/15/24.
//

import SwiftUI
import Foundation

extension Image {
    init(image: Platform.Image) {
        #if os(macOS)
        self = Image(nsImage: image)
        #else
        self = Image(uiImage: image)
        #endif
    }
}

#if os(iOS)
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
#endif
