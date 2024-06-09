//
//  EraserObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/8/24.
//

import CoreData
import Foundation

@objc(EraserObject)
final class EraserObject: NSManagedObject {
    @NSManaged var bounds: [CGFloat]
    @NSManaged var color: [CGFloat]
    @NSManaged var style: Int16
    @NSManaged var createdAt: Date
    @NSManaged var thickness: CGFloat
    @NSManaged var quads: NSMutableOrderedSet
    @NSManaged var strokes: NSMutableSet
}
