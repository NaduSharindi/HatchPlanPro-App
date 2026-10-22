//
//  Persistence.swift
//  HatchPlanPro
//
//  Created by Nadunika Sharindi on 2026-05-11.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        try? viewContext.save()
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HatchPlanPro")
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("HatchPlanPro: missing persistent store description")
        }
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }
        // Model versions are added as the schema grows; let Core Data infer
        // the mapping so existing farm-floor data survives app updates.
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let loadError, let storeURL = description.url, !inMemory {
            // The local store is a cache of Firestore, so an unreadable store is
            // rebuilt rather than crashing the app; data re-syncs from the cloud.
            print("Persistence: store failed to load (\(loadError.localizedDescription)); rebuilding.")
            try? container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite)
            container.loadPersistentStores { _, error in
                if let error {
                    fatalError("Persistence: unable to create store — \(error)")
                }
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
