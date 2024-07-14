//
//  ToolObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/17/24.
//

import CoreData
import Foundation

@objc(ToolObject)
final class ToolObject: NSManagedObject {
    @NSManaged var selection: Int16
    @NSManaged var pens: NSMutableSet
    @NSManaged var memo: MemoObject?
}
