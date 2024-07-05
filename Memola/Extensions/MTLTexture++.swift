//
//  MTLTexture++.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/4/24.
//

import MetalKit
import Foundation

extension MTLTexture {
    private func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height = self.height
        let rowBytes = self.width * 4
        let p = malloc(width * height * 4)!
        getBytes(p, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return p
    }

    func getImage() -> CGImage? {
        let bytes = self.bytes()
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        if let provider = CGDataProvider(dataInfo: nil, data: bytes, size: selftureSize, releaseData: { _, p, _ in
            p.deallocate()
        }) {
            return CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: rowBytes,
                space: pColorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: CGColorRenderingIntent.defaultIntent
            )
        }
        return nil
    }
}
