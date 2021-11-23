//
//  PersistenceController.swift
//  ShaderMania
//
//  Created by Markus Moenig on 23/11/21.
//

import Foundation
import CoreData
import CloudKit

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = true) {
        
        container = NSPersistentCloudKitContainer(name: "DataModel")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Error")
        }
        
        //description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.moenig.ShaderMania")

        description.cloudKitContainerOptions?.databaseScope = .public

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /// Save the context if it has changes
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
