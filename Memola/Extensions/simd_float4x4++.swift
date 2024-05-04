//
//  simd_float4x4++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

extension simd_float4x4 {
    init(_ transform: CGAffineTransform) {
        let t = CATransform3DMakeAffineTransform(transform)
        self = simd_float4x4([
            [Float(t.m11), Float(t.m12), Float(t.m13), Float(t.m14)],
            [Float(t.m21), Float(t.m22), Float(t.m23), Float(t.m24)],
            [Float(t.m31), Float(t.m32), Float(t.m33), Float(t.m34)],
            [Float(t.m41), Float(t.m42), Float(t.m43), Float(t.m44)]
        ])
    }
}
