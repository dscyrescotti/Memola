//
//  QuadObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

@objc(QuadObject)
final class QuadObject: NSManagedObject {
    @NSManaged var originX: CGFloat
    @NSManaged var originY: CGFloat
    @NSManaged var size: CGFloat
    @NSManaged var rotation: CGFloat
    @NSManaged var shape: Int16
    @NSManaged var color: [CGFloat]
    @NSManaged var stroke: StrokeObject?
}
