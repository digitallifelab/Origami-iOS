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
    //private let mainQueueContext:NSManagedObjectContext
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
        self.privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.privateContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        //self.mainQueueContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        //self.mainQueueContext.parentContext = self.privateContext
        
        completion?(true)
    }
    
    
    //MARK: - Work stuff
    
    func readAllElements() -> Set<DBElement>? {
        
        var toReturn:Set<DBElement>?
        self.privateContext.performBlockAndWait { _ in
            let fetchRequest = NSFetchRequest(entityName: "DBElement")
            do
            {
                if let resultArray = try self.privateContext.executeFetchRequest(fetchRequest) as? [DBElement]
                {   if resultArray.isEmpty{
                    return
                    }
                    
                    toReturn = Set(resultArray)
                }
            }
            catch let error {
                print(error)
                return
            }
        }
        
        return toReturn
    }
    
    /**
    Mathod is used for querying only count for creating layout of for displaying actual subordinates info.
    - Parameter elementId: an id of element to search it`s subordinate elements
    - Parameter shouldReturnObjects:
        - If *`shouldReturnObjects`* is not passed ( or passed *`false`*) - method starts fetchRequest with resuitType *`ManagedObjectIDResultType`* for faster execution
        - If *`shouldReturnObjects`* is passed *`true`* method starts fetchRequest with resultType default
    - Parameter completion: an optional closure to handle response of method
    - Returns: 
        - count of elements in optional array that sholud be returned
        - optional array of DBElement objects
        - error if fetchRequest fails or if something unusual happens
    */
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
    
    func readHomeDashboardElements(shouldRefetch:Bool = true, completion:( ((signals:[DBElement]?, favourites:[DBElement]?, other:[DBElement]?) )->() )?)
    {
        var returningValue: (signals:[DBElement]?,favourites:[DBElement]?, other:[DBElement]?) = (signals:nil, favourites:nil, other:nil)
        
        let signalsRequest = NSFetchRequest(entityName: "DBElement")
        signalsRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal"]
        signalsRequest.shouldRefreshRefetchedObjects = shouldRefetch
        signalsRequest.predicate = NSPredicate(format: "isSignal == true")
        signalsRequest.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: false)]
        
        self.privateContext.performBlockAndWait { _ in
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
        }
      
        
        let favouritesRequest = signalsRequest
        favouritesRequest.shouldRefreshRefetchedObjects = shouldRefetch
        favouritesRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal", "isFavourite"]
        favouritesRequest.predicate = NSPredicate(format: "isFavourite == true")
        self.privateContext.performBlockAndWait { _ in
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
        }
       
        
        
        let otherDashboardElementsRequest = signalsRequest
        otherDashboardElementsRequest.shouldRefreshRefetchedObjects = shouldRefetch
        otherDashboardElementsRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal", "rootElementId"]
        otherDashboardElementsRequest.predicate = NSPredicate(format: "rootElementId == 0")
        
        self.privateContext.performBlockAndWait { _ in
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
        }
        
        
        
        completion?(returningValue)
        
    }
    /**
    Method calls *`readElementById()`* on every element in a *for-in* loop.
    If Element is found - it is updated to current state, 
    Else new element is inserted in local database
    
    after *for-in* loop is finished private context saves changes if any and *`completion()`* block is called
    
    - Note: this is time expensive task
    */
    func saveElementsToLocalDatabase(elements:[Element], completion:((didSave:Bool, error:NSError?)->())?)
    {
        for anElement in elements
        {
           if let existingElement = self.readElementById(anElement.elementId!)
           {
                print("2 - changingFoundElement in database")
               
                existingElement.fillInfoFromInMemoryElement(anElement)
                        
            }
            else
            {
                print("1 - inserting new element into database...")
                if let newElement = NSEntityDescription.insertNewObjectForEntityForName("DBElement", inManagedObjectContext: self.privateContext) as? DBElement
                {
                    newElement.fillInfoFromInMemoryElement(anElement)
                }
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

    /**
    executes fetch request on private context (not main queue)
    - Returns: 
        - found DBElement object  
        - *nil* if error occured or if element with given ID was not found.
    */
    func readElementById(elementId:Int) -> DBElement?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBElement")
        let predicate = NSPredicate(format: "elementId == \(elementId)")
        fetchRequest.predicate = predicate
        
        do{
            if let elementsResult = try self.privateContext.executeFetchRequest(fetchRequest) as? [DBElement]
            {
                if elementsResult.count == 1
                {
                    return elementsResult.first!
                }
                else if elementsResult.count == 0
                {
                    return nil
                }
                else if elementsResult.count > 1
                {
                    assert(false, "readElementById  ERROR  -> Found duplicate elements in Local Database...")
                    //TODO: delete duplicate entries
                }
            }
            return nil
        }
        catch let error {
            print(error)
            return nil
        }
    }
    
    func readElementByIdAsync(elementId:Int, completion:((DBElement?)->())?)
    {
        guard let foundElement = self.readElementById(elementId) else
        {
            completion?(nil)
            return
        }
        completion?(foundElement)
    }
    
    func setFavourite(newFavValue:Bool, elementId:Int, completion:(()->())?)
    {
        guard let foundDBElement = self.readElementById(elementId) else
        {
            completion?()
            return
        }
        
        foundDBElement.isFavourite = NSNumber(bool: newFavValue)
        
        if self.privateContext.hasChanges
        {
            do{
                try self.privateContext.save()
                completion?()
                print("SAVED CHANGES after FAVOURITE element value updated")
            }
            catch let saveError{
                print("did not save privateContext after element FAVOURITE changed: ")
                print(saveError)
                completion?()
            }
            return
        }
        
        print(" ERROR while updating element FAVOURITE:   privateContextHasNoChanges")
    }
    
    func setSignal(newValue:Bool, elementId:Int, completion:(()->())?)
    {
        guard let foundDBElement = self.readElementById(elementId) else
        {
            completion?()
            return
        }
        
        foundDBElement.isSignal = NSNumber(bool: newValue)
        
        if self.privateContext.hasChanges
        {
            do{
                try self.privateContext.save()
                completion?()
                print("SAVED CHANGES after SIGNAL element value updated")
            }
            catch let saveError{
                print("did not save privateContext after element SIGNAL changed: ")
                print(saveError)
                completion?()
            }
            return
        }
        
        print(" ERROR while updating element SIGNAL: privateContextHasNoChanges")
    }
    
    
    //MARK:  - avatar previews
    func saveAvatarPreview(data:NSData, contactId:Int, completion:(()->())?)
    {
        
    }
    
    func readAvatarPreviewForContactId(contactId:Int) -> NSData?
    {
        return nil
    }
    
    private func findAvatarPreviewForUserId(userId:Int) -> DBUserAvatarPreview?
    {
        let previewFetchRequest = NSFetchRequest(entityName: "DBUserAvatarPreview")
        previewFetchRequest.predicate = NSPredicate(format: "avatarUserId == \(userId)")
        do{
            if let previews = try self.privateContext.executeFetchRequest(previewFetchRequest) as? [DBUserAvatarPreview]
            {
                if previews.count == 1
                {
                    return previews.first!
                }
            }
            return nil
        }
        catch{
            return nil
        }
        
    }
    
    func findPersonByUserName(userName:String) -> DBPerson?
    {
        let personFetshRequest = NSFetchRequest(entityName: "DBContact")
        let predicate = NSPredicate(format: "userName == \(userName)")
        personFetshRequest.predicate = predicate
        
        do{
            if let persons = try self.privateContext.executeFetchRequest(personFetshRequest) as? [DBContact]
            {
                if persons.count > 1
                {
                    //TODO: delete duplicate contacts and return single left after deletion
                }
                else if persons.count == 1
                {
                    return persons.first!
                }
                else if persons.count == 0
                {
                   
                    //try to find current User
                    let userFetchRequest = NSFetchRequest(entityName: "DBUser")
                    do{
                        if let currentUsers = try self.privateContext.executeFetchRequest(userFetchRequest) as? [DBUser]
                        {
                            if currentUsers.count == 1
                            {
                                return currentUsers.first!
                            }
                            else if currentUsers.count == 0
                            {
                                return nil
                            }
                            else if currentUsers.count > 1
                            {
                                //TODO: delete all users except currently logged in
                                return nil
                            }
                        }
                    }
                    catch let errorUser
                    {
                        print("-> ERROR while querying a person:")
                        print(errorUser)
                        return nil
                    }
                }
            }
            print("...some weird stuff happens...")
            return nil
        }
        catch let errorContact
        {
            print("-> ERROR while querying a person:")
            print(errorContact)
            return nil
        }
    }
    
}


/*
func fillInfoFromInMemoryElement(element:Element)
{
self.elementId      = element.elementId
self.rootElementId  = NSNumber(integer: element.rootElementId)
self.responsibleId  = NSNumber(integer: element.responsible)
self.title          = element.title
self.details        = element.details
self.dateChanged    = element.changeDate?.dateFromServerDateString()
self.dateCreated    = element.createDate.dateFromServerDateString()
self.dateRemind     = element.remindDate
self.dateArchived   = element.archiveDate?.dateFromServerDateString()
self.dateFinished   = element.finishDate
self.type           = NSNumber(integer:element.typeId)
self.finishState    = NSNumber(integer: element.finishState)
self.isFavourite    = NSNumber(bool:element.isFavourite)
self.isSignal       = NSNumber(bool:element.isSignal)
self.hasAttaches    = NSNumber(bool: element.hasAttaches)
}

*/