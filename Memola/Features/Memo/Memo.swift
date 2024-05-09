//
//  Memo.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import CoreData
import Foundation

@objc(Memo)
final class Memo: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var data: Data
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var canvas: Canvas
}

extension Memo: Identifiable { }
