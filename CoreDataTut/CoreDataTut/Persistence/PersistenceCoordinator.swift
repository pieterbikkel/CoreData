//
//  PersistenceCoordinator.swift
//  CoreDataTut
//
//  Created by Pieter Bikkel on 05/09/2020.
//  Copyright © 2020 Pieter Bikkel. All rights reserved.
//

import CoreData
import Foundation

class PersistenceCoordinator {
    
    typealias CompletionHandler = (Error?) -> Void
    typealias FetchedResultHandler = ([NSManagedObject]?, Error?) -> Void
    
    let persistentContainer: NSPersistentContainer
    let model: NSManagedObjectModel
    
    var privateContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    var fetchingContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
        self.model = persistentContainer.managedObjectModel
        
    }
    
    init(model: NSManagedObjectModel, storeDescription: NSPersistentStoreDescription) {
        self.model = model
        self.persistentContainer = NSPersistentContainer(name: "", managedObjectModel: model)
        self.persistentContainer.persistentStoreDescriptions = [storeDescription]
    }
    
    func constructCoreDataStack(_ completionHandler: @escaping CompletionHandler) {
        
        var loadedStoreCounts = 0
        let storesToLoad = persistentContainer.persistentStoreDescriptions.count
        
        persistentContainer.loadPersistentStores { storeDescription, error in
        
        if let error = error {
            print("The load call failed: \(error.localizedDescription)")
            completionHandler(error)
            return
        }
        
        loadedStoreCounts += 1
        
            if loadedStoreCounts == storesToLoad {
                completionHandler(nil)
            }
        }
        
        func saveChanges(in context: NSManagedObjectContext, completionHandler: @escaping CompletionHandler) {
            
            context.perform {
                
                do {
                    
                    if context.hasChanges {
                        try context.save()
                        try context.parent?.save()
                    }
                    
                    completionHandler(nil)
                } catch {
                    print("Hit an error: \(error.localizedDescription)")
                    completionHandler(error)
                }
            }
        }
        
        func fetch(from context: NSManagedObjectContext, fetchRequest: NSFetchRequest<NSFetchRequestResult>, fetchCompletionHandler: FetchedResultHandler) {
            
            do {
                
                let fetchedResults = try context.fetch(fetchRequest) as? [NSManagedObject]
                fetchCompletionHandler(fetchedResults, nil)
                
            } catch {
                print("Hit an error: \(error.localizedDescription)")
                fetchCompletionHandler(nil, error)
                
            }
            
        }
    }
    
}
