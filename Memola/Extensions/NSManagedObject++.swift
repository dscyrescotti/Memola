//
//  NSManagedObject++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import CoreData
import Foundation

extension NSManagedObject {
    convenience init(_ keyPath: KeyPath<Persistence, NSManagedObjectContext>) {
        self.init(context: Persistence.shared[keyPath: keyPath])
    }
}
