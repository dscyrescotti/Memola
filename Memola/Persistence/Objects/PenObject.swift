//
//  PenObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/17/24.
//

import CoreData
import Foundation

@objc(PenObject)
class PenObject: NSManagedObject {
    @NSManaged var color: [CGFloat]
    @NSManaged var style: Int16
    @NSManaged var thickness: CGFloat
    @NSManaged var isSelected: Bool
    @NSManaged var orderIndex: Int16
    @NSManaged var tool: ToolObject?
}

extension PenObject {
    static func createObject(_ keyPath: KeyPath<Persistence, NSManagedObjectContext>, penStyle: any PenStyle) -> PenObject {
        let object = PenObject(context: Persistence.shared[keyPath: keyPath])
        object.color = penStyle.color
        object.style = penStyle.strokeStyle.rawValue
        object.isSelected = false
        object.thickness = penStyle.thickness.min
        return object
    }
}
