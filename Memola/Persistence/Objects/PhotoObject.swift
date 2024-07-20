//
//  PhotoObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/13/24.
//

import CoreData
import Foundation

@objc(PhotoObject)
final class PhotoObject: NSManagedObject {
    @NSManaged var width: CGFloat
    @NSManaged var originY: CGFloat
    @NSManaged var originX: CGFloat
    @NSManaged var height: CGFloat
    @NSManaged var bounds: [CGFloat]
    @NSManaged var createdAt: Date?

    @NSManaged var file: PhotoFileObject?
    @NSManaged var element: ElementObject?
}
