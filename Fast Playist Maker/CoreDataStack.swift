//
//  CoreDataStack.swift
//  Fast Playist Maker
//
//

import Foundation
import CoreData

struct CoreDataStack {
    
    //Mark: Properties
    
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: NSURL
    internal let dbURL: NSURL
    internal let persistingContext: NSManagedObjectContext
    internal let backgroundContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    
    init?(modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable to find \(modelName)in the main bundle")
            return nil
        }
        self.modelURL = modelURL as NSURL
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = persistingContext
        
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = mainContext
        
        guard let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("unable to reach the documents folder")
            return nil
        }
        self.dbURL = docUrl.appendingPathComponent("model.sqlite") as NSURL
        
        do {
            try addStoreCoordinator(storeType: NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
        } catch let error as NSError {
            print("unable to add store at \(dbURL)")
            print(error.localizedDescription)
        }
    }
    
    func addStoreCoordinator(storeType: String, configuration: String?, storeURL: NSURL, options : [NSObject: AnyObject]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL as URL, options: nil)
    }
}

extension CoreDataStack {
    typealias BackgroundBatchFunction = (_ backgroundContext: NSManagedObjectContext) -> ()
    
    func performBackgroundBatchOperation(batchFunction: @escaping BackgroundBatchFunction) {
        
        backgroundContext.perform() {
            
            
            batchFunction(self.backgroundContext)
            
            
            do {
                try self.backgroundContext.save()
            } catch let error as NSError {
                fatalError("Error while saving backgroundContext: \(error)")
            }
        }
    }
}

extension CoreDataStack {
    func save() {
        
        mainContext.performAndWait() {
            if self.mainContext.hasChanges {
                do {
                    try self.mainContext.save()
                } catch let error as NSError {
                    fatalError("Error While saving main context: \(error)")
                }
                
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch let error as NSError {
                        fatalError("Error while saving persisting context \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(_ delayInSeconds : Int) {
        if delayInSeconds > 0 {
            save()
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds)
            }
        }
    
    }
    
    
}
