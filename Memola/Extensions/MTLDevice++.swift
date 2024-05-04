//
//  MTLDevice++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit

extension MTLDevice {
    func maximumTextureDimension() -> Int {
        supportsFamily(.apple3) ? 16384 : 8192
    }
}
