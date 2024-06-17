//
//  GraphicContextObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

@objc(GraphicContextObject)
final class GraphicContextObject: NSManagedObject {
    @NSManaged var canvas: CanvasObject?
    @NSManaged var elements: NSMutableOrderedSet
}
