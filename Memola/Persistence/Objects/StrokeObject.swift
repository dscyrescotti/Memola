//
//  StrokeObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

@objc(StrokeObject)
final class StrokeObject: NSManagedObject {
    @NSManaged var bounds: [CGFloat]
    @NSManaged var color: [CGFloat]
    @NSManaged var style: Int16
    @NSManaged var createdAt: Date
    @NSManaged var thickness: CGFloat
    @NSManaged var quads: NSMutableOrderedSet
    @NSManaged var graphicContext: GraphicContextObject?
}
