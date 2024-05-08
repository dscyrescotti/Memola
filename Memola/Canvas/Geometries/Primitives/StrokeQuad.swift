//
//  StrokeQuad.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class StrokeQuad: NSObject, Codable {
    var quad: Quad

    init(quad: Quad) {
        self.quad = quad
    }
}

