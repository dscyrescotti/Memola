//
//  MemoObject.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

@objc(MemoObject)
final class MemoObject: NSManagedObject, Identifiable {
    @NSManaged var title: String
    @NSManaged var data: Data
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var canvas: CanvasObject
}
