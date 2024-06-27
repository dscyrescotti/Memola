//
//  RenderPass.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

protocol RenderPass {
    var label: String { get }
    var descriptor: MTLRenderPassDescriptor? { get set }
    func resize(on view: MTKView, to size: CGSize, with renderer: Renderer)
    func draw(into commandBuffer: MTLCommandBuffer, on canvas: Canvas, with renderer: Renderer) -> Bool
}
