//
//  Drawable.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

protocol Drawable: AnyObject {
    func prepare(device: MTLDevice)
    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder)
}
