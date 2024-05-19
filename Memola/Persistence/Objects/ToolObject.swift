//
//  ToolObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/17/24.
//

import CoreData
import Foundation

@objc(ToolObject)
class ToolObject: NSManagedObject {
    @NSManaged var pens: NSMutableSet
    @NSManaged var memo: MemoObject?
}
