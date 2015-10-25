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
    //MARK: - Elements
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
    //MARK: ---
    func readRecentArchiverElements() -> [DBElement]?
    {
        let request = NSFetchRequest(entityName: "DBElement")
        request.predicate = NSPredicate(format: "dateArchived != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: true)]
        
        var elementsToReturn:[DBElement]?
        self.privateContext.performBlockAndWait {[unowned self] () -> Void in
            do{
                if let elements = try self.privateContext.executeFetchRequest(request) as? [DBElement]
                {
                    if !elements.isEmpty
                    {
                        elementsToReturn = elements
                    }
                }
            }
            catch let error {
                print("\nError while fetching archived elements:")
                print(error)
                return
            }
        }
        
        return elementsToReturn
    }
    
    func readRecentNonArchivedElements() -> [DBElement]?
    {
        let request = NSFetchRequest(entityName: "DBElement")
        request.predicate = NSPredicate(format: "dateArchived == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: true)]
        
        var elementsToReturn:[DBElement]?
        self.privateContext.performBlockAndWait {[unowned self] () -> Void in
            do{
                if let elements = try self.privateContext.executeFetchRequest(request) as? [DBElement]
                {
                    if !elements.isEmpty
                    {
                        elementsToReturn = elements
                    }
                }
            }
            catch let error {
                print("\nError while fetching archived elements:")
                print(error)
                return
            }
        }
        
        return elementsToReturn
    }
    
    //MARK: ---
    func readRootElementTreeForElementManagedObjectId(managedId:NSManagedObjectID) -> [DBElement]?
    {
        guard let currentElement = self.privateContext.objectWithID(managedId) as? DBElement else
        {
            return nil
        }
        
        var foundRoots = [DBElement]()
        var pendingElement:DBElement? = currentElement
        while let _ = pendingElement
        {
            if let parentFound = self.findParentElementForElement(pendingElement!)
            {
                foundRoots.append(parentFound)
                pendingElement = parentFound
                continue
            }
            pendingElement = nil
        }
        
        if foundRoots.isEmpty{
            return nil
        }
        
        return foundRoots
    }
    
    private func findParentElementForElement(element:DBElement) -> DBElement?
    {
        if let rootId = element.rootElementId?.integerValue{
           return self.readElementById(rootId)
        }
        return nil
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
    func readSubordinateElementsForElementIdAsync(elementId:Int, shouldReturnObjects:Bool = false, completion:((count:Int, elements:[DBElement]?, error:NSError?) ->())? )
    {
        let elementsRequest = NSFetchRequest(entityName: "DBElement")
        let predicate = NSPredicate(format: "rootElementId == %ld", elementId)
        elementsRequest.predicate = predicate
        elementsRequest.shouldRefreshRefetchedObjects = true //TODO: set this flag to false if the method is called in a loop....
        
        if shouldReturnObjects
        {
            dispatch_async(getBackgroundQueue_DEFAULT(), { () -> Void in
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
            })
            
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
    
    func readSubordinateElementsForDBElementIdSync(elementId:Int, shouldReturnObjects:Bool = false) -> (count:Int, elements:[DBElement]?, error:NSError?)
    {
        let elementsRequest = NSFetchRequest(entityName: "DBElement")
        
        let predicate = NSPredicate(format: "rootElementId = \(elementId) AND dateArchived = nil")
        elementsRequest.predicate = predicate
        elementsRequest.shouldRefreshRefetchedObjects = false //TODO: set this flag to false if the method is called in a loop....
        
        var returnCount = 0
        var returnError:NSError?
        
        if shouldReturnObjects
        {
            var returnElements:[DBElement]?
            
            self.privateContext.performBlockAndWait({ () -> Void in
                do{
                    if let requestResult = try self.privateContext.executeFetchRequest(elementsRequest) as? [DBElement]
                    {
                        returnCount = requestResult.count
                        if returnCount > 0
                        {
                            returnElements = requestResult
                        }
                    }
                    else
                    {
                        let anError = NSError(domain: "com.Origami.DatabaseError", code: -101, userInfo: [NSLocalizedDescriptionKey:"Could not cast fetched objects to DBElement array."])
                        returnError = anError
                    }
                }
                catch let error as NSError
                {
                    returnError = error
                }
                catch
                {
                    returnError = unKnownExceptionError
                }
            })
            
            return (count: returnCount, elements: returnElements, error: returnError)
            
        }
        else //return only count or error
        {
            elementsRequest.resultType = .ManagedObjectIDResultType
            
            self.privateContext.performBlockAndWait({ () -> Void in
                do{
                    if let requestResult = try self.privateContext.executeFetchRequest(elementsRequest) as? [NSManagedObjectID]
                    {
                        returnCount = requestResult.count
                    }
                    else
                    {
                        let anError = NSError(domain: "com.Origami.DatabaseError", code: -101, userInfo: [NSLocalizedDescriptionKey:"Could not cast fetched objects to DBElement array."])
                        returnError = anError
                    }
                }
                catch let error as NSError
                {
                    returnError = error
                }
                catch
                {
                    returnError = unKnownExceptionError
                }
            })

            return (count: returnCount, elements: nil, error: returnError)
        }
    }
    
    func readHomeDashboardElements(shouldRefetch:Bool = true, completion:( ((signals:[DBElement]?, favourites:[DBElement]?, other:[DBElement]?) )->() )?)
    {
        let bgQueue = getBackgroundQueue_CONCURRENT()
        dispatch_async(bgQueue) { () -> Void in
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
            
            dispatch_async(dispatch_get_main_queue(), { _ in
                completion?(returningValue)
            })
        }
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
               // print("title: \(existingElement.title!),\n elementID: \(existingElement.elementId!.integerValue), \n rootID: \(existingElement.rootElementId!.integerValue)")
            }
            else
            {
                print("1 - inserting new element into database...")
                if let newElement = NSEntityDescription.insertNewObjectForEntityForName("DBElement", inManagedObjectContext: self.privateContext) as? DBElement
                {
                    newElement.fillInfoFromInMemoryElement(anElement)
                    //print("title: \(newElement.title!),\n elementId: \(newElement.elementId!.integerValue), \n rootID: \(newElement.rootElementId!.integerValue)")
                }
            }
        
        }
        
        if self.privateContext.hasChanges
        {
            do
            {
                try self.privateContext.save()
                completion?(didSave: true, error: nil)
            }
            catch let error as NSError
            {
                completion?(didSave: false, error: error)
            }
            catch
            {
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
        let predicate = NSPredicate(format: "elementId = \(elementId)")
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
        dispatch_async(getBackgroundQueue_CONCURRENT()) { () -> Void in
            guard let foundElement = self.readElementById(elementId) else
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion?(nil)
                })
                
                return
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?(foundElement)
            })
            
        }
       
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
            do {
                try self.privateContext.save()
                completion?()
                print("SAVED CHANGES after SIGNAL element value updated")
            }
            catch let saveError {
                print("did not save privateContext after element SIGNAL changed: ")
                print(saveError)
                completion?()
            }
            return
        }
        
        print(" ERROR while updating element SIGNAL: privateContextHasNoChanges")
    }
    
    func deleteAllElements()
    {
        let allElementsRequest = NSFetchRequest(entityName: "DBElement")
        allElementsRequest.includesPropertyValues = false
        if #available (iOS 9.0, *)
        {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: allElementsRequest)
            do
            {
                try self.persistentStoreCoordinator.executeRequest(deleteRequest, withContext: self.privateContext)
            }
            catch
            {
                
            }
        }
        else //pre iOS 9
        {
            do
            {
                if let allElements = try self.privateContext.executeFetchRequest(allElementsRequest) as? [DBElement]
                {
                    for anElement in allElements
                    {
                        self.privateContext.deleteObject(anElement)
                    }
                }
            }
            catch
            {
                
            }
        }
        
        if self.privateContext.hasChanges
        {
            do{
                try self.privateContext.save()
                print("Deleted all elements from local Database...")
            }
            catch{
                
            }
        }
    }
    
    //MARK: - Messages
    func saveChatMessagesToLocalDataBase(messages:[Message], completion:((Bool, error:NSError?) -> ())?)
    {
        guard !messages.isEmpty else
        {
            completion?(true, error:nil)
            return
        }
        
        var mutableSet = Set<DBMessageChat>()
        for aMessage in messages
        {
            if let existingMessage = self.readChatMessageById(aMessage.messageId)
            {
                existingMessage.fillInfoFromMessageObject(aMessage)
                mutableSet.insert(existingMessage)
            }
            else
            {
                print("inserting new message into database")
             
                if let message = NSEntityDescription.insertNewObjectForEntityForName("DBMessageChat", inManagedObjectContext: self.privateContext) as? DBMessageChat
                {
                    message.fillInfoFromMessageObject(aMessage)
                    mutableSet.insert(message)
                }
            }
        }
        
        if mutableSet.count > 0
        {
            if let anyMessage = mutableSet.first, elementId = anyMessage.elementId?.integerValue
            {
                //link message to existing element if found
                if let existingElement = self.readElementById(elementId)
                {
                    if let existingSet = existingElement.messages as? Set<DBMessageChat>
                    {
                        let newMessagesSet = existingSet.union(mutableSet)
                        existingElement.messages = newMessagesSet
                    }
                    else
                    {
                        existingElement.messages = mutableSet
                    }
                }
            }
        }
        
        if self.privateContext.hasChanges
        {
            do{
                try self.privateContext.save()
                print("\n->did save Context after messages inserted or updated.")
                completion?(true, error:nil)
            }
            catch let error as NSError{
                print("\n->did NOT save Context after messages inserted or updated.")
                print("Error: \n\(error)")
                completion?(false, error:error)
            }
            
            return
        }
        print("\n->did NOT save Context after messages inserted or updated.")
        print("Reason: context has NO CHANGES\n")
        completion?(false, error:nil)
    }
    
    func readChatMessageById(messageId:Int) -> DBMessageChat?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBMessageChat")
        let predicate = NSPredicate(format: "messageId = \(messageId)")
        fetchRequest.predicate = predicate
        
        do{
            if let messagesResult = try self.privateContext.executeFetchRequest(fetchRequest) as? [DBMessageChat]
            {
                if messagesResult.count == 1
                {
                    return messagesResult.first!
                }
                else if messagesResult.count == 0
                {
                    return nil
                }
                else if messagesResult.count > 1
                {
                    assert(false, "readChatMessageById  ERROR  -> Found duplicate messages in Local Database...")
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
    
    func readLastMessagesForHomeDashboard(completion:( ([DBMessageChat]?, error:NSError?) -> ())? )
    {
        let lastMessagesRequest = NSFetchRequest(entityName: "DBMessageChat")
        let sortById = NSSortDescriptor(key: "messageId", ascending: false)
        //let sortByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        lastMessagesRequest.sortDescriptors = [sortById]
        lastMessagesRequest.fetchLimit = 3
        
        self.privateContext.performBlock { () -> Void in
            do{
                if let messages = try self.privateContext.executeFetchRequest(lastMessagesRequest) as? [DBMessageChat]
                {
                    if !messages.isEmpty
                    {
                        let sortedMessages = messages.sort({ (message1, message2) -> Bool in
                            return message1.messageId!.integerValue < message2.messageId!.integerValue
                        })
                        //debug
                        for aDBMessage in sortedMessages
                        {
                            print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
                        }
                        
                        completion?(sortedMessages, error:nil)
                    }
                    else{
                        completion?(nil, error:nil)
                    }
                }
            }
            catch let error as NSError{
                completion?(nil, error:error)
            }
        }
    }
    /**
     - Returns: 
        - nil messages if no messages were found
        - error and nil messages if something bad happens
        - array of DBMessage if found at least one message
     */
    func readLastMessagesForElementById(elementId:Int, fetchSize:Int, completion:(([DBMessageChat]?, error:NSError?) -> ())?)
    {
        let lastMessagesRequest = NSFetchRequest(entityName: "DBMessageChat")
        let sort = NSSortDescriptor(key: "dateCreated", ascending: true)
        let predicate = NSPredicate(format: "elementId = \(elementId)")
        
        lastMessagesRequest.predicate = predicate
        lastMessagesRequest.sortDescriptors = [sort]
        lastMessagesRequest.fetchLimit = fetchSize
        
        self.privateContext.performBlock { () -> Void in
            do{
                if let messages = try self.privateContext.executeFetchRequest(lastMessagesRequest) as? [DBMessageChat]
                {
                    if !messages.isEmpty
                    {
                        //debug
                        for aDBMessage in messages
                        {
                            print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
                        }
                        completion?(messages, error:nil)
                    }
                    else
                    {
                        completion?(nil, error:nil)
                    }
                }
            }
            catch let error as NSError
            {
                completion?(nil, error:error)
            }
        }
    }
    
    
    func deleteAllChatMessages()
    {
        let allElementsRequest = NSFetchRequest(entityName: "DBMessageChat")
        allElementsRequest.includesPropertyValues = false
        if #available (iOS 9.0, *)
        {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: allElementsRequest)
            do
            {
                try self.persistentStoreCoordinator.executeRequest(deleteRequest, withContext: self.privateContext)
            }
            catch
            {
                
            }
        }
        else //pre iOS 9
        {
            do
            {
                if let allMessages = try self.privateContext.executeFetchRequest(allElementsRequest) as? [DBMessageChat]
                {
                    for aChatMessage in allMessages
                    {
                        self.privateContext.deleteObject(aChatMessage)
                    }
                }
            }
            catch
            {
                
            }
        }
        
        if self.privateContext.hasChanges
        {
            do{
                try self.privateContext.save()
                print("Deleted all CHAT Messages from local Database...")
            }
            catch{
                
            }
        }

    }
    //MARK: - avatar previews
    
    /**
    calls *`saveAvatarPreview()`* in a `for-in` loop, saves private context after loop end
    - Parameter infoArray: array of tuples to save
    - Parameter completion:
        - has `false` if an empty infoArray was passed to method
        - has `false` if privateContext has no changes
        - has `false` if privateContext did catch an error while trying to save
        - has `true` if privateContext did save
    */
    func batchSaveAvatars(infoArray:[(data:NSData, userId:Int, fileName:String)], completion:((Bool)->())?)
    {
        guard !infoArray.isEmpty else {
            completion?(false)
            return
        }
        
        for aTuple in infoArray
        {
            self.saveAvatarPreview(aTuple.data, forUserId: aTuple.userId, fileName: aTuple.fileName)
        }
        
        if self.privateContext.hasChanges{
            do{
                try self.privateContext.save()
                completion?(true)
            }
            catch let saveError{
                print(saveError)
                completion?(false)
            }
            return
        }
        
        completion?(false)
    }
    
    /**
    - if existing DBUserAvatarPreview was found by calling *`findAvatarPreviewForUserId()`*
    an update occurs
    - if not found - new DBUserAvatarPreview entity is created in privateContext
    - Parameter data: image preview data object
    - Parameter forUserId: contactId or userId(if current user`s avatar preview is saved)
    - Parameter fileName: local stored name with extension for a file that actually stores full size image data on disc
    */
    func saveAvatarPreview(data:NSData, forUserId:Int, fileName:String)
    {
        let localContext = self.privateContext
        
        localContext.performBlock { () -> Void in
            if let existingPreview = self.findAvatarPreviewForUserId(forUserId), existingImageData = existingPreview.avatarPreviewData
            {
                if existingImageData.hashValue != data.hashValue
                {
                    existingPreview.avatarPreviewData = data
                    print("edited existing avatar preview IMAGE DATA")
                }
                if existingPreview.fileName != fileName
                {
                    existingPreview.fileName = fileName
                    print("edited existing avatar preview FILE NAME")
                }
            }
            else
            {
                if let
                    newAvatarPreview = NSEntityDescription.insertNewObjectForEntityForName("DBAvatarPreview", inManagedObjectContext: self.privateContext) as? DBAvatarPreview
                {
                    newAvatarPreview.fileName = fileName
                    newAvatarPreview.avatarUserId = forUserId
                    newAvatarPreview.avatarPreviewData = data
                    print("inserted new avatar preview")
                }
            }
        }
        
    }
    
    func readAvatarPreviewForContactId(contactId:Int) -> NSData?
    {
        guard let avatarPreview = self.findAvatarPreviewForUserId(contactId) else
        {
            return nil
        }
        
        if let _ = avatarPreview.avatarPreviewData
        {
            return avatarPreview.avatarPreviewData
        }
        print("\n->no file data for avatar previewData")
        return nil
    }
    
    private func findAvatarPreviewForUserId(userId:Int) -> DBAvatarPreview?
    {
        let previewFetchRequest = NSFetchRequest(entityName: "DBAvatarPreview")
        previewFetchRequest.predicate = NSPredicate(format: "avatarUserId == \(userId)")
        do{
            if let previews = try self.privateContext.executeFetchRequest(previewFetchRequest) as? [DBAvatarPreview]
            {
                if previews.count == 1
                {
                    return previews.first!
                }
                else if previews.count == 0
                {
                    return nil
                }
                else if previews.count > 1
                {
                    return previews.last!
                }
            }
            else
            {
                return nil
            }
        }
        catch let fetchError
        {
            print(fetchError)
            return nil
        }
        
        return nil
    }
    
    /**
     private context performs async block on it`s queue
     - Returns:
        - dictionary of found images
        - error if fetch request fails
        - nil if at least one DBAvatarPreview object was found
     - Note: completion block may be called on any queue
     
    */
    func preloadSavedAvatarPreviewsToDataSource(completion:(([Int:UIImage]?, error:NSError?) -> ())?)
    {
        let previewsRequest = NSFetchRequest(entityName: "DBAvatarPreview")
        previewsRequest.propertiesToFetch = ["avatarUserId","avatarPreviewData"]
        let privateContextLocal = self.privateContext
        privateContextLocal.performBlock { () -> Void in
            do{
                if let previewObjects = try privateContextLocal.executeFetchRequest(previewsRequest) as?[DBAvatarPreview] where !previewObjects.isEmpty
                {
                    var returningDict = [Int:UIImage]()
                    for aPreview in previewObjects
                    {
                        if let avatarData = aPreview.avatarPreviewData, userId = aPreview.avatarUserId?.integerValue, image = UIImage(data: avatarData)
                        {
                            returningDict[userId] = image
                        }
                    }
                    if !returningDict.isEmpty
                    {
                        completion?(returningDict, error:nil)
                        return
                    }
                }
                //return nil, if images not founs and if imagePreview containers not found
                completion?(nil, error:nil)
                
            }
            catch let fetchError as NSError {
                completion?(nil, error:fetchError)
            }
        }
        
    }
    
    //MARK: - Person
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
    
    func findPersonById(userId:Int) -> (db:DBPerson?, memory:Person?)
    {
        if let aUserId = DataSource.sharedInstance.user?.userId
        {
            if aUserId == userId
            {
                return (db:nil, memory:DataSource.sharedInstance.user)
            }
            else if let foundContact = self.readContactById(userId)
            {
                return (db:foundContact, memory:nil)
            }
        }
        
        return (db:nil, memory:nil)
    }
    
    //MARK: - Contacts
    
    func saveContactsToDataBase(contacts:[Contact], completion:((Bool, error:NSError?)->())?)
    {
        guard !contacts.isEmpty else
        {
            completion?(false, error:NSError(domain: "com.Origami.EmptyValue.Error", code: -3030, userInfo: [NSLocalizedDescriptionKey:"Tried to insert empty contacts to local database."]))
            return
        }
        for aContact in contacts
        {
            if let existingContact = self.readContactById(aContact.contactId)
            {
                print("Updating Contact: \(existingContact.contactId!)")
                existingContact.fillInfoFromContact(aContact)
            }
            else
            {
                print("Inserting new Contact")
                if let newContact = NSEntityDescription.insertNewObjectForEntityForName("DBContact", inManagedObjectContext: self.privateContext) as? DBContact
                {
                    newContact.fillInfoFromContact(aContact)
                }
            }
        }
        
        if self.privateContext.hasChanges
        {
            do
            {
                try self.privateContext.save()
                print(" Did save context after SavingContacts...")
                completion?(true, error: nil)
            }
            catch let contextSaveError as NSError
            {
                print(" --- !!!!  Did NOT context after SavingContacts : ")
                print(contextSaveError)
                completion?(false, error: contextSaveError)
            }
        }
        else
        {
            print("\n ->->->-> PrivateContext has no changes after contacts saving.")
            completion?(false, error:nil)
        }
        
        
    }

    func readContactById(contactId:Int) -> DBContact?
    {
        let contactRequest = NSFetchRequest(entityName: "DBContact")
        contactRequest.predicate = NSPredicate(format: "contactId = \(contactId)")
        do{
            if let contactsResult = try self.privateContext.executeFetchRequest(contactRequest) as? [DBContact]
            {
                let contactsCount = contactsResult.count
                if contactsCount == 1
                {
                    return contactsResult.first
                }
                else if contactsCount == 0
                {
                    return nil
                }
                else
                {
                    //get last returned contact and delete the rest
                    var severalContacts = contactsResult
                    let toReturn = severalContacts.removeLast()
                    
                    for aContact in severalContacts
                    {
                        self.privateContext.deleteObject(aContact)
                    }
                    //save context after deletion will happen at some point in time, not here, because this method potentially will be called in loops
                    return toReturn
                }
            }
            
            return nil
        }
        catch let error as NSError{
            print("Could not execute Single Contact Fetch:")
            print(error)
            return nil
        }
    }
    
    
    
    
    
}
