//
//  ElementObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/12/24.
//

import CoreData
import Foundation

@objc(ElementObject)
final class ElementObject: NSManagedObject {
    @NSManaged var type: Int16
    @NSManaged var createdAt: Date?
    @NSManaged var stroke: StrokeObject?
    @NSManaged var graphicContext: GraphicContextObject?
}
