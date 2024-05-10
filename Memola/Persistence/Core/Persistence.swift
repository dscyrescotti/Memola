//
//  Persistence.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import CoreData
import Foundation

class Persistence {
    private let modelName = "MemolaModel"

    static let shared: Persistence = Persistence()

    private init() { }

    static var context: NSManagedObjectContext = {
        shared.persistentContainer.viewContext
    }()

    private lazy var viewContext: NSManagedObjectContext = {
        persistentContainer.viewContext
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        let persistentStore = NSPersistentStoreDescription()
        persistentStore.shouldMigrateStoreAutomatically = true
        persistentStore.shouldInferMappingModelAutomatically = true
        let container = NSPersistentContainer(name: modelName, managedObjectModel: managedObjectModel)
        do {
            let coordinator = container.persistentStoreCoordinator
            if let oldStore = coordinator.persistentStores.first {
                try coordinator.remove(oldStore)
            }
            _ = try coordinator.addPersistentStore(type: .sqlite, at: sqliteURL)
        } catch {
            fatalError("[Memola] - \(error.localizedDescription)")
        }
        container.persistentStoreDescriptions = [persistentStore]
        container.loadPersistentStores { description, error in
            if let error {
                fatalError("[Memola]: \(error.localizedDescription)")
            }
        }
        return container
    }()

    private lazy var managedObjectModel: NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: ".momd"), let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("[Memola]: Unable to load model.")
        }
        return model
    }()

    private lazy var sqliteURL: URL = {
        do {
            let fileURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("\(modelName).sqlite")
            NSLog(fileURL.absoluteString)
            return fileURL
        } catch {
            fatalError("[Memola]: \(error.localizedDescription)")
        }
    }()

    static func performe(_ action: (NSManagedObjectContext) -> Void) {
        action(shared.viewContext)
    }

    static func saveIfNeeded() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                NSLog("[Memola] - \(error.localizedDescription)")
            }
        }
    }
}
