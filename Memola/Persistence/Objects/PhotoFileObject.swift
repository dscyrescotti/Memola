//
//  PhotoFileObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/20/24.
//

import CoreData
import Foundation

@objc(PhotoFileObject)
final class PhotoFileObject: NSManagedObject, Identifiable {
    @NSManaged var createdAt: Date?
    @NSManaged var imageURL: URL?
    @NSManaged var bookmark: Data?
    @NSManaged var dimension: [CGFloat]

    @NSManaged var photos: NSMutableSet?
    @NSManaged var graphicContext: GraphicContextObject?

    var previewImage: Platform.Image? {
        guard let imageURL else { return nil }
        guard let data = try? Data(contentsOf: imageURL, options: []) else { return nil }
        return Platform.Image(data: data)
    }

    func previewSize(_ size: CGFloat) -> (width: CGFloat, height: CGFloat) {
        let minDimension = min(dimension[0], dimension[1])
        let width = size * dimension[0] / minDimension
        let height = size * dimension[1] / minDimension
        return (width, height)
    }

    func photoDimension() -> CGSize {
        let maxSize = max(dimension[0], dimension[1])
        let width = dimension[0] * 100 / maxSize
        let height = dimension[1] * 100 / maxSize
        return CGSize(width: width, height: height)
    }
}
