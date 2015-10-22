//
//  LocalDataBaseHandler.swift
//  Origami
//
//  Created by CloudCraft on 21.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class LocalDatabaseHandler{
    
    private let privateContext:NSManagedObjectContext
    private let mainQueueContext:NSManagedObjectContext
    private let persistentStoreCoordinator:NSPersistentStoreCoordinator
    //MARK: - Initialization stuff
    class func getManagedObjectModel() -> NSManagedObjectModel?
    {
        guard let dataModelUrl = NSBundle.mainBundle().URLForResource("OrigamiDataModel", withExtension: "momd") else{
            return nil
        }
        
        if let dataModel = NSManagedObjectModel(contentsOfURL:dataModelUrl)
        {
            return dataModel
        }
        
        return nil
    }
    
    class func getPersistentStoreCoordinatorForModel(model:NSManagedObjectModel) throws -> NSPersistentStoreCoordinator?
    {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let aFileHandler = FileHandler()
        guard let dbURL = aFileHandler.applicationDocumentsDirectory()?.URLByAppendingPathComponent("OrigamiDB.sqlite") else {
            return nil
        }
        
        do
        {
            let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true]
            let _ =  try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dbURL, options: mOptions)
        
            return coordinator
        }
        catch let error
        {
            print(error)
            throw error
        }
    }
    
    init(storeCoordinator:NSPersistentStoreCoordinator, completion:((Bool)->())?)
    {
        self.persistentStoreCoordinator = storeCoordinator
        self.privateContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        self.privateContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        self.mainQueueContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        self.mainQueueContext.parentContext = self.privateContext
        
        completion?(true)
    }
    
    
    //MARK: - Work stuff
    
    func readAllElements() -> Set<DBElement>? {
        
        let fetchRequest = NSFetchRequest(entityName: "DBElement")
        do
        {
            if let resultArray = try self.mainQueueContext.executeFetchRequest(fetchRequest) as? [DBElement]
            {   if resultArray.isEmpty{
                    return nil
                }
                
                return Set(resultArray)
            }
        }
        catch let error {
            print(error)
            return nil
        }
        
        return nil
    }
    
    func readSubordinatesElementsForElementId(elementId:Int, shouldReturnObjects:Bool = false, completion:((count:Int, elements:[DBElement]?, error:NSError?)->())?)
    {
        let elementsRequest = NSFetchRequest(entityName: "DBElement")
        let predicate = NSPredicate(format: "rootElementId == %ld", elementId)
        elementsRequest.predicate = predicate
        elementsRequest.shouldRefreshRefetchedObjects = true //TODO: set this flag to false if the method is called in a loop....
        
        if shouldReturnObjects
        {
            do{
                if let requestResult = try self.privateContext.executeFetchRequest(elementsRequest) as? [DBElement]
                {
                    let count = requestResult.count
                    if count > 0{
                    
                        completion?(count: count, elements: requestResult, error: nil)
                    }
                    else
                    {
                        completion?(count: count, elements: nil, error: nil)
                    }
                }
                else
                {
                    let anError = NSError(domain: "com.Origami.DatabaseError", code: -101, userInfo: [NSLocalizedDescriptionKey:"Could not cast fetched objects to DBElement array."])
                    completion?(count: 0, elements: nil, error: anError)
                }
            }
            catch let error as NSError
            {
                completion?(count:0, elements: nil, error:error)
            }
            catch
            {
                let unKnownError = unKnownExceptionError
                completion?(count:0, elements: nil, error:unKnownError)
            }
        }
        else //return only count or error
        {
            elementsRequest.resultType = .ManagedObjectIDResultType
            do{
                if let requestResult = try self.privateContext.executeFetchRequest(elementsRequest) as? [DBElement]
                {
                    completion?(count: requestResult.count, elements: nil, error: nil)
                }
                else
                {
                    let anError = NSError(domain: "com.Origami.DatabaseError", code: -101, userInfo: [NSLocalizedDescriptionKey:"Could not cast fetched objects to NSManagedObjectId array."])
                    completion?(count: 0, elements: nil, error: anError)
                }
            }
            catch let error as NSError
            {
                completion?(count:0, elements: nil, error:error)
            }
            catch
            {
                let unKnownError = unKnownExceptionError
                completion?(count:0, elements: nil, error:unKnownError)
            }
        }
    }
    
    func readHomeDashboardElements(shouldRefetch:Bool = true, completion:( (info:(signals:[DBElement]?,favourites:[DBElement]?, other:[DBElement]?))->() )?)
    {
        self.mainQueueContext.reset()
        
        var returningValue: (signals:[DBElement]?,favourites:[DBElement]?, other:[DBElement]?) = (signals:nil, favourites:nil, other:nil)
        
        let signalsRequest = NSFetchRequest(entityName: "DBElement")
        signalsRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal"]
        signalsRequest.shouldRefreshRefetchedObjects = shouldRefetch
        signalsRequest.predicate = NSPredicate(format: "isSignal == true")
        signalsRequest.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: false)]
        do{
            if let signalElements = try self.privateContext.executeFetchRequest(signalsRequest) as? [DBElement]
            {
                if signalElements.count > 0
                {
                    returningValue.signals = signalElements
                }
            }
        }
        catch{
            
        }
        
        let favouritesRequest = signalsRequest
        favouritesRequest.shouldRefreshRefetchedObjects = shouldRefetch
        favouritesRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal", "isFavourite"]
        favouritesRequest.predicate = NSPredicate(format: "isFavourite == true")
        do{
            if let favouriteElements = try self.privateContext.executeFetchRequest(favouritesRequest) as? [DBElement]
            {
                if favouriteElements.count > 0
                {
                    returningValue.favourites = favouriteElements
                }
            }
        }
        catch{
            
        }
        
        
        let otherDashboardElementsRequest = signalsRequest
        otherDashboardElementsRequest.shouldRefreshRefetchedObjects = shouldRefetch
        otherDashboardElementsRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal", "rootElementId"]
        otherDashboardElementsRequest.predicate = NSPredicate(format: "rootElementId == 0")
        do{
            if let otherDashboardElements = try self.privateContext.executeFetchRequest(otherDashboardElementsRequest) as? [DBElement]
            {
                if otherDashboardElements.count > 0
                {
                    returningValue.other = otherDashboardElements
                }
            }
        }
        catch{
            
        }
        
        completion?(info:returningValue)
        
    }
    
    func saveElementsToLocalDatabase(elements:[Element], completion:((didSave:Bool, error:NSError?)->())?)
    {
        let singleElementRequest = NSFetchRequest(entityName: "DBElement")
        
        for anElement in elements
        {
            singleElementRequest.predicate = NSPredicate(format: "elementId == \(anElement.elementId!)")
            do{
                if let existingElements = try self.privateContext.executeFetchRequest(singleElementRequest) as? [DBElement]
                {
                    if existingElements.isEmpty{
                        
                        if let newElement = NSEntityDescription.insertNewObjectForEntityForName("DBElement", inManagedObjectContext: self.privateContext) as? DBElement
                        {
                            newElement.fillInfoFromInMemoryElement(anElement)
                        }
                        
                    }
                    else if existingElements.count == 1
                    {
                        let existingElement = existingElements.first!
                        existingElement.fillInfoFromInMemoryElement(anElement)
                    }
                    else if existingElements.count > 1
                    {
                        assert(false, "Found duplicate elements in Local Database...")
                        //TODO: delete duplicates and update to current values
                    }
                }
            }
            catch{
                
            }
        }
        
        
        if self.privateContext.hasChanges
        {
            do{
                try self.privateContext.save()
                completion?(didSave: true, error: nil)
            }
            catch let error as NSError{
                completion?(didSave: false, error: error)
            }
            catch{
                abort()
            }
        
        }
    }

    func readElementById(elementId:Int) -> DBElement?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBElement")
        fetchRequest.fetchLimit = 3
        
        return nil
    }
    
    func readElementByIdAsync(elementId:Int, completion:((DBElement?)->())?)
    {
        
    }
    
    
    
}