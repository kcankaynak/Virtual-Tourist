//
//  CoreDataController.swift
//  Virtual Tourist
//
//  Created by Kemal Kaynak on 06.07.20.
//  Copyright © 2020 Kemal Kaynak. All rights reserved.
//

import Foundation
import CoreData

final class CoreDataController {
    
    static let shared = CoreDataController("Virtual_Tourist")
    let persistentContainer: NSPersistentContainer!
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    lazy var backgroundContext: NSManagedObjectContext = {
        return persistentContainer.newBackgroundContext()
    }()
    
    private init(_ modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func setupContext() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load() {
        persistentContainer.loadPersistentStores { (storeDesc, error) in
            if error != nil {
                self.setupContext()
                self.autoSaveViewContext()
            }
        }
    }
    
    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
    }
}

// MARK: - Saving Operations -

extension CoreDataController {
    
    func autoSaveViewContext(interval: TimeInterval = 30) {
        guard interval > 0 else { return }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval){
            self.autoSaveViewContext(interval: interval)
        }
    }
    
    func save() {
        do {
            try viewContext.save()
        } catch let error {
            print("Can't save item due to error -> \(error.localizedDescription)")
        }
    }
}
