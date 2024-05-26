//
//  CGRect++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

extension CGRect {
    func transform(to rect: CGRect) -> CGAffineTransform {
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: -self.minX, y: -self.minY)
        t = t.translatedBy(x: rect.minX, y: rect.minY)
        t = t.scaledBy(x: 1 / self.width, y: 1 / self.height)
        t = t.scaledBy(x: rect.width, y: rect.height)
        return t
    }

    func muliply(by factor: CGFloat) -> CGRect {
        CGRect(origin: origin.muliply(by: factor), size: size.multiply(by: factor))
    }

    var boundingBox: (min: vector_float2, max: vector_float2) {
        (.init(minX.float, minY.float), .init(maxX.float, maxY.float))
    }
}
