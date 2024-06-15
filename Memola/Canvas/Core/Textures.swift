//
//  Textures.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class Textures {
    static var penTextures: [String: MTLTexture] = [:]

    static func hasCreatedPenTexture(of textureName: String) -> Bool {
        penTextures[textureName] != nil
    }

    @discardableResult
    static func createPenTexture(with textureName: String, on device: MTLDevice) -> MTLTexture? {
        if let penTexture = penTextures[textureName] {
            return penTexture
        }
        let textureLoader = MTKTextureLoader(device: device)
        let penTexture = try? textureLoader.newTexture(name: textureName, scaleFactor: 1.0, bundle: .main, options: [.SRGB: false])
        penTextures[textureName] = penTexture
        return penTexture
    }

    @discardableResult
    static func createPhotoTexture(for url: URL, on device: MTLDevice) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: device)
        do {
            let photoTexture = try textureLoader.newTexture(URL: url, options: [.SRGB: false])
            return photoTexture
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
            return nil
        }
    }

    static func createGraphicTexture(
        from renderer: Renderer,
        size: CGSize,
        pixelFormat: MTLPixelFormat? = nil
    ) -> MTLTexture? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat ?? renderer.pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead, .renderTarget, .shaderWrite]
        guard let texture = renderer.device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        texture.label = "Graphic Texture"
        return texture
    }

    static func createCacheTexture(
        from renderer: Renderer,
        size: CGSize,
        pixelFormat: MTLPixelFormat? = nil
    ) -> MTLTexture? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat ?? renderer.pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead, .renderTarget, .shaderWrite]
        guard let texture = renderer.device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        texture.label = "Cache Texture"
        return texture
    }

    static func createStrokeTexture(
        from renderer: Renderer,
        size: CGSize,
        pixelFormat: MTLPixelFormat? = nil
    ) -> MTLTexture? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat ?? renderer.pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.storageMode = .shared
        descriptor.usage = [.shaderRead, .renderTarget, .shaderWrite]
        guard let texture = renderer.device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        texture.label = "Stroke Texture"
        return texture
    }
}
