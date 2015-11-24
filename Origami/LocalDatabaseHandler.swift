//
//  LocalDataBaseHandler.swift
//  Origami
//
//  Created by CloudCraft on 21.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class LocalDatabaseHandler
{    
    private let privateContext:NSManagedObjectContext
    private var pMainQueueContext:NSManagedObjectContext?
    var mainQueueContext:NSManagedObjectContext {
        if let _ = self.pMainQueueContext
        {
            return self.pMainQueueContext!
        }
        
        self.pMainQueueContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.pMainQueueContext?.parentContext = self.privateContext
        return self.mainQueueContext
    }
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
    
    
    //MARK: - 
    func getPrivateContext() -> NSManagedObjectContext
    {
        return self.privateContext
    }
    
    func savePrivateContext(completion:(NSError? ->())?)
    {
        let lvContext = self.privateContext
        
        if lvContext.hasChanges
        {
            do
            {
                try lvContext.save()
                completion?(nil)
                print(" ---- didSavePrivateContext ---- ")
            }
            catch let saveError as NSError
            {
                completion?(saveError)
            }
        }
        else
        {
            completion?(nil)
        }
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
        request.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: false)]
        
        var elementsToReturn:[DBElement]?
        let lvContext = self.privateContext
        
        lvContext.performBlockAndWait { _ in
            do{
                if let elements = try lvContext.executeFetchRequest(request) as? [DBElement]
                {
                    if !elements.isEmpty
                    {
                        elementsToReturn = elements
                    }
                }
            }
            catch let error
            {
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
        request.predicate = NSPredicate(format: "dateArchived = nil")
        request.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: false)]
        
        var elementsToReturn:[DBElement]?
        let lvContext = self.privateContext
        lvContext.performBlockAndWait { _ in
            do{
                if let elements = try lvContext.executeFetchRequest(request) as? [DBElement]
                {
                    if !elements.isEmpty
                    {
                        elementsToReturn = elements
                    }
                }
            }
            catch let error
            {
                print("\nError while fetching archived elements:")
                print(error)
                return
            }
        }
        
        return elementsToReturn
    }
    
    //MARK: ---
    
    func readElementsByUserId(userId:Int, archived:Bool, elementType:ElementOptions, completion:((result: (owned:[DBElement]?, participating:[DBElement]?)) -> ())?)
    {
        let optionsConverter = ElementOptionsConverter()
        
        let context = self.privateContext
        let sortByDateChanged = NSSortDescriptor(key: "dateChanged", ascending: false)
        let ownedElementsRequest = NSFetchRequest(entityName: "DBElement")
        
        let userIdFilterPredicateString = (elementType == .Task) ? "responsibleId = \(userId)" : "creatorId = \(userId)"
        let creatorIdPredicate = NSPredicate(format: "\(userIdFilterPredicateString)")
       
        let archivedString = (archived) ? "dateArchived != nil" : "dateArchived = nil"
        let archivedPredicate = NSPredicate(format: archivedString)
        
        let predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [creatorIdPredicate, archivedPredicate])
        ownedElementsRequest.predicate = predicate
        ownedElementsRequest.sortDescriptors = [sortByDateChanged]
        
        let participatingRequest = NSFetchRequest(entityName: "DBElement")
        
        let userIdFilterUnownedPredicateString = (elementType == .Task) ? "responsibleId != \(userId) AND creatorId = \(userId)" : "creatorId != \(userId)"
        let participatingPredicate = NSPredicate(format:"\(userIdFilterUnownedPredicateString)")
        
        let predicateParticipating = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [participatingPredicate, archivedPredicate])
        participatingRequest.predicate = predicateParticipating
        participatingRequest.sortDescriptors = [sortByDateChanged]
        
        var ownedElements:[DBElement]?
        var participatingElements:[DBElement]?
        
        
        context.performBlockAndWait { _ in
            do
            {
                if let foundOwnedElements = try context.executeFetchRequest(ownedElementsRequest) as? [DBElement]
                {
                    if elementType == .ReservedValue1
                    {
                        ownedElements = foundOwnedElements
                        return
                    }
                    else if elementType == .ReservedValue2
                    {
                        ownedElements = foundOwnedElements.filter() { (anElement) in
                            return anElement.isSignal!.boolValue
                        }
                        return
                    }
                    
                    ownedElements = foundOwnedElements.filter(){ (anElement) in
                        
                        if let currentElementType = anElement.type?.integerValue
                        {
                            if optionsConverter.isOptionEnabled(elementType, forCurrentOptions: currentElementType)
                            {
                                return true
                            }
                        }
                        return false
                    }
                }
            }
            catch
            {
                return
            }
        }
        
        context.performBlockAndWait { _ in
            do
            {
                if let foundElements = try context.executeFetchRequest(participatingRequest) as? [DBElement]
                {
                    if elementType == .ReservedValue1
                    {
                        participatingElements = foundElements
                        return
                    }
                    else if elementType == .ReservedValue2
                    {
                        participatingElements = foundElements.filter() { (anElement) in
                            return anElement.isSignal!.boolValue
                        }
                        return
                    }
                    
                    participatingElements = foundElements.filter() { (anElement) in
                        if let currentElementType = anElement.type?.integerValue
                        {
                            if optionsConverter.isOptionEnabled(elementType, forCurrentOptions: currentElementType)
                            {
                                return true
                            }
                        }
                        return false
                    }
                }
            }
            catch
            {
                return
            }
        }
        
        completion?(result: (owned: ownedElements, participating: participatingElements))
        
        
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
     Method is used for querying only count for creating layout of for displaying actual subordinates info.
     - Parameter elementId: an id of element to search it`s subordinate elements
     - Parameter forMainQueue:  by default is *false*, this means objecta ere fetched by private queue ManagedObjectContext, *true* sets MainQueConcurrency type managed object context to be alloacted and fetched objects.
     - Parameter completion: an optional closure to handle response of method
     - Returns:
     - count of elements in optional array that sholud be returned
     - optional array of DBElement objects
     - error if fetchRequest fails or if something unusual happens
     */
    func readSubordinateElementsForDBElementId(elementId:Int, forMainQueue:Bool = false, completion:((count:Int, elements:[DBElement]?, error:NSError?) ->())? = nil) //-> (count:Int, elements:[DBElement]?, error:NSError?)
    {
        let elementsRequest = NSFetchRequest(entityName: "DBElement")
        
        let predicate = NSPredicate(format: "rootElementId = \(elementId) AND dateArchived = nil")
        elementsRequest.predicate = predicate
        elementsRequest.shouldRefreshRefetchedObjects = true
        
        var returnCount = 0
        var returnError:NSError?
        let context = NSManagedObjectContext(concurrencyType: (forMainQueue) ? .MainQueueConcurrencyType  : .PrivateQueueConcurrencyType)
        context.parentContext = self.privateContext
        
       
            var returnElements:[DBElement]?
            
            context.performBlock/*AndWait*/(){ () -> Void in
                do{
                    elementsRequest.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: false)]
                    
                    if let requestResult = try context.executeFetchRequest(elementsRequest) as? [DBElement]
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
                catch let error
                {
                    returnError = error as NSError
                }
                
                completion?(count: returnCount, elements: returnElements, error: returnError)
            }
            
            //return (count: returnCount, elements: returnElements, error: returnError)
    }
    
    /**
     Performs fetch request on main queue context. Used for returning real Elements for CollectionView DataSource and anywhere else if needed
     - Throws: when no subordinate *DBElement*  found or any error happens
     */
    func subordinateElementsForElementId(elementId:Int) throws -> [NSManagedObjectID]
    {
        let lvContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        lvContext.parentContext = self.privateContext
        
        let request = NSFetchRequest(entityName: "DBElement")
        request.sortDescriptors = [NSSortDescriptor(key: "dateChanged", ascending: true)]
        request.predicate = NSPredicate(format: "rootElementId = \(elementId)")
        request.resultType = .ManagedObjectIDResultType
        
        var toReturnElements:[NSManagedObjectID]?
        
        lvContext.performBlockAndWait() {
            do
            {
                if let subordinates = try lvContext.executeFetchRequest(request) as? [NSManagedObjectID] where subordinates.count > 0
                {
                    toReturnElements = subordinates
                }
            }
            catch let error
            {
                print("error for main queue subordinates query:")
                print(error)
            }
        }
        
        if let _ = toReturnElements
        {
            return toReturnElements!
        }
        throw OrigamiError.NotFoundError(message: "No Subordinate Elements wer Found")
    }
    
    func countSubordinatesForElementByManagedObjectId(managedID:NSManagedObjectID) -> Int
    {
        let context = self.privateContext
        var returnCount = 0
        context.performBlockAndWait(){
            if let element = context.objectWithID(managedID) as? DBElement, elementId = element.elementId where elementId.integerValue > 0
            {
                let fetchRequest = NSFetchRequest(entityName: "DBElement")
                fetchRequest.resultType = .CountResultType
                fetchRequest.predicate = NSPredicate(format:"rootElementId = %@", elementId)
                
                do{
                    if let lvCount = try context.executeFetchRequest(fetchRequest) as? [Int]
                    {
                        print("subordinates count: \(lvCount)")
                        returnCount = lvCount.first!
                    }
                }
                catch let fetchError
                {
                    print("fetch count error:")
                    print(fetchError)
                }
            }
        }
        
        return returnCount
    }
    
    func readHomeDashboardElements(shouldRefetch:Bool = true, completion:( ((signals:[NSManagedObjectID]?, favourites:[NSManagedObjectID]?, other:[NSManagedObjectID]?) )->() )? = nil)
    {
        let bgQueue = getBackgroundQueue_DEFAULT()
        dispatch_async(bgQueue) { () -> Void in
            var returningValue: (signals:[NSManagedObjectID]?,favourites:[NSManagedObjectID]?, other:[NSManagedObjectID]?) = (signals:nil, favourites:nil, other:nil)
            
            let dateChangedDescriptor = NSSortDescriptor(key: "dateChanged", ascending: false)
            let signalsRequest = NSFetchRequest(entityName: "DBElement")
            signalsRequest.resultType = NSFetchRequestResultType.ManagedObjectIDResultType
            //signalsRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal"]
            signalsRequest.shouldRefreshRefetchedObjects = shouldRefetch
            signalsRequest.predicate = NSPredicate(format: "isSignal = true AND dateArchived = nil")
            signalsRequest.sortDescriptors = [dateChangedDescriptor]
            
            let context = self.privateContext
            
            context.performBlockAndWait { _ in
                do{
                    if let signalElements = try context.executeFetchRequest(signalsRequest) as? [NSManagedObjectID]
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
            //favouritesRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal", "isFavourite"]
            favouritesRequest.predicate = NSPredicate(format: "isFavourite = true AND dateArchived = nil")
            favouritesRequest.sortDescriptors = [dateChangedDescriptor]
            favouritesRequest.resultType = .ManagedObjectIDResultType
            
            context.performBlockAndWait { _ in
                do{
                    if let favouriteElements = try context.executeFetchRequest(favouritesRequest) as? [NSManagedObjectID]
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
            otherDashboardElementsRequest.resultType = .ManagedObjectIDResultType
            //otherDashboardElementsRequest.propertiesToFetch = ["title", "details", "finishState", "type", "isSignal", "rootElementId"]
            otherDashboardElementsRequest.predicate = NSPredicate(format: "rootElementId = 0 AND dateArchived = nil")
            otherDashboardElementsRequest.sortDescriptors = [dateChangedDescriptor]
            
            context.performBlockAndWait { _ in
                do{
                    if let otherDashboardElements = try context.executeFetchRequest(otherDashboardElementsRequest) as? [NSManagedObjectID]
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
            
            
            
            dispatch_async(dispatch_get_main_queue()) { _ in
                completion?(returningValue)
            }
//                let mainQueueContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
//                mainQueueContext.parentContext = context
//                
//                mainQueueContext.performBlock()
//                {
//                    var toReturnCollectionInfo:(signals:[DBElement]?, favourites:[DBElement]?, other:[DBElement]?) = (signals:nil, favourites:nil, other:nil)
//                    //fill Signals
//                    if let signalIDs = returningValue.signals
//                    {
//                        var signalsArray = [DBElement]()
//                        for anId in signalIDs
//                        {
//                            let _ = mainQueueContext.objectWithID(anId)
//                            
//                            if let aSignal = mainQueueContext.objectRegisteredForID(anId) as? DBElement
//                            {
//                                print(aSignal.title)
//                                print(aSignal.details)
//                                print(aSignal.dateCreated)
//                                signalsArray.append(aSignal)
//                            }
//                        }
//                        if !signalsArray.isEmpty
//                        {
//                            toReturnCollectionInfo.signals = signalsArray
//                        }
//                    }
//                    
//                    //fill Favourites
//                    if let favouriteIDs = returningValue.favourites
//                    {
//                        var favArray = [DBElement]()
//                        for anId in favouriteIDs
//                        {
//                            let _ = mainQueueContext.objectWithID(anId)
//                            
//                            if let aFavouurite = mainQueueContext.objectRegisteredForID(anId) as? DBElement
//                            {
//                                print(aFavouurite.isSignal)
//                                print(aFavouurite.details)
//                                print(aFavouurite.title)
//                                print(aFavouurite.dateCreated)
//                                favArray.append(aFavouurite)
//                            }
//                        }
//                        if !favArray.isEmpty
//                        {
//                            toReturnCollectionInfo.favourites = favArray
//                        }
//                    }
//                    
//                    //fill other
//                    if let otherIDs = returningValue.other
//                    {
//                        var othersArray = [DBElement]()
//                        for anId in otherIDs
//                        {
//                            let _ = mainQueueContext.objectWithID(anId)
//                            if let anOther = mainQueueContext.objectRegisteredForID(anId) as? DBElement
//                            {
//                                print(anOther.isSignal)
//                                print(anOther.details)
//                                print(anOther.title)
//                                print(anOther.dateCreated)
//                                othersArray.append(anOther)
//                            }
//                        }
//                        if !othersArray.isEmpty
//                        {
//                            toReturnCollectionInfo.other = othersArray
//                        }
//                    }
//                    completion?(toReturnCollectionInfo)
//                }
            
            //}
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
                //print("2 - changingFoundElement in database")
               
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
            let context = self.privateContext
            context.performBlock({ () -> Void in
                do
                {
                    try context.save()
                    completion?(didSave: true, error: nil)
                }
                catch let error as NSError
                {
                    completion?(didSave: false, error: error)
                }
            })
        }
        else
        {
            completion?(didSave: false, error: nil)
        }
    }

    /**
    executes fetch request on private context (not main queue)
    - Returns: 
        - found DBElement object  
        - *nil* if error occured or if element with given ID was not found.
    */
    @warn_unused_result func readElementById(elementId:Int) -> DBElement?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBElement")
        let predicate = NSPredicate(format: "elementId = \(elementId)")
        fetchRequest.predicate = predicate
        
        var elementToReturn:DBElement?
       
            let context = self.privateContext
            context.performBlockAndWait(){ _ in
                
                do{
                    if let elementsResult = try self.privateContext.executeFetchRequest(fetchRequest) as? [DBElement]
                    {
                        if elementsResult.count == 1
                        {
                            elementToReturn = elementsResult.first!
                        }
                        else if elementsResult.count == 0
                        {
                            //print("no element found for id: \(elementId)\n")
                            
                        }
                        else if elementsResult.count > 1
                        {
                            assert(false, "readElementById  ERROR  -> Found duplicate elements in Local Database...")
                            //TODO: delete duplicate entries
                            var elements = elementsResult
                            let toReturn = elements.removeLast()
                            elementToReturn = toReturn
                            for anElement in elements
                            {
                                context.deleteObject(anElement)
                            }
                            
                            do
                            {
                                try context.save()
                            }
                            catch let saveError
                            {
                                print("did not save context after deleting duplicate entries:")
                                print(saveError)
                            }
                        }
                    }
                }
                catch let error
                {
                    print(error)
                }
            }
        
        return elementToReturn
    
    }
    
    func readElementByIdAsync(elementId:Int, completion:((DBElement?)->())?)
    {
        let bgOpUserInitiated = NSBlockOperation() {
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
        
        if #available(iOS 9.0, *)
        {
            bgOpUserInitiated.qualityOfService = NSQualityOfService.UserInitiated
        }
        else
        {
            bgOpUserInitiated.queuePriority = .High
        }
        
        let backgroundQueue = NSOperationQueue()
        backgroundQueue.maxConcurrentOperationCount = 2
        
        backgroundQueue.addOperation(bgOpUserInitiated)
    }
    
    func readAllElementIDs() throws -> Set<Int>
    {
        let fetchRequest = NSFetchRequest(entityName: "DBElement")
        fetchRequest.propertiesToFetch = ["elementId"]
    
        let context = self.privateContext
        
        var errorToThrow:ErrorType?
        var elementIDsToReturn = Set<Int>()
        
        context.performBlockAndWait { () -> Void in
            do
            {
                if let resultElements = try context.executeFetchRequest(fetchRequest) as? [DBElement]
                {
                    if resultElements.count > 0
                    {
                        var setToReturnLocal = Set<Int>()
                        for anElement in resultElements
                        {
                            if let elId = anElement.elementId?.integerValue
                            {
                                setToReturnLocal.insert(elId)
                            }
                        }
                        elementIDsToReturn = setToReturnLocal
                    }
                    else
                    {
                        errorToThrow = OrigamiError.NotFoundError(message: "No Elements Found In Database")
                    }
                }
            }
            catch let fetchError
            {
                errorToThrow = fetchError
            }
        }
        
        if let _ =  errorToThrow
        {
            throw errorToThrow!
        }
        
        if !elementIDsToReturn.isEmpty
        {
            return elementIDsToReturn
        }
        throw OrigamiError.NotFoundError(message: "No Elements Found In Database")
    }
    
    func readAllElementsForVisualization() -> Set<DBElement>?
    {
        let context = self.privateContext
        
        let fetchVisualizableElements = NSFetchRequest(entityName: "DBElement")
        
        var foundElements:[DBElement]?
        context.performBlockAndWait() {
            
            do
            {
                if let allElementsInDb = try context.executeFetchRequest(fetchVisualizableElements) as? [DBElement] where allElementsInDb.count > 0
                {
                    foundElements = allElementsInDb
                }
            }
            catch let fetchError
            {
                print(" -> readAllElementsForVisualization _ > fetch error:")
                print(fetchError)
            }
        }
        
        if let elementsToReturn = foundElements
        {
            return Set(elementsToReturn)
        }
        
        return nil
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
    
    func deleteElementById(elementId:Int, shouldSaveContext:Bool = false, completion:((Bool, error:NSError?)->())? = nil)
    {
        let lvContext = self.privateContext
        if let foundElementToDelete = self.readElementById(elementId)
        {
            let managedObjectId = foundElementToDelete.objectID
            
            lvContext.performBlockAndWait(){_ in
                if let element = lvContext.objectWithID(managedObjectId) as? DBElement
                {
                    lvContext.deleteObject(element)
                }
                
                
                if shouldSaveContext
                {
                    if lvContext.hasChanges
                    {
                        do{
                            try lvContext.save()
                            print("Private Context did save after deleting DBElement")
                            completion?(true, error: nil)
                        }
                        catch let saveError as NSError {
                            print("Private Context did NOT save after deleting DBElement:  Error")
                            completion?(false, error : saveError)
                        }
                    }
                    else
                    {
                        print("Private Context did NOT save after deleting DBElement:  No Changes to Context")
                        completion?(false, error: nil)
                    }
                    return
                }
                completion?(true, error:nil)
            }
        }
        else
        {
            print("-> LocalDatabasehandler   DID NOT FIND ELEMEENT TO DELETE....")
            completion?(false, error:nil)
        }
       
    }
    
    func deleteElementsByIds(elementIds:Set<Int>)
    {
        for anElementId in elementIds
        {
            self.deleteElementById(anElementId)
        }
        
        if self.privateContext.hasChanges
        {
            let context = self.privateContext
            context.performBlockAndWait({ () -> Void in
               
                do{
                    try context.save()
                }
                catch let saveError
                {
                    print("context DID NOT SAVE after batch deletion elements:")
                    print(saveError)
                }
            })
        }
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
                print("Deleted all Elements from local Database...")
            }
            catch{
                
            }
        }
    }
    
    //MARK: - Messages
    
    /**
    During saving messages the method also tryes to find target element and associate given messages to it
    
    - error if empty messages
    - error if privateContext throws while tryig to save changes to persistent store
    - *true* only if context did save after changes
    */
    func saveChatMessagesToLocalDataBase(messages:[Message], completion:((Bool, error:NSError?) -> ())?)
    {
        guard !messages.isEmpty else
        {
            completion?(false, error:nil)
            return
        }
        
        let lvContext = self.privateContext
        
        lvContext.performBlockAndWait { _ in
            for aMessage in messages
            {
                if let existingMessage = self.readChatMessageById(aMessage.messageId)
                {
                    existingMessage.fillInfoFromMessageObject(aMessage)
                }
                else
                {
                    //print("inserting new message into database")
                    
                    if let message = NSEntityDescription.insertNewObjectForEntityForName("DBMessageChat", inManagedObjectContext: self.privateContext) as? DBMessageChat
                    {
                        message.fillInfoFromMessageObject(aMessage)
                    }
                }
            }
        }
        
        if lvContext.hasChanges
        {
            do{
                
                try lvContext.save()
                print("\n->did <<<<< SAVE >>>>> Context after messages inserted or updated.")
                
                completion?(true, error:nil)
            }
            catch let error as NSError{
                print("\n->did NOT save Context after messages inserted or updated.")
                print("Error: \n\(error)")
                completion?(false, error:error)
            }
            catch{
                print("UnknownError while saving privateContext")
                completion?(false, error:unKnownExceptionError)
            }
            
            
        }
        else
        {
            print("\n->did NOT save Context after messages inserted or updated.")
            print("Reason: context has NO CHANGES\n")
            completion?(false, error:nil)
        }
    }
    
    func performMessagesAndElementsPairing(completion:(()->())?)
    {
        if let messagesWithoutTargetElement = self.getMessagesIdsForMessagesWithoutElement()
        {
            for (elementId, aMessages) in messagesWithoutTargetElement
            {
                if let element = self.readElementById(elementId.integerValue)
                {
                    element.addMessages(Set(aMessages))
                }
            }
        }
        
        let context = self.privateContext
        if context.hasChanges
        {
            context.performBlock() {
                do
                {
                    try context.save()
                    print("Dis Save Context after PAIRING")
                    
//                    do
//                    {
//                        try self.deleteMessagesWithoutElement()
//                        completion?()
//                    }
//                    catch let messagesCleanUpError
//                    {
//                        print(" Did not delete messages without target element:")
//                        print(messagesCleanUpError)
//                         completion?()
//                    }
                }
                catch{
                    print("Dis NOT Save Context after PAIRING")
                    completion?()
                }
            }
        }
        else
        {
            print("Dis NOT Save Context after PAIRING - No Changes")
            completion?()
//            do
//            {
//                try self.deleteMessagesWithoutElement()
//            }
//            catch let deletingError
//            {
//                print(" Did not delete messages without target element:")
//                print(deletingError)
//            }
        }
        
        
    }
    
    
    
    func deleteMessagesWithoutElement() throws
    {
        let context = self.privateContext
        var thrownError:ErrorType?
        
        let fetchDeleteRequest = NSFetchRequest(entityName: "DBMessageChat")
        fetchDeleteRequest.predicate = NSPredicate(format: "targetElement = nil")
        fetchDeleteRequest.propertiesToFetch = ["elementId"]
        
        //first check , if we have to perform any delete action at all
        var errorCount:NSError?
        let messagesToDeleteCount = context.countForFetchRequest(fetchDeleteRequest, error: &errorCount)
        
        guard messagesToDeleteCount > 0 else
        {
            return
        }
        
        context.performBlockAndWait { () -> Void in
            guard let storeCoordinator = context.persistentStoreCoordinator else
            {
                thrownError = OrigamiError.UnknownError
                return
            }
        
            if #available(iOS 9.0, *)
            {
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchDeleteRequest)
                batchDeleteRequest.affectedStores = storeCoordinator.persistentStores
                do
                {
                    let result = try context.executeRequest(batchDeleteRequest)
                    
                    print(" -> Batch Delete Request deleted messages with result: \(result)")
                    do
                    {
                        try context.save()
                        print(" -> Batch Delete Request DID SAVE context after batch delete messages iOS 9.")
                    }
                    catch let saveContextError
                    {
                        thrownError = saveContextError
                    }
                }
                catch let batchDeleteError
                {
                    thrownError = batchDeleteError
                }
            }
            else
            {
                // Fallback on earlier versions
                do
                {
                    if let foundMessagesWothoutTargetElement = try context.executeFetchRequest(fetchDeleteRequest) as? [DBMessageChat]
                    {
                        for aMessage in foundMessagesWothoutTargetElement
                        {
                            context.deleteObject(aMessage)
                        }
                    }
                    do
                    {
                        try context.save()
                    }
                    catch let saveContextPreIos9Error
                    {
                        thrownError = saveContextPreIos9Error
                    }
                    
                }
                catch let fetchError
                {
                    thrownError = fetchError
                }
            }
        }
        
        if let errorHappened = thrownError
        {
            throw errorHappened
        }
        
        print("Successfully deleted messages without target element")
    }
    
    func readChatMessageById(messageId:Int) -> DBMessageChat?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBMessageChat")
        let predicate = NSPredicate(format: "messageId = \(messageId)")
        fetchRequest.predicate = predicate
        let context = self.privateContext
        var toReturnMessage:DBMessageChat?
        
        context.performBlockAndWait() {
            do{
                if let messagesResult = try context.executeFetchRequest(fetchRequest) as? [DBMessageChat]
                {
                    if messagesResult.count == 1
                    {
                        toReturnMessage = messagesResult.last
                    }
                    else if messagesResult.count > 1
                    {
                        //assert(false, "readChatMessageById  ERROR  -> Found duplicate messages in Local Database...")
                        var messagesToClear = messagesResult
                        
                        toReturnMessage = messagesToClear.removeLast()
                        
                        for aMessage in messagesToClear
                        {
                            context.deleteObject(aMessage)
                        }
                        
                        do
                        {
                            try context.save()
                        }
                        catch let saveError
                        {
                            print("did not save context after deleting duplicate message entries:")
                            print(saveError)
                        }
                    }
                }
               
            }
            catch let error {
                print("Could not fetch messages:")
                print(error)
            }
        }//end of performBlockAndWait
        
        return toReturnMessage
        
    }
    
    func readLastMessagesForHomeDashboard(completion:( ([DBMessageChat]?, error:NSError?) -> ())? )
    {
//        do
//        {
//            try self.deleteMessagesWithoutElement()
//        }
//        catch let deletionError
//        {
//            print(" -> readLastMessagesForHomeDashboard -> did not delete messages without element. Error:")
//            print(deletionError)
//        }
        
        let lastMessagesRequest = NSFetchRequest(entityName: "DBMessageChat")
        let sortById = NSSortDescriptor(key: "messageId", ascending: false)

        lastMessagesRequest.predicate = NSPredicate(format: "targetElement != nil")
        lastMessagesRequest.sortDescriptors = [sortById]
        
        let context = self.privateContext
        context.performBlock { () -> Void in
            do{
                if let messages = try context.executeFetchRequest(lastMessagesRequest) as? [DBMessageChat]
                {
                    if !messages.isEmpty
                    {
                        let sortedMessages = messages.sort({ (message1, message2) -> Bool in
                            return message1.messageId!.integerValue < message2.messageId!.integerValue
                        })
                        
                        
                        if sortedMessages.count < 4
                        {
//                            //debug
//                            for aDBMessage in sortedMessages
//                            {
//                                print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
//                            }
                            completion?(sortedMessages, error:nil)
                        }
                        else
                        {
                            let trimmedMessages = trimArray(sortedMessages, toLastItemsCount: 3)
//                            //debug
//                            for aDBMessage in trimmedMessages
//                            {
//                                print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
//                            }
                            completion?(trimmedMessages, error:nil)
                        }
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
        print(predicate)
        lastMessagesRequest.predicate = predicate
        lastMessagesRequest.sortDescriptors = [sort]
        
        let context = self.privateContext
        
        context.performBlock { () -> Void in
            do{
                if let messages = try context.executeFetchRequest(lastMessagesRequest) as? [DBMessageChat]
                {
                    if !messages.isEmpty
                    {
                      
                        
                        if messages.count > fetchSize
                        {
                            let trimmed = trimArray(messages, toLastItemsCount: fetchSize)
//                            //debug
//                            for aDBMessage in trimmed
//                            {
//                                print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
//                            }
                            completion?(trimmed, error:nil)
                        }
                        else
                        {
//                            //debug
//                            for aDBMessage in messages
//                            {
//                                print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
//                            }
                            completion?(messages, error:nil)
                        }
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
    
    func readChatMessagesForElementById(elementId:Int, fetchSize:Int, lastMessageId:Int = 0, completion:(([DBMessageChat]?, error:NSError?) -> ())?)
    {
        if lastMessageId == 0 //load last messages to show in ChatVC (after "viewDidLoad")
        {
            self.readLastMessagesForElementById(elementId, fetchSize: fetchSize, completion: completion)
        }
        else
        {
            // preform actual work
            let lastMessagesRequest = NSFetchRequest(entityName: "DBMessageChat")
            let sort = NSSortDescriptor(key: "dateCreated", ascending: true)
            let predicate = NSPredicate(format: "elementId = \(elementId) AND messageId < \(lastMessageId)")
            print(predicate)
            lastMessagesRequest.predicate = predicate
            lastMessagesRequest.sortDescriptors = [sort]
            lastMessagesRequest.fetchLimit = fetchSize
            
            let context = self.privateContext
            context.performBlock { () -> Void in
                do{
                    if let messages = try context.executeFetchRequest(lastMessagesRequest) as? [DBMessageChat]
                    {
                        if !messages.isEmpty
                        {
//                            //debug
//                            for aDBMessage in messages
//                            {
//                                print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
//                            }
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
    }
    
    func readNewMsessagesForElementById(elementId:Int, lastMessageId:Int, completion:(([DBMessageChat]?, error:NSError?) -> ())?)
    {
        let lastMessagesRequest = NSFetchRequest(entityName: "DBMessageChat")
        let sort = NSSortDescriptor(key: "dateCreated", ascending: true)
        let predicate = NSPredicate(format: "elementId = \(elementId) AND messageId > \(lastMessageId)")
        print(predicate)
        lastMessagesRequest.predicate = predicate
        lastMessagesRequest.sortDescriptors = [sort]
        let lvContext = self.privateContext
        lvContext.performBlock { () -> Void in
            do{
                if let messages = try lvContext.executeFetchRequest(lastMessagesRequest) as? [DBMessageChat]
                {
                    if !messages.isEmpty
                    {
//                        //debug
//                        for aDBMessage in messages
//                        {
//                            print("returnedMessage: \(aDBMessage.messageId!), date:\(aDBMessage.dateCreated!.timeDateString())")
//                        }
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
    
    
    func getLatestMessageId() -> Int
    {
        let chatMessagesRequest = NSFetchRequest(entityName: "DBMessageChat")
        chatMessagesRequest.fetchLimit = 1
        chatMessagesRequest.propertiesToFetch = ["messageId"]
        
        chatMessagesRequest.sortDescriptors = [NSSortDescriptor(key: "messageId", ascending: false)]
        
        
        var lastMessageId = 0
        let context = self.privateContext
        context.performBlockAndWait { () -> Void in
            do{
                if let results = try context.executeFetchRequest(chatMessagesRequest) as? [DBMessageChat]
                {
                    if !results.isEmpty
                    {
                        let lastMessage = results.first
                        if let messageId = lastMessage?.messageId?.integerValue
                        {
                            lastMessageId = messageId
                        }
                    }
                }
            }
            catch{
                
            }
        }
        
        
        return lastMessageId
    }
    
    func getManagedObjectIDsForMessagesWithoutElement() -> [NSManagedObjectID]?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBMessageChat")
        let predicate = NSPredicate(format: "targetElement = nil")
        fetchRequest.predicate = predicate
        fetchRequest.resultType = .ManagedObjectIDResultType
        let context = self.privateContext
        
        var messagesToReturn:[NSManagedObjectID]?
        context.performBlockAndWait { _ in
            do{
                if let messagesWithoutElement = try context.executeFetchRequest(fetchRequest) as? [NSManagedObjectID]
                {
                    if !messagesWithoutElement.isEmpty
                    {
                        messagesToReturn = messagesWithoutElement
                    }
                }
            }
            catch
            {
                
            }
        }
        
        return messagesToReturn
    }
    
    
    
    func getMessagesIdsForMessagesWithoutElement() -> [NSNumber:[DBMessageChat]]?
    {
        let fetchRequest = NSFetchRequest(entityName: "DBMessageChat")
        let predicate = NSPredicate(format: "targetElement = nil")
        fetchRequest.predicate = predicate
        fetchRequest.propertiesToFetch = ["messageId", "elementId"]
        
        let context = self.privateContext
        
        var messagesToReturn:[NSNumber:[DBMessageChat]]?
        context.performBlockAndWait { _ in
            do{
                if let messagesWithoutElement = try context.executeFetchRequest(fetchRequest) as? [DBMessageChat]
                {
                    if !messagesWithoutElement.isEmpty
                    {
                        //initialize local value to be returned
                        var lvMessagesToReturn = [NSNumber:[DBMessageChat]]()
                        
                        var elementIdNum = NSNumber(integer: 0)
                        
                        for aMessage in messagesWithoutElement
                        {
                            elementIdNum = aMessage.elementId!
                            
                            if let existingMessageIds = lvMessagesToReturn[elementIdNum]
                            {
                                var toReplace = existingMessageIds
                                toReplace.append(aMessage)
                                lvMessagesToReturn[elementIdNum] = toReplace
                            }
                            else
                            {
                                lvMessagesToReturn[elementIdNum] = [aMessage]
                            }
                        }
                        
                        //assign local value to returned value
                        messagesToReturn = lvMessagesToReturn
                    }
                }
            }
            catch
            {
                
            }
        }
        
        return messagesToReturn
    }
    
    func cleanMessagesWithoutElement(completion:(()->())?)
    {
        dispatch_async(getBackgroundQueue_DEFAULT()) {[weak self] in
            if let weakSelf = self
            {
                guard let messagesToBeDeletedIDs = weakSelf.getManagedObjectIDsForMessagesWithoutElement() else
                {
                    completion?()
                    return
                }
                
                let privContext = weakSelf.privateContext
                privContext.performBlockAndWait() { _ in
                    for anObjectId in messagesToBeDeletedIDs
                    {
                        let objectMessage = privContext.objectWithID(anObjectId)
                        privContext.deleteObject(objectMessage)
                    }
                    if privContext.hasChanges
                    {
                        do{
                            try privContext.save()
                        }
                        catch{
                            
                        }
                    }
                }
                
                completion?()
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
        
        localContext.performBlockAndWait { () -> Void in
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
       
        let context = self.privateContext
        
        var previewToReturn:DBAvatarPreview?
        context.performBlockAndWait() {
            
            do{
                if let previews = try context.executeFetchRequest(previewFetchRequest) as? [DBAvatarPreview]
                {
                    if previews.count == 1
                    {
                        previewToReturn = previews.first!
                    }
                    else if previews.count > 1
                    {
                        previewToReturn = previews.last!
                    }
                }
            }
            catch let fetchError
            {
                print("previewAvatar fetch error:")
                print(fetchError)
            }

        }
        
        return previewToReturn
    }
    
    func deleteAvatarPreviewForUserId(userId:Int)
    {
        if let foundUserAvatarPreview = self.findAvatarPreviewForUserId(userId)
        {
            let childContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            childContext.parentContext = self.privateContext
            
            childContext.performBlockAndWait() {
                let lvPreviewForMain = childContext.objectWithID(foundUserAvatarPreview.objectID)
                childContext.deleteObject(lvPreviewForMain)
                
                if childContext.hasChanges
                {
                    do{
                        try childContext.save()
                    }
                    catch let errorSavingContext{
                        print(" DID not save context after avatar preview deleting:\n")
                        print("\(errorSavingContext)")
                    }
                }
            }
        }
        else
        {
            print("DID NOT delete user avatar preview:  Not Found.\n")
        }
       
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
        privateContextLocal.performBlockAndWait { () -> Void in
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
    func findPersonByUserName(userName:String) throws -> DBPerson
    {
        let personFetshRequest = NSFetchRequest(entityName: "DBContact")
        let predicate = NSPredicate(format: "userName like %@", userName)
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
                                throw OrigamiError.NotFoundError(message: "Person with userName \" userName \" was not found.")
                            }
                            else if currentUsers.count > 1
                            {
                                //TODO: delete all users except currently logged in
                                let toReturn =  currentUsers.first!
                                var toDelete = currentUsers
                                
                                toDelete.removeAtIndex(0)
                                
                                let context = self.privateContext
                                
                                context.performBlock(){_ in
                                    for aDBuser in toDelete
                                    {
                                        context.deleteObject(aDBuser)
                                    }
                                }
                                
                                return toReturn
                            }
                        }
                    }
                    catch let errorUser
                    {
                        print("-> ERROR while querying a person:")
                        print(errorUser)
                        throw errorUser
                    }
                }
            }
            print("...some weird stuff happens...")
            throw OrigamiError.NotFoundError(message: "User was not found: Could not execute fetch request.")
        }
        catch let errorContact
        {
            print("-> ERROR while querying a person:")
            print(errorContact)
            throw errorContact
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
//            completion?(false, error:NSError(domain: "com.Origami.EmptyValue.Error", code: -3030, userInfo: [NSLocalizedDescriptionKey:"Tried to insert empty contacts to local database."]))
            self.deleteAllContacts()
            completion?(true, error: nil)
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
        
        let context = self.privateContext
        if self.privateContext.hasChanges
        {
            context.performBlock({ () -> Void in
                do
                {
                    try context.save()
                    print(" Did save context after SavingContacts...")
                    completion?(true, error: nil)
                }
                catch let contextSaveError as NSError
                {
                    print(" --- !!!!  Did NOT context after SavingContacts : ")
                    print(contextSaveError)
                    completion?(false, error: contextSaveError)
                }
            })
           
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
    
    func readContactByManagedObjectID(managedId:NSManagedObjectID, completion:((DBContact?, error:NSError?) -> ())?)
    {
        if #available(iOS 8.3, *)
        {
            self.privateContext.refreshAllObjects()
        }
        else {
            // Fallback on earlier versions
        }
        
        let localContext = self.privateContext
        localContext.performBlock() { _ in
            if let foundContact = localContext.objectWithID(managedId) as? DBContact
            {
                completion?(foundContact, error:nil)
            }
            else
            {
                completion?(nil, error:nil)
            }
        }
    }
    
    /**
     if contacts array is empty, completion block will contain *nil*
     */
    func readAllMyContacts(completion:([DBContact]? -> ())?)
    {
        let contactsRequest = NSFetchRequest(entityName: "DBContact")
        let sortDescriptor = NSSortDescriptor(key: "lastName", ascending: true)
        contactsRequest.sortDescriptors = [sortDescriptor]
        
        let context = self.privateContext
        
        context.performBlock { () -> Void in
            do
            {
                if let contacts = try context.executeFetchRequest(contactsRequest) as? [DBContact]
                {
                    if !contacts.isEmpty
                    {
                        completion?(contacts)
                    }
                    else
                    {
                        completion?(nil)
                    }
                }
            }
            catch
            {
                completion?(nil)
            }
        }
    }
    
    func readAllContactIDs() -> Set<Int>
    {
        let contactsRequest = NSFetchRequest(entityName: "DBContact")
        let context = self.privateContext
        
        var setToReturn = Set<Int>()
        
        context.performBlockAndWait() {
            do{
                if let contacts = try context.executeFetchRequest(contactsRequest) as? [DBContact]
                {
                    for aContact in contacts
                    {
                        if let contactId = aContact.contactId?.integerValue
                        {
                            setToReturn.insert(contactId)
                        }
                    }
                }
            }
            catch{
                
            }
        }
        
        return setToReturn
        
    }
    
    /**
     
    */
    func deleContactById(contactId:Int, saveImmediately:Bool = false, completion:((Bool, error:NSError?)->())?)
    {
        if let existingContact = self.findPersonById(contactId).db
        {
            let context = self.privateContext
            context.performBlock({ () -> Void in
                
                context.deleteObject(existingContact)
                if saveImmediately
                {
                    if context.hasChanges
                    {
                        do
                        {
                            try context.save()
                            print("-> Deleted Contact From Private Context")
                            completion?(true, error:nil)
                        }
                        catch let error as NSError
                        {
                            print("failed to delete contact from private context:")
                            print(error)
                            completion?(true, error:error)
                        }
                    }
                }
            })
        }
    }
    
    func deleContactById(contactId:Int, saveImmediately:Bool = false)
    {
        if let existingContact = self.findPersonById(contactId).db
        {
            let context = self.privateContext
            context.performBlockAndWait(){ () -> Void in
                
                context.deleteObject(existingContact)
                if saveImmediately
                {
                    if context.hasChanges
                    {
                        do
                        {
                            try context.save()
                            print("-> Deleted Contact From Private Context")
                        }
                        catch let error as NSError
                        {
                            print("failed to delete contact from private context:")
                            print(error)
                        }
                    }
                }
            }
        }
    }
    
    /** 
    Saves private context after deleting
    */
    func deleteAllContacts()
    {
        let allElementsRequest = NSFetchRequest(entityName: "DBContact")
        allElementsRequest.includesPropertyValues = false
        
        let lvContext = self.privateContext
        
        if #available (iOS 9.0, *)
        {
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: allElementsRequest)
            do
            {
                if let result = try self.persistentStoreCoordinator.executeRequest(deleteRequest, withContext: lvContext) as? [DBContact]
                {
                    print("will delete contacts: \(result)")
                }
            }
            catch
            {
                
            }
        }
        else //pre iOS 9
        {
            
            lvContext.performBlockAndWait() { () -> Void in
                do
                {
                    if let allContacts = try lvContext.executeFetchRequest(allElementsRequest) as? [DBContact]
                    {
                        for aContact in allContacts
                        {
                            lvContext.deleteObject(aContact)
                        }
                    }
                }
                catch
                {
                    
                }
                
            }
        }
        
        if lvContext.hasChanges
        {
            do
            {
                try lvContext.save()
                print("Deleted all Contacts from local Database...")
            }
            catch
            {
                
            }
        }
    }
    
    //MARK: - Attaches
    func readAttachesForElementById(elementId:Int) throws -> [DBAttach]
    {
        if elementId < 1
        {
            let error = OrigamiError.PreconditionFailure(message: "Wrong element id parameter.")
            throw error
        }
        
        guard let lvElement = self.readElementById(elementId) else
        {
            throw OrigamiError.NotFoundError(message: "Element Not Found By Id: \(elementId).")
        }
        
        guard let lvAttaches = lvElement.attaches as? Set<DBAttach> where lvAttaches.count > 0 else
        {
            throw OrigamiError.NotFoundError(message: "Element has no Attaches.")
        }
        
        let attachesSorted = lvAttaches.sort( < )
        
        return attachesSorted
    }
    
    func readAttachById(attachId:Int) throws -> DBAttach
    {
        if attachId < 1
        {
            let error = OrigamiError.PreconditionFailure(message: "Wrong attach id parameter.")
            throw error
        }
        
        let attachFetchRequest = NSFetchRequest(entityName: "DBAttach")
        attachFetchRequest.predicate = NSPredicate(format: "attachId = \(attachId)")
        let context = self.privateContext
        
        var errorToThrow:ErrorType?
        var attachToReturn:DBAttach?
        
        context.performBlockAndWait { _ in
            do
            {
                if let foundAttaches = try context.executeFetchRequest(attachFetchRequest) as? [DBAttach]
                {
                    let count = foundAttaches.count
                    
                    if count == 1
                    {
                        attachToReturn = foundAttaches.first!
                    }
                    else if count < 1
                    {
                        errorToThrow = OrigamiError.NotFoundError(message: "Attach was not found by id: \(attachId)")
                    }
                    else if count > 1
                    {
                        print(" -> context  is cleating repeating attaches for requested attach id: \(attachId)  ....")
                        var manyAttaches = foundAttaches
                        var attachesToErase = [DBAttach]()
                        repeat{
                            let attachToRemove = manyAttaches.removeLast()
                            attachesToErase.append(attachToRemove)
                        } while manyAttaches.count > 1
                        
                        for anAttach in attachesToErase
                        {
                            context.deleteObject(anAttach)
                        }
                        
                        print("deleted \(attachesToErase.count) repeating attaches....")
                        
                    }
                }
            }
            catch let error
            {
                errorToThrow = error
            }
        }
        
        if let error = errorToThrow
        {
            throw error
        }
        
        if let attach = attachToReturn
        {
            return attach
        }
        else
        {
            let notFoundError = OrigamiError.NotFoundError(message: "Attach was not found by id: \(attachId)")
            throw notFoundError
        }
    }
    /**
     - Parameter shouldSaveContext: default value is *false*
     - Note: consider saving managed object context at some point if passing false to *shouldSaveContext* or ommitting this parameter
     - Returns: newly created DBAttach entity
     */
    func saveAttachToLocalDatabase(attach:AttachFile, shouldSaveContext:Bool = false) throws -> DBAttach
    {
        
        var noAttachError:ErrorType?
        do
        {
            let existing = try self.readAttachById(attach.attachID)
            
            existing.fillInfoFromInMemoryAttach(attach)
        }
        catch let error
        {
            noAttachError = error
        }
        
        guard let _ = noAttachError else
        {
            let existingAttachError = OrigamiError.PreconditionFailure(message: "target DBAttach already exists in local database")
            throw existingAttachError
        }
        
        guard let newAttach = NSEntityDescription.insertNewObjectForEntityForName("DBAttach", inManagedObjectContext: self.privateContext) as? DBAttach else
        {
            let insertError = OrigamiError.UnknownError
            throw insertError
        }
        
        //perform actual data saving work
        newAttach.fillInfoFromInMemoryAttach(attach)
        
        do
        {
            let previewImageData = try DataSource.sharedInstance.getAttachPreviewForFileNamed(newAttach.fileName!)
            if let  newImagePreview = NSEntityDescription.insertNewObjectForEntityForName("DBAttachImagePreview", inManagedObjectContext: self.privateContext) as? DBAttachImagePreview
            {
                newImagePreview.imagePreviewData = previewImageData
                newImagePreview.attachId = newAttach.attachId
                newAttach.preview = newImagePreview
            }
        }
        catch let previewImageError
        {
            print(" saveAttachToLocalDatabase -> Could not get attachPreviewImageData:")
            print(previewImageError)
        }
        
        
        //save context immediately if needed
        if shouldSaveContext && self.privateContext.hasChanges
        {
            var savingError:ErrorType?
            let context = self.privateContext
            
            //switch to context`s own queue
            context.performBlockAndWait { _ in
                
                do{
                    try context.save()
                }
                catch let lvSavingError
                {
                    savingError = lvSavingError
                }
            }
            
            //proceed in current queue after context did finish executing "save" operation
            if let error = savingError
            {
                throw error
            }
            
            return newAttach
        }
        
        //debug
        if !self.privateContext.hasChanges
        {
            print( "WARNING! -> Managed Object Context has no changes after inserting new attach file info.")
        }
        
        return newAttach
    }
    
    
    
    func saveImagePreview(imageData:NSData, forAttachById attachId:Int) throws
    {
        do
        {
            let foundAttach = try self.readAttachById(attachId)
        
            do
            {
                try self.savePreview(imageData, forAttach: foundAttach)
            }
            catch let savingError
            {
                throw savingError
            }
        
        }
        catch let findingError
        {
            throw findingError
        }
    }
    
    
    /**
     - Note: if calling this method in a loop or recursively, don`t forget to call *savePrivateContext* method at any point after loop finishes
      - pass *true* to `shouldSaveContext` if you want contaxt to save after single insertion of image preview

     - Parameter shouldSaveContext: default value is *`false`*
     - Parameter dbAttach: DBAttach instance to assign attach for
     - Parameter imageData: NSData object, containing image preview bytes
     - Throws: if could not save context after insertion, or if new DBAttachImagePreview entity could not be created
     */
    func savePreview(imageData:NSData, forAttach dbAttach:DBAttach, shouldSaveContext:Bool = false) throws
    {
        guard let newPreview = NSEntityDescription.insertNewObjectForEntityForName("DBAttachImagePreview", inManagedObjectContext: self.privateContext) as? DBAttachImagePreview else
        {
            let insertionError = OrigamiError.PreconditionFailure(message: "Could not insert new \"ImagePreview\" entity to context.")
            throw insertionError
        }
        
        newPreview.attachId = dbAttach.attachId
        newPreview.imagePreviewData = imageData
        dbAttach.preview = newPreview
        
        if shouldSaveContext && self.privateContext.hasChanges
        {
            let context = self.privateContext
            var saveError:ErrorType?
            
            context.performBlockAndWait()
                {
                do{
                    try context.save()
                }
                catch let lvSaveError
                {
                    saveError = lvSaveError
                }
            }
           
            if let error = saveError
            {
                throw error
            }
        }
    }
    
    /**
     Tries to find target element and assign given attaches to it
     
     - Parameter shouldSaveContext: *false* by default
     - if passed *true*, managed object context will try to save immediately
     - Note: Consider saving managed object context after pairing element and attaches
     - Throws: 
        - *NotFoundError* with message containing element ID  if target attach was not found
        - *UnknownError* if found element attaches could not be converted to Set< DBAttach >
        - if tried to save managed object context and failed
     - Returns: number of newly added attaches
     */
    func addAttaches(attaches:[DBAttach], toElementById elementId:Int, shouldSaveContext:Bool = false) throws -> Int
    {
        guard let foundElement = self.readElementById(elementId) else
        {
            let notFound = OrigamiError.NotFoundError(message: "Not Found Element by Id: \(elementId)")
            throw notFound
        }
        
        //convert to Swift Set
        guard let currentAttaches = foundElement.attaches as? Set<DBAttach> else
        {
            throw OrigamiError.UnknownError
        }
        let currentAttachesCount = currentAttaches.count
        //perform adding new attaches
        let newAttaches = currentAttaches.union(Set(attaches))
        
        //convert back to NSSet
        let nsSetAttaches = newAttaches as NSSet

        //finaly update found element`s attaches
        foundElement.attaches = nsSetAttaches
        let newAttachesCount = newAttaches.count
        
        if shouldSaveContext && self.privateContext.hasChanges
        {
            var savingError:ErrorType?
            let context = self.privateContext
            context.performBlockAndWait() { _ in
                do
                {
                    try context.save()
                }
                catch let error
                {
                    savingError = error
                }
            }
            
            if let error = savingError
            {
                throw error
            }
        }
        
        //debug
        if !self.privateContext.hasChanges
        {
            print(" WARNING! Managed Object Context has no changes after assigning new attaches to element.")
        }
        
        let attachesAddedCount = newAttachesCount - currentAttachesCount
        
        return attachesAddedCount
    }
    
    func deleteAttach(attach:DBAttach, shouldSave:Bool = false) throws
    {
        let context = self.privateContext
        var deletingError:ErrorType?
        context.performBlockAndWait { () -> Void in
            
            let attachId = attach.objectID
            let object = context.objectWithID(attachId)
            context.deleteObject(object)
           
            if shouldSave
            {
                if context.hasChanges
                {
                    do
                    {
                        try context.save()
                    }
                    catch let savingError
                    {
                        deletingError = savingError
                    }
                }
                else
                {
                    let unknownError = OrigamiError.UnknownError
                    deletingError = unknownError
                }
            }
        }
        
        if let error = deletingError
        {
            throw error
        }
    }
    
    func deleteAttachById(attachId:Int) throws
    {
        do
        {
            var saveError:ErrorType?
            let foundAttach = try self.readAttachById(attachId)
            let context = self.privateContext
            context.performBlockAndWait({ () -> Void in
                context.deleteObject(foundAttach)
                do{
                    try context.save()
                }
                catch let blockSaveError
                {
                    saveError = blockSaveError
                }
            })
            
            if let errorToThrow = saveError
            {
                throw errorToThrow
            }
        }
        catch let error
        {
            throw error
        }
    }
    
    
    /**
     - Returns: Non empty array of attachIDs
     */
    func allAttachesIDsForElementById(elementId:Int) throws -> Set<Int>
    {
        guard let foundElement = self.readElementById(elementId) else
        {
            throw OrigamiError.NotFoundError(message: "Element Not Found By Id: \(elementId).")
        }
        
        guard let attachesSet = foundElement.attaches as? Set<DBAttach> where attachesSet.count > 0 else
        {
            throw OrigamiError.NotFoundError(message: "No Attaches Found for Element by Id: \(elementId).")
        }
        
        var intsSet = Set<Int>()
        
        for anAttach in attachesSet
        {
            if let intId = anAttach.attachId?.integerValue
            {
                intsSet.insert(intId)
            }
        }
        
        guard !intsSet.isEmpty else
        {
            throw OrigamiError.NotFoundError(message: "No attachIds found.")
        }
        return intsSet
    }
    
    func deleteAllAttachesForElementById(elementId:Int) throws
    {
        guard let foundElement = self.readElementById(elementId) else
        {
            throw OrigamiError.NotFoundError(message: "Element Not Found By Id: \(elementId).")
        }
        
        guard let attachesSet = foundElement.attaches as? Set<DBAttach> where attachesSet.count > 0 else
        {
            throw OrigamiError.NotFoundError(message: "No Attaches Found for Element by Id: \(elementId).")
        }
        
        let context = self.privateContext
        
        var anyError:ErrorType?
        
        context.performBlockAndWait { () -> Void in
            for anAttach in attachesSet
            {
                context.deleteObject(anAttach)
            }
            
            do
            {
                try context.save()
            }
            catch let saveError
            {
                anyError = saveError
            }
        }
        
        if let error = anyError
        {
            throw error
        }
    }
}
