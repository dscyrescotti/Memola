//
//  NSManagedObjectContext++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData

extension NSManagedObjectContext {
    func saveIfNeeded() throws {
        if hasChanges {
            try save()
        }
    }
}
