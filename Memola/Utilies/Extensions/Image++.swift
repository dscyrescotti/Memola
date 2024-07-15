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

#if os(macOS)
extension NSImage {
    func upsideDownMirrored() -> NSImage {
        let degrees: CGFloat = 180
        let sinDegrees = abs(sin(degrees * CGFloat.pi / 180.0))
        let cosDegrees = abs(cos(degrees * CGFloat.pi / 180.0))
        let newSize = CGSize(
            width: size.height * sinDegrees + size.width * cosDegrees,
            height: size.width * sinDegrees + size.height * cosDegrees
        )

        let imageBounds = NSRect(
            x: (newSize.width - size.width) / 2,
            y: (newSize.height - size.height) / 2,
            width: size.width,
            height: size.height
        )

        let otherTransform = NSAffineTransform()
        otherTransform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        otherTransform.rotate(byDegrees: degrees)
        otherTransform.translateX(by: -newSize.width / 2, yBy: -newSize.height / 2)

        let rotatedImage = NSImage(size: newSize)
        rotatedImage.lockFocus()
        otherTransform.concat()
        draw(in: imageBounds, from: CGRect.zero, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()

        return rotatedImage
    }

    func flipped(flipHorizontally: Bool = false, flipVertically: Bool = false) -> NSImage {
        let flippedImage = NSImage(size: size)

        flippedImage.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high

        let transform = NSAffineTransform()
        transform.translateX(by: flipHorizontally ? size.width : 0, yBy: flipVertically ? size.height : 0)
        transform.scaleX(by: flipHorizontally ? -1 : 1, yBy: flipVertically ? -1 : 1)
        transform.concat()

        draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1)

        flippedImage.unlockFocus()

        return flippedImage
    }
}
#endif

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
