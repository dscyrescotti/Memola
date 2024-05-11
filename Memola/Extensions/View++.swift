//
//  View++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/11/24.
//

import SwiftUI
import CoreData
import Foundation

extension View {
    func persistence(_ keyPath: KeyPath<Persistence, NSManagedObjectContext>) -> some View {
        environment(\.managedObjectContext, Persistence.shared[keyPath: keyPath])
    }
}
