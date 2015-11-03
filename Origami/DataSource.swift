//
//  DataSource.swift
//  Origami
//
//  Created by CloudCraft on 02.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit
import ImageIO

typealias successErrorClosure = (success:Bool, error:NSError?) -> ()

@objc class DataSource: NSObject
{
    typealias voidClosure = () -> ()
    
    typealias messagesArrayClosure = ([Message]?) -> ()
    typealias elementsArrayClosure = ([Element]?) -> ()
    typealias contactsArrayClosure = ([Contact]?) -> ()
    typealias attachesArrayClosure = ([AttachFile]?) -> ()
    typealias userClosure = (User?) -> ()
    typealias errorClosure = (NSError?) -> ()

    enum ResponseType:Int
    {
        case Added = 1
        case Replaced = 2
        case Denied = 3
    }
        
    //singletone
    static let sharedInstance = DataSource()
    
    // properties
    lazy var messagesObservers = [NSNumber:MessageObserver]()
    
    var user:User?
    
    private var messages =  [NSNumber:[Message]] () // {elementId: [Messages]}
    
    private lazy var contacts = [Contact]()
    
//    private lazy var elements = [Element]()
    
    var languages = [Language]()
    var countries = [Country]()
   
    lazy var operationQueue = NSOperationQueue()
    
    private lazy var pBgOperationQueue = NSOperationQueue()
    private var avatarOperationQueue:NSOperationQueue {
        pBgOperationQueue.maxConcurrentOperationCount = 3
        return pBgOperationQueue
    }
    //private lazy var dataCache:NSCache = NSCache()
    var pendingAttachFileDataDownloads = [Int:NSURLSessionDataTask]()
    var pendingUserAvatarsDownolads = [String:Int]()
    lazy var userAvatarsHolder = [Int:UIImage]()
    lazy var participantIDsForElement = [Int:Set<Int>]()
    
    private let serverRequester = ServerRequester()
 
    var shouldReloadAfterElementChanged = false
    var isRemovingObsoleteMessages = false
    var shouldLoadAllMessages = true
    
    var dashBoardInfo:(signals:[DBElement]?, favourites:[DBElement]?, other:[DBElement]?)?
    
    var localDatadaseHandler: LocalDatabaseHandler?
    func createLocalDatabaseHandler(completion:((dbInitialization:Bool)->())?)
    {
        if let model = LocalDatabaseHandler.getManagedObjectModel()
        {
            do{
                if let storeCoordinator = try LocalDatabaseHandler.getPersistentStoreCoordinatorForModel(model)
                {
                    DataSource.sharedInstance.localDatadaseHandler = LocalDatabaseHandler(storeCoordinator: storeCoordinator, completion: { (success) -> () in
                        if success == false
                        {
                            DataSource.sharedInstance.localDatadaseHandler = nil
                        }
                        completion?(dbInitialization:success)
                    })
                }
            }
            catch{
                completion?(dbInitialization: false)
            }
        }
    }
    var messagesLoader:MessagesLoader?
    var dataRefresher:DataRefresher?
    
    var loadingAllElementsInProgress = false
    
  
    //private stuff
    private func getMessagesObserverForElementId(elementId:NSNumber) -> MessageObserver?
    {
        if let existingObserver = DataSource.sharedInstance.messagesObservers[elementId]
        {
            return existingObserver
        }
        return nil
    }
   
    func removeAllObserversForNewMessages()
    {
        if !DataSource.sharedInstance.messagesObservers.isEmpty // self.messageObservers.count > 0
        {
            DataSource.sharedInstance.messagesObservers.removeAll(keepCapacity: false)
        }
    }
    
    // functions
    func performLogout(completion:voidClosure?) //optional closure as parameter (completion block in objective-c)
    {
        let bgQueue:dispatch_queue_t = dispatch_queue_create("logout.queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue, { _ in
            DataSource.sharedInstance.localDatadaseHandler?.deleteAllElements()
            DataSource.sharedInstance.localDatadaseHandler?.deleteAllChatMessages()
            DataSource.sharedInstance.localDatadaseHandler?.deleteAllContacts()
            DataSource.sharedInstance.user = nil
            //DataSource.sharedInstance.cleanDataCache()
            DataSource.sharedInstance.contacts.removeAll(keepCapacity: false)
            //DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
            DataSource.sharedInstance.userAvatarsHolder.removeAll()
            //print("AvatarsHolder Before cleaning: \(DataSource.sharedInstance.avatarsHolder.count)")
            //DataSource.sharedInstance.avatarsHolder.removeAll(keepCapacity: false)
            //print("AvatarsHolder After cleaning: \(DataSource.sharedInstance.avatarsHolder.count)")
            //DataSource.sharedInstance.stopRefreshingNewMessages()
            
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
            dispatch_after(timeout, getBackgroundQueue_DEFAULT(), { () -> Void in
                DataSource.sharedInstance.messagesLoader?.stopRefreshingLastMessages()
                print("stopRefreshingLastMessages")
                //sleep(2)
                
                //DataSource.sharedInstance.messagesLoader?.cancelDispatchSource()
                //print("cancelDispatchSource")
                //sleep(2)
                
                DataSource.sharedInstance.messagesLoader = nil
                print("messagesLoader = nil")
            })
            
            
            DataSource.sharedInstance.removeAllObserversForNewMessages()
         
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey(passwordKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            if  completion != nil
            {
                //return into main queue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion?()
                })
            }
        })
    }
    
    //MARK: - User
    func tryToGetUser(completion:(user:User?, error:NSError?)->())
    {
        if DataSource.sharedInstance.user != nil
        {
            completion(user: DataSource.sharedInstance.user, error: nil)
            return
        }
        
        //try to perform auto login
        
        guard let userName = NSUserDefaults.standardUserDefaults().objectForKey(loginNameKey) as? String, let password = NSUserDefaults.standardUserDefaults().objectForKey(passwordKey) as? String else
        {
            completion(user: nil, error: NSError(domain: "com.Origami.NoUserDataError.", code: -1, userInfo: [NSLocalizedDescriptionKey:"No user password or email found"]))
            return
        }
        
        DataSource.sharedInstance.serverRequester.loginWith(userName, password: password, completion: { (userResult, loginError) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let lvUser = userResult as? User
                {
                    DataSource.sharedInstance.user = lvUser
                    completion(user: DataSource.sharedInstance.user, error: nil)
                }
                else
                {
                    completion(user: nil, error: loginError)
                }
            })
        })
    }
    
    func editUserInfo(completion: ((success:Bool, error: NSError?)->())?)
    {
        if let currentUser = DataSource.sharedInstance.user
        {
            let bgQueue = dispatch_queue_create("Origami.UserEdit.Queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue, { () -> Void in
                DataSource.sharedInstance.serverRequester.editUser(currentUser, completion: { (success, error) -> () in
                    completion?(success:success, error: error)
                })
            })
            
        }
    }
    
    
    //MARK: - Message
    //MARK: -
    //MARK: Messages ServerRequests
    func loadAllMessagesFromServer()
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        DataSource.sharedInstance.serverRequester.loadAllMessages {
            (resultArray, serverError) -> () in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                if let messagesTuple = resultArray
                {
                    DataSource.sharedInstance.localDatadaseHandler?.saveChatMessagesToLocalDataBase(messagesTuple.chat, completion: { (saved, error) -> () in
                        NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoadingMessages, object: DataSource.sharedInstance)
                    })
                }
                else
                {
                    NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoadingMessages, object: DataSource.sharedInstance)
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
        }
    }
    
    func loadLastMessages(completion:successErrorClosure?)
    {
        DataSource.sharedInstance.serverRequester.loadNewMessages { (messages, error) -> () in
            if let anError = error
            {
                if let completionBlock = completion
                {
                    completionBlock(success: false, error: anError)
                }
                return
            }
                
            guard let returnedStruct = messages else
            {  //if no new messages
                completion?(success: true, error: nil)
                return
            }
            
            DataSource.sharedInstance.handleRecievedMessagesTuple(returnedStruct, completion: { () -> () in
                if let completionBlock = completion
                {
                    completionBlock(success: true, error: nil)
                }
            })
        }
    }
    
    func syncLastMessages(lastMessageId:Int = 0, completion:((Bool, error:NSError?)->())?)
    {
        DataSource.sharedInstance.serverRequester.loadNewMessagesWithLastMessageID(lastMessageId) { (messagesTuple, error) -> () in
            if let anError = error{
                completion?(false, error: anError)
                return
            }
            guard let unHandledTupleHolderStruct = messagesTuple else
            {
                // no new last messages recieved
                completion?(true, error:nil)
                return
            }
            
            DataSource.sharedInstance.handleRecievedMessagesTuple(unHandledTupleHolderStruct, completion: { () -> () in
                completion?(true, error:nil)
            })
        }
    }
    
    private func handleRecievedMessagesTuple(messagesTupleHolder: TypeAliasMessagesTuple, completion:(()->())?)
    {
        var lvMessagesHolder = [NSNumber:[Message]]()
        for lvMessage in messagesTupleHolder.messagesTuple.chat
        {
            if lvMessagesHolder[lvMessage.elementId!] != nil
            {
                lvMessagesHolder[lvMessage.elementId!]?.append(lvMessage)
            }
            else
            {
                lvMessagesHolder[lvMessage.elementId!] = [lvMessage]
            }
        }
        
        if !lvMessagesHolder.isEmpty
        {
            var messagesForFoundElements = [Message]()
            var messagesForNotFoundElements = [Message]()
            for (keyElementId, messages) in lvMessagesHolder
            {
                if let _ = DataSource.sharedInstance.localDatadaseHandler?.readElementById(keyElementId.integerValue)
                {
                    //print("Saving Messages \(messages.count) for element: \(keyElementId)")
                    messagesForFoundElements += messages
                }
                else
                {
                    //print("Saving messages with currently missing element : \(keyElementId)")
                    messagesForNotFoundElements += messages
                }
              
            }
            
            DataSource.sharedInstance.localDatadaseHandler?.saveChatMessagesToLocalDataBase(messagesForFoundElements, completion: { (saved, error) -> () in
                if let messageSaveError = error
                {
                    print("Message Save Error: \n \(messageSaveError)")
                }
                
                DataSource.sharedInstance.localDatadaseHandler?.saveChatMessagesToLocalDataBase(messagesForNotFoundElements, completion: { (saved, error) -> () in
                    if let messageSaveError = error
                    {
                        print("Message Save Error: \n \(messageSaveError)")
                    }
                    
                    DataSource.sharedInstance.localDatadaseHandler?.performMessagesAndElementsPairing(){ _ in
                        print("\n -> DataSource did finish PAIRING messages and elemnts..")
                        if let observerHomeVC = DataSource.sharedInstance.getMessagesObserverForElementId(All_New_Messages_Observation_ElementId)
                        {
                            observerHomeVC.newMessagesWereAdded()
                        }
                    }
                    
                })
            })
        }
        
        let serviceMessages = messagesTupleHolder.messagesTuple.service
        if !serviceMessages.isEmpty
        {
            let serviceHandler = ServiceMessagesHandler()
            serviceHandler.startProcessingServiceMessages(serviceMessages)
        }

        completion?()
    }
    
    func sendNewMessage(message:Message, completion:errorClosure?)
    {
        //can be not main queue
        guard let messageElementId = message.elementId , text = message.textBody else {
            
            completion?(NSError(domain: "com.Origami.InvalidParameterError", code: -1022, userInfo: [NSLocalizedDescriptionKey:"No element id from passing message or empty message body."]))
            return
        }
        
        let messageToInsert = message
        DataSource.sharedInstance.serverRequester.sendMessage(text, toElement: messageElementId) { (result, error) -> () in
            
            //main queue
            if error != nil
            {
                completion?(error)
            }
            else
            {
                if let responseInfo = result as? [String:Int], messageId = responseInfo["SendElementMessageResult"]
                {
                    messageToInsert.dateCreated = NSDate()
                    messageToInsert.messageId = messageId
                }
                
                DataSource.sharedInstance.localDatadaseHandler?.saveChatMessagesToLocalDataBase([messageToInsert], completion: { (saved, error) -> () in
                    if let saveError = error
                    {
                        completion?(saveError)
                        DataSource.sharedInstance.localDatadaseHandler?.performMessagesAndElementsPairing(nil)
                        
                        return
                    }
//                    if saved
//                    {
//                        print("DataSource did save new Message to local database")
//                        
//                    }
                    DataSource.sharedInstance.localDatadaseHandler?.performMessagesAndElementsPairing(nil)
                    completion?(nil)
                })
            }
        }
    }
    
    
    func startRefreshingNewMessages()
    {
        DataSource.sharedInstance.stopRefreshingNewMessages()
        if let loader = DataSource.sharedInstance.messagesLoader
        {
            loader.startRefreshingLastMessages()
        }
    }
    
    func stopRefreshingNewMessages()
    {
        DataSource.sharedInstance.messagesLoader?.stopRefreshingLastMessages()
    }
    //MARK: Messages Local Stuff
    
    func isMessagesEmpty() -> Bool{
        return DataSource.sharedInstance.messages.isEmpty
    }
    
    func addMessages(messageObjects:[Message], forElementId elementId:NSNumber, completion:voidClosure?)
    {
        let messagesToAdd = ObjectsConverter.sortMessagesByMessageId(messageObjects)
        // add to our array container
        if let existingMessages = DataSource.sharedInstance.messages[elementId]
        {
            var mutableExisting = existingMessages
            mutableExisting += messagesToAdd
            //replace existing messages with new array
            DataSource.sharedInstance.messages[elementId] = mutableExisting
        }
        else
        {
            DataSource.sharedInstance.messages[elementId] = messagesToAdd
        }
        
        // also check if there are any observers waiting for new messages
        if let observer =  getMessagesObserverForElementId(elementId)
        {
            observer.newMessagesAdded(messagesToAdd)
        }
        
        //return from function
        if let completionBlock = completion
        {
            completionBlock()
        }
    }
    
    func getAllMessagesForElementId(elementId:NSNumber) -> [Message]?
    {
        if let messagesExist = messages[elementId]
        {
            return messagesExist
        }
        return nil
    }
    
    func getMessagesQuantyty(quantity:Int, elementId:Int, lastMessageId:Int?) -> [Message]?
    {
        print(" next queried portion of messages with params: \n quantity: \(quantity)\n elementId: \(elementId)\n lastMessageId: \(lastMessageId)")
        
        let allMessagesForElement = DataSource.sharedInstance.getAllMessagesForElementId(NSNumber(integer: elementId))
            
        if let unFilteredExistingMessagesForElementId = allMessagesForElement
        {
            var messagesToReturn = [Message]()
            var aCount = Int(0)
            if let presentLastMessageId = lastMessageId
            {
                let lastMessageIndex = unFilteredExistingMessagesForElementId.count - 1
                
                for var i = lastMessageIndex; i >= 0; i--
                {
                    
                    let currentMessage = unFilteredExistingMessagesForElementId[i]
                    if currentMessage.messageId >= presentLastMessageId
                    {
                        continue
                    }
                    
                    if aCount < quantity
                    {
                        messagesToReturn.insert(currentMessage, atIndex: 0)
                    }
                    else
                    {
                        break
                    }
                }
            }
            else
            {
                for aMessage in unFilteredExistingMessagesForElementId.reverse()
                {
                    if aCount < quantity
                    {
                        messagesToReturn.insert(aMessage, atIndex: 0)
                        aCount += 1
                    }
                    else
                    {
                        break
                    }
                }
            }
            
            if messagesToReturn.isEmpty
            {
                return nil
            }
            //debug print out filtered last messages
            //print("\n ---Returning message ids for chat: ")
            for aFilteredMessage in messagesToReturn
            {
                print( "-> \(aFilteredMessage.messageId)")
            }
            return messagesToReturn

        }
        else
        {
            return nil
        }
    }

    
//    func getLastMessagesForDashboardCount(messagesQuantity:Int, completion completionClosure:((messages:[Message]?)->())? = nil)
//    {
//        
//        let bgQueue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//        
//        dispatch_async(bgQueue, { () -> Void in
//            if DataSource.sharedInstance.messages.isEmpty
//            {
//                
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        if let completionBlock = completionClosure
//                        {
//                            completionBlock(messages: nil)
//                        }
//                    })
//                return
//            }
//            
//            var allMessagesSet = Set<Message>()
//            for (_,lvMessages) in DataSource.sharedInstance.messages
//            {
//                allMessagesSet.unionInPlace( Set(lvMessages))
//            }
//            var sortedArray = Array(allMessagesSet)
//            
//            ObjectsConverter.sortMessagesByDate(&sortedArray, > )
//            var lastThreeItems = [Message]()
//            var index = 0
//            
//            var elementIDsToDeleteMessageSet = Set<Int>()
//            for aMessage in sortedArray
//            {
//                if lastThreeItems.count > 2
//                {
//                    break
//                }
//                
//                index += 1
//                
//                if let elementIdInt = aMessage.elementId
//                {
//                    if let _ = DataSource.sharedInstance.getElementById(elementIdInt)
//                    {
//                        lastThreeItems.insert(aMessage, atIndex: 0)
//                    }
//                    else
//                    {
//                        elementIDsToDeleteMessageSet.insert(elementIdInt)
//                    }
//                }
//                
//            }
//            
//            if !elementIDsToDeleteMessageSet.isEmpty
//            {
//                print(" \n -> deleting messages for non existing elements...")
//                DataSource.sharedInstance.removeMessagesForDeletedElements(elementIDsToDeleteMessageSet)
//            }
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                if let completionBlock = completionClosure
//                {
//                    
//                    completionBlock(messages: lastThreeItems) //return result
//                }
//            })
//        })
//        
//    }
    
    func addObserverForNewMessagesForElement(newObserver:MessageObserver, elementId:NSNumber) -> ResponseType
    {
        var response:ResponseType
        if let _ = DataSource.sharedInstance.getMessagesObserverForElementId(elementId) // array exists for this element
        {
            // replace with new one and return .Replaced
            response = .Replaced
        }
        else
        {
            // add new one and return .Added
            response = .Added
        }
        
        messagesObservers[elementId] = newObserver
        return response
    }
    
    func removeObserverForNewMessagesForElement(elementId:NSNumber)
    {
        if let _ = DataSource.sharedInstance.messagesObservers[elementId]
        {
            DataSource.sharedInstance.messagesObservers[elementId] = nil
        }
    }
    
    
    
    func removeMessagesForDeletedElements(elementIDs:Set<Int>)
    {
        if DataSource.sharedInstance.isRemovingObsoleteMessages
        {
            return
        }
        
        DataSource.sharedInstance.isRemovingObsoleteMessages = true
        DataSource.sharedInstance.shouldLoadAllMessages = false
        let aLock = NSLock()
        aLock.name = "MessageDeletionLock"
        aLock.lock()
        for anId in elementIDs
        {
            if !DataSource.sharedInstance.messages.isEmpty
            {
                if DataSource.sharedInstance.messages.removeValueForKey(NSNumber(integer:anId)) != nil
                {
                    print(" -> Deleted messages array.")
                }
            }
        }
        aLock.unlock()
        
        DataSource.sharedInstance.isRemovingObsoleteMessages = false
    }
    
    //MARK: - Element
    /**
        submitNewElementToServer completion : Sends POST request to server to create new Element.
    
        - Parameter completion: returnClosure withnewElementId in case of success and error in case of error
    
    */
    func submitNewElementToServer(newElement:Element, completion:((newElementId:Int?, error:NSError?) ->())?)
    {
        DataSource.sharedInstance.serverRequester.submitNewElement(newElement){ (result, error) -> () in
            if let successElement = result as? Element
            {
                let elementId = successElement.elementId
                if elementId <= 0
                {
                    completion?(newElementId: nil, error: NSError(domain: "com.origami.newElementCreationError.", code: -10500, userInfo: [NSLocalizedDescriptionKey:"Wrong New Element Id Recieved"]))
    
                    return
                }
                
                NSOperationQueue().addOperationWithBlock(){_ in
                    DataSource.sharedInstance.localDatadaseHandler?.saveElementsToLocalDatabase([successElement]) { (didSave, error) -> () in
                        if didSave
                        {
                            completion?(newElementId: elementId, error: nil)
                        }
                        else
                        {
                            completion?(newElementId: nil, error: error)
                        }
                    }
                }
            }
            else
            {
                completion?(newElementId: nil, error: error)
            }
        }
    }
    
//    func addNewElements(elements:[Element], completion:voidClosure?)
//    {
//        DataSource.sharedInstance.elements += elements
//        var elementIDs = Set<NSNumber>()
//        for anElement in elements
//        {
//            if let id = anElement.elementId
//            {
//                elementIDs.insert(id)
//            }
//        }
//        
//        NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil, userInfo: ["IDs" : elementIDs])
//        
//        if (completion != nil)
//        {
//            completion!()
//        }
//    }
//    
//    func getElementById(elementId:Int) -> Element?
//    {
//        let foundElements = DataSource.sharedInstance.elements.filter
//        { lvElement -> Bool in
//            if let existId = lvElement.elementId
//            {
//                return existId == elementId
//            }
//            return false
//        }
//        
//        if !foundElements.isEmpty
//        {
//            return foundElements.last
//        }
//        return  nil
//    }
//    
    /**
    returns array of elements, containing at leats one *Element* object
    */
//    func getRootElementTreeForElement(targetRootElementId:Int) -> [Element]?
//    {
//        var root = targetRootElementId
//        guard  root > 0 else{
//            return nil
//        }
//        
//        var elements = [Element]()
//        
//        while root > 0
//        {
//            if let foundRootElement = DataSource.sharedInstance.getElementById(root)
//            {
//                elements.append(foundRootElement)
//                root = foundRootElement.rootElementId
//            }
//            else
//            {
//                break
//            }
//        }
//        
//        if elements.isEmpty
//        {
//            return nil
//        }
//        return elements
//        
//    }
//    
//    func getSubordinateElementsForElement(elementId:Int?, shouldIncludeArchived:Bool) -> [Element]?
//    {
//        guard let lvElementId = elementId else {
//            return nil
//        }
//        
//        var elementsToReturn = [Element]()
//        for lvElement in DataSource.sharedInstance.elements
//        {
//            if lvElement.rootElementId == lvElementId
//            {
//                elementsToReturn.append(lvElement)
//            }
//        }
//        
//        if !elementsToReturn.isEmpty
//        {
//            ObjectsConverter.sortElementsByDate(&elementsToReturn)
//            if !shouldIncludeArchived
//            {
//                let newElements = ObjectsConverter.filterArchiveElements(false, elements: elementsToReturn)
//                return newElements
//            }
//        }
//    
//        return nil
//    }
//    
//    func getSubordinateElementsTreeForElement(targetRootElement:Element) -> [Element]?
//    {
//        //var treeToReturn = [Element]()
//        
//        guard let currentSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(targetRootElement.elementId, shouldIncludeArchived:false) else
//        {
//            return nil
//        }
//        if currentSubordinates.isEmpty
//        {
//            return nil
//        }
//        
//        //let countSubordinates = currentSubordinates.count
//        var subordinatesSet = Set<Element>()
//        
//        for lvElement in currentSubordinates
//        {
//            if let subordinatesFirst =  DataSource.sharedInstance.getSubordinateElementsForElement(lvElement.elementId, shouldIncludeArchived:false)
//            {
//                if !subordinatesFirst.isEmpty
//                {
//                    let subSetFirst = Set(subordinatesFirst)
//                    subordinatesSet.exclusiveOrInPlace(subSetFirst)
//                }
//            }
//        }
//    
//        return Array(subordinatesSet)
//       
//    }
    
//    func getDashboardElements( completion:([Int:[Element]]?)->() )
//    {
//        
//        let dispatchQueue = dispatch_queue_create("elements.sorting", DISPATCH_QUEUE_SERIAL)
//        dispatch_async(dispatchQueue,
//        {
//            if DataSource.sharedInstance.elements.isEmpty
//            {
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    completion(nil)
//                })
//                return
//            }
//            
//            var toReturnDict = [Int:[Element]]()
//            
//            let preFavouriteElements = DataSource.sharedInstance.elements.filter({ (checkedElement) -> Bool in
//                return checkedElement.isFavourite.boolValue
//            })
//            
//            var favouriteElements =  ObjectsConverter.filterArchiveElements(false, elements: preFavouriteElements)
//            
//            if let _ = favouriteElements {
//                ObjectsConverter.sortElementsByDate(&favouriteElements!)
//                toReturnDict[2] = favouriteElements!
//            }
//            else {
//                toReturnDict[2] = [Element]()
//            }
//        
//            // ----
//            var otherElementsSet = Set<Element>()//[Element]()
//            
//            let filteredMainElements = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
//                //let rootId = element.rootElementId
//                return (element.rootElementId == 0)
//                
//            })
//            
//            for lvElement in filteredMainElements
//            {
//                otherElementsSet.insert(lvElement)
//            }
//            
//            let preOtherElementsArray = Array(otherElementsSet)
//            var otherElementsArray = ObjectsConverter.filterArchiveElements(false, elements: preOtherElementsArray)
//            if let _ = otherElementsArray {
//                ObjectsConverter.sortElementsByDate(&otherElementsArray!)
//                toReturnDict[3] = otherElementsArray!
//            }
//            else {
//                toReturnDict[3] = [Element]()
//            }
//            
//            // get all signals
//            let filteredSignals = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
//                
//                let signalValue = element.isSignal.boolValue
//                //let  rootId = element.rootElementId.integerValue
//                
//                return (signalValue )
//            })
//            
//            let signalElementsSet = Set(filteredSignals)
//            let preSignalElementsArray = Array(signalElementsSet)
//            
//            //filter out archiveElements
//            
//            
//            var signalElementsArray = ObjectsConverter.filterArchiveElements(false, elements: preSignalElementsArray)
//            if let _ = signalElementsArray{
//                 ObjectsConverter.sortElementsByDate(&signalElementsArray!)
//                toReturnDict[1] = signalElementsArray!
//            }
//            else{
//                toReturnDict[1] = [Element]()
//            }
//            
//            dispatch_async(dispatch_get_main_queue(),
//            {
//                _ in
//                //let toReturn : [Int:[Element]] = [1:signalElementsArray, 2:favouriteElements, 3:otherElementsArray]
//                completion(toReturnDict)
//            })
//        })
//    }
    
//    func getAllElementsSortedByActivity( completion:((elements:[Element]?) -> ())? )
//    {
//        //NSLog("_________ Started gathering elements for RecentActivityTableVC.....")
//        
//        let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
//        dispatch_async(bgQueue, { () -> Void in
//            
//            var elementsToSort = DataSource.sharedInstance.elements
//            print("-> DataSource->  getAllElementsSortedByActivity. All elements: \(elementsToSort.count)\n")
//            ObjectsConverter.sortElementsByDate(&elementsToSort)
//            
//            print("-> DataSource->  getAllElementsSortedByActivity. All elements Sorted by date: \(elementsToSort.count)\n")
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                completion?(elements: elementsToSort)
//            })
//        })
//    }

    /**
    Starts loading all elements for current user and saves thed to local database with attempt to save managed object context
    - Returns: in completion block 
        - true if context did save normally or if no changes occured, 
        - false if no changes in context, 
        - false and error if something happened
    */
    func loadAllElementsInfo(completion:((success:Bool, failure:NSError?) ->())?)
    {
        DataSource.sharedInstance.loadingAllElementsInProgress = true
        
        DataSource.sharedInstance.serverRequester.loadAllElements {(result, error) -> () in
            
            
            if let allElements = result as? [Element]
            {
                
                if allElements.isEmpty
                {
                    completion?(success: false, failure: nil)
                    return
                }
                
                DataSource.sharedInstance.localDatadaseHandler?.saveElementsToLocalDatabase(allElements, completion: { (didSave, error) -> () in
                    if didSave == true
                    {
//                        let backgroundQueue = dispatch_queue_create("elements-handler-queue", DISPATCH_QUEUE_SERIAL)
//                        dispatch_async(backgroundQueue, { () -> Void in
//                            DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
//                            
//                            
//                            let elementsSet = Set(allElements)
//                            var elementsArrayFromSet = Array(elementsSet)
//                            
//                            ObjectsConverter.sortElementsByDate(&elementsArrayFromSet)
//                            
//                            DataSource.sharedInstance.elements += elementsArrayFromSet
//                            print("\n -> Added Elements = \(elementsArrayFromSet.count)")
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                completion(success: true, failure: nil)
//                            })
//                        })
                        completion?(success:didSave, failure:error)
                    }
                    else
                    {
                        if let insertError = error
                        {
                            print(insertError)
                        }
                        completion?(success:didSave, failure:error)
                    }
                    
                    DataSource.sharedInstance.localDatadaseHandler?.performMessagesAndElementsPairing({ () -> () in
                        print("\n -> loadAllElementsInfo:   -   Did finish PAIRING elements and messages.")
                    })
                })
                
//                let backgroundQueue = dispatch_queue_create("elements-handler-queue", DISPATCH_QUEUE_SERIAL)
//                dispatch_async(backgroundQueue, { () -> Void in
//                    DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
//                    
//                    
//                    let elementsSet = Set(allElements)
//                    var elementsArrayFromSet = Array(elementsSet)
//                    
//                    ObjectsConverter.sortElementsByDate(&elementsArrayFromSet)
//                    
//                    DataSource.sharedInstance.elements += elementsArrayFromSet
//                    print("\n -> Added Elements = \(elementsArrayFromSet.count)")                
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        completion(success: true, failure: nil)
//                    })
//                })
                
            }
            else
            {
                completion?(success: false, failure: error)
            }
            
            DataSource.sharedInstance.loadingAllElementsInProgress = false
        }
    }
//    func countExistingElementsLocked() -> Int
//    {
//        var elementsCount:Int = 0
//        
//        let aLock =  NSLock()
//        aLock.lock()
//            elementsCount = DataSource.sharedInstance.elements.count
//        aLock.unlock()
//        
//        return elementsCount
//        
//    }
//    func getAllElementsLocked() -> [Element]?
//    {
//        let aLock = NSLock()
//        var elements = [Element]()
//        aLock.lock()
//            elements += DataSource.sharedInstance.elements
//        aLock.unlock()
//        
//        if elements.isEmpty
//        {
//            return nil
//        }
//        return elements
//    }
//    
//    func addElementsLocked(newElements:[Element])
//    {
//        let aLock = NSLock()
//        aLock.lock()
//        DataSource.sharedInstance.elements += newElements
//        
//        aLock.unlock()
//        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
//        NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil, userInfo: nil)
//        
//    }
//    
//
//    func replaceAllElementsToNew(newElements:[Element])
//    {
//        let aLock = NSLock()
//        aLock.name = "Elements replacer lock"
//        aLock.lock()
//        DataSource.sharedInstance.elements.removeAll(keepCapacity: true)
//        DataSource.sharedInstance.elements += newElements
//        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
//        aLock.unlock()
//        
//        NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil)
//    }
    
    func editElement(element:Element, completionClosure completion:((edited:Bool) -> ())? )
    {
        if let elementId = element.elementId //?.integerValue
        {
            DataSource.sharedInstance.serverRequester.editElement(element) { (success, error) -> () in
                
                    if success
                    {
                        if let existingElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
                        {
                            print(" ----> for elementID: \(elementId)")
                            existingElement.title = element.title
                            existingElement.details = element.details
                            //existingElement.isFavourite = NSNumber(bool:element.isFavourite)
                            existingElement.isSignal = NSNumber(bool:element.isSignal)
                            print("Saving new Type Id :\(element.typeId)")
                            existingElement.type = NSNumber(integer:element.typeId)
                            
                            existingElement.dateChanged = NSDate()
                            print("Saving new Responsible Id: \(element.responsible) ")
                            existingElement.responsibleId = NSNumber(integer:element.responsible)
                            
                            print("Saving new FinishState: \(element.finishState)")
                            
                            existingElement.finishState = NSNumber(integer:element.finishState)
                            existingElement.isSignal = NSNumber(bool:element.isSignal)
                            if let remindDate = element.remindDate
                            {
                                existingElement.dateRemind = remindDate
                            }
                            
                            if let rootTree = DataSource.sharedInstance.localDatadaseHandler?.readRootElementTreeForElementManagedObjectId(existingElement.objectID)
                            {
                                for aParent in rootTree
                                {
                                    aParent.dateChanged = existingElement.dateChanged
                                }
                            }
                            
                            existingElement.dateArchived = element.archiveDate?.dateFromServerDateString()
                            
                            if existingElement.isArchived()
                            {
                                if let info =  DataSource.sharedInstance.localDatadaseHandler?.readSubordinateElementsForDBElementIdSync(elementId, shouldReturnObjects: true)
                                {
                                    if info.count > 0
                                    {
                                        if let elements = info.elements
                                        {
                                            for anElementDb in elements
                                            {
                                                anElementDb.dateArchived = existingElement.dateArchived
                                            }
                                        }
                                    }
                                }
                                
                                DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext({ (saveError) -> () in
                                    if let error = saveError
                                    {
                                        print("did not save context because of Error:")
                                        print(error)
                                        completion?(edited: false)
                                    }
                                    else
                                    {
                                       completion?(edited: true)
                                    }
                                })
                            }
                            else
                            {
                                completion?(edited: success)
                            }
                            
                            DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                        }
                    }
                
            }
        }
    }
    
    func setElementFinishDate(elementId:Int, date:NSDate, completion:((success:Bool)->())?)
    {
        guard let dateString = date.dateForRequestURL() else
        {
            completion?(success:false)
            return
        }
        
        DataSource.sharedInstance.serverRequester.setElementFinished(elementId, finishDate: dateString) { (success) -> () in
            if success
            {
                if let existElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
                {
                    existElement.dateFinished = date
                }
            }
            completion?(success:success)
        }
    }
    
    func setElementFinishState(elementId:Int, newFinishState:Int, completion:((success:Bool)->())?)
    {
        DataSource.sharedInstance.serverRequester.setElementFinishState(elementId, finishState: newFinishState) { (success) -> () in
            if success
            {
                if let existingElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
                {
                    existingElement.finishState = NSNumber(integer: newFinishState)
                }
            }
            completion?(success: success)
        }
    }
    
    func updateElement(elementId:Int?, isFavourite favourite:Bool, completion completionClosure:((edited:Bool)->())? )
    {
        guard let anElementId = elementId else{
            completionClosure?(edited:false)
            return
        }
       
        DataSource.sharedInstance.serverRequester.setElementWithId(anElementId, favourite: favourite) { (success, error) -> () in
            
            if success
            {
                dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    
                    if let existingElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(anElementId)
                    {
                        existingElement.isFavourite = NSNumber(bool:favourite)
                        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                    }
                })
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure?(edited: true)
                })
            }
            else
            {
                completionClosure?(edited: false)
                print("Error did not update FAVOURITE for element.")
            }
        }
    }
    
    
    func loadPassWhomIdsForElement(elementIdInt:Int, comlpetion completionClosure:((finished:Bool)->())? ) {
        
        //let elementIdInt = element.elementId!.integerValue
        DataSource.sharedInstance.serverRequester.loadPassWhomIdsForElementID(elementIdInt, completion: { (passWhomIds, error) -> () in
            if let recievedIDs = passWhomIds
            {
                DataSource.sharedInstance.participantIDsForElement[elementIdInt] = Set(recievedIDs)
                completionClosure?(finished: true)
            }
            else
            {
                print("did not load passWhomIDs for element: \(elementIdInt)")
                completionClosure?(finished: false)
            }
        })
    }
    
    func deleteElementFromServer(elementId:Int, completion closure:(deleted:Bool, error:NSError?) ->())
    {
        DataSource.sharedInstance.serverRequester.deleteElement(elementId, completion: closure)
    }
    
    //MARK: - Attaches
    
    /**
    Queries attach info from the RAM
    - Returns: **nil** if no attaches info was found or if attaches info is empty
    */
    func getAttachesForElementById(elementId:Int?) -> [DBAttach]?
    {
        guard let lvElementId = elementId else
        {
            return nil
        }
        
        do
        {
            if let foundAttaches = try DataSource.sharedInstance.localDatadaseHandler?.readAttachesForElementById(lvElementId)
            {
               return foundAttaches
            }
            return nil
        }
        catch
        {
             return nil
        }
       
    }
    
    func loadAttachesInfoForElement(elementIdInt:Int, completion:attachesArrayClosure?)
    {
        let localInt = elementIdInt
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
  
        DataSource.sharedInstance.serverRequester.loadAttachesListForElementId(localInt,
        completion:
        { (result, error) -> ()
            in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let attachesArray = result as? [AttachFile]
            {
                completion?(attachesArray)
            }
            else
            {
                completion?(nil)
            }
        })
    }
    
    
    /** 
    Queries Attach Info from server
    
        - Parameters:
            - elementIdInt: integerValue of element to request attaches for
            - completion: block returns AttachFile array stored in memory or nil
    */
    func refreshAttachesForElement(elementIdInt:Int, completion:((info:(loaded:Int, saved:Int))->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        DataSource.sharedInstance.serverRequester.loadAttachesListForElementId(elementIdInt) { (result, error) -> ()
                in
            
                guard let attachesArray = result as? [AttachFile] else
                {
                    // there are no attaches for current element,  delete existing if present
                    do
                    {
                        try DataSource.sharedInstance.localDatadaseHandler?.deleteAllAttachesForElementById(elementIdInt)
                    }
                    catch let deletionError
                    {
                        print(" ataches cleaning error:")
                        print(deletionError)
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    completion?(info: (loaded: 0, saved: 0))
                    return
                }
                
                
                var setCurrentAttachIDs = Set<Int>()
                
                var dbAttaches = [DBAttach]()
                for attach in attachesArray
                {
                    setCurrentAttachIDs.insert(attach.attachID)
                    
                    do{
                        if let newAttach = try DataSource.sharedInstance.localDatadaseHandler?.saveAttachToLocalDatabase(attach, shouldSaveContext:false)
                        {
                            dbAttaches.append(newAttach)
                        }
                    }
                    catch let attachInsertError{
                        print(attachInsertError)
                    }
                }
                
                
                let savingGroup = dispatch_group_create()
            
                dispatch_group_enter(savingGroup)
            
                DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext({ (error) -> () in
                    
                    dispatch_group_leave(savingGroup)
                })
                
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 5.0))
               
                let waitResult = dispatch_group_wait(savingGroup, timeout)
                print(" - Saving op finished with esult: \(waitResult)")
   
                //if new attaches recieved, pair them to existing element if found
                var returnInfo = (loaded:attachesArray.count, saved:0)
                
                if !dbAttaches.isEmpty
                {
                    do{
                        try DataSource.sharedInstance.localDatadaseHandler?.addAttaches(dbAttaches, toElementById: elementIdInt)
                        returnInfo.saved = dbAttaches.count
                    }
                    catch let pairingError
                    {
                        print("Could not associate attach to element:")
                        print(pairingError)
                    }
                }
                
                
                var currentAttachesInDBset:Set<Int>?
                
                do{
                    if let currentlyExistingAttachesSet = try DataSource.sharedInstance.localDatadaseHandler?.allAttachesIDsForElementById(elementIdInt)
                    {
                        currentAttachesInDBset = currentlyExistingAttachesSet
                    }
                }catch{}
                
                
                if let currentAttachesSet = currentAttachesInDBset
                {
                    let attachIDsToDelete = currentAttachesSet.subtract(setCurrentAttachIDs)
                    if !attachIDsToDelete.isEmpty
                    {
                        for anAttachId in attachIDsToDelete
                        {
                            do{
                                try DataSource.sharedInstance.localDatadaseHandler?.deleteAttachById(anAttachId)
                            }
                            catch let deletionError {
                                print("did not delete attach:")
                                print(deletionError)
                            }
                        }
                    }
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                completion?(info:returnInfo)
        }
    }
    
    func attachFile(file:MediaFile, toElementId elementId:Int, completion completionClosure:((success:Bool, error: ErrorType?)->())? ) {
        
        guard elementId > 0 else
        {
            let errorId = NSError(domain: "Element id error", code: -65, userInfo: [NSLocalizedDescriptionKey:"Colud not start attaching file. Reason: wrong element id format."])
            completionClosure?(success: false, error: errorId)
            return
        }
        
        DataSource.sharedInstance.serverRequester.attachFile(file, toElement: elementId) { (successAttached, attachId ,errorAttached) -> () in
            
            if successAttached
            {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                print(" - upload succeeded. saving fileDataToDisc... ")
               
                do
                {
                    try DataSource.sharedInstance.saveAttachFileData(file.data, forAttachFileName: file.name)
                   
                    if let attachIdInt = attachId
                    {
                        let newFileAttach = AttachFile()
                        newFileAttach.attachID = attachIdInt
                        newFileAttach.elementID = elementId
                        newFileAttach.fileName = file.name
                        if let userId = DataSource.sharedInstance.user?.userId
                        {
                            newFileAttach.creatorID = userId
                        }
                        
                        if let attachDB = try DataSource.sharedInstance.localDatadaseHandler?.saveAttachToLocalDatabase(newFileAttach, shouldSaveContext: true)
                        {
                            do{
                                try DataSource.sharedInstance.localDatadaseHandler?.addAttaches([attachDB], toElementById: elementId)
                            }
                            catch{
                                
                            }
                        }
                    }
                                       
                    DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext({ (errorSaving) -> () in
                        if let error = errorSaving
                        {
                             completionClosure?(success: true, error: error)
                        }
                        else
                        {
                            completionClosure?(success: true, error: nil)
                        }
                       
                    })
                    
                }
                catch let saveError
                {
                    completionClosure?(success:true, error:saveError)
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            else
            {
                completionClosure?(success: false, error: errorAttached)
            }
        }
    }
    
    func saveAttachFileData(fileData:NSData, forAttachFileName fileName:String) throws
    {
        var errorSaving:NSError?
        
        dispatch_sync(getBackgroundQueue_SERIAL()) { _ in
            let lvFileHandle = FileHandler()
            lvFileHandle.saveFileToDisc(fileData, fileName: fileName, completion: { (filePath, saveError) -> Void in
                if filePath != nil
                {
                    print(" - saved fila to disc...")
                }
                else
                {
                    errorSaving = NSError(domain: "FileSavingError", code: -61, userInfo: [NSLocalizedDescriptionKey:"Could not save file to disc. \n Wanted path: \(filePath)"])
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
        }
        
        if let error = errorSaving
        {
            throw error
        }
       
    }
    
    
    func deleteAttachedFileNamed(file:(fileName:String, id:Int), fromElement elementId:Int, completion completionClosure:((success:Bool, error:NSError?)->())? ) {
        
        //response key "RemoveFileFromElementResult"
        do{
            if let attach = try DataSource.sharedInstance.localDatadaseHandler?.readAttachById(file.id)
            {
                do
                {
                    try DataSource.sharedInstance.localDatadaseHandler?.deleteAttach(attach, shouldSave: true)
                    print(" deleteAttachedFileNamed -> Deleted local database ATTACH... ")
                }
                catch let deletingError
                {
                    //deleting error
                    print(" deleteAttachedFileNamed ERROR: -> \(deletingError)")
                }
            }
        }
        catch let findingError
        {
            //attach finding eror
            print(" deleteAttachedFileNamed ERROR: -> \(findingError)")
        }
       
        
        print(" deleteAttachedFileNamed -> Sending Deleting attach from element query to server... ")
        
        DataSource.sharedInstance.serverRequester.unAttachFile(file.fileName, fromElement: elementId) { (success, fromServerError) -> () in
            let backgroundQueue = NSOperationQueue()
            backgroundQueue.maxConcurrentOperationCount = 1
            if success
            {
                print(" deleteAttachedFileNamed -> Deleted from server.")
            }
            else
            {
                print("\n deleteAttachedFileNamed -> Could not deAttach file on server: \n Error: \n\(fromServerError)")
            }
            completionClosure?(success: success, error: fromServerError)
        }
    }
    /**
    Function creates an instance of FileHandler and tries to erase file by file name, stored in AttachFile
    - Parameter attach: attach file that shoud be cleaned from user device`s disc
    */
    func eraseFileFromDiscForAttach(attachFileName:String)
    {
        let fileHandler = FileHandler()
        fileHandler.eraseFileNamed(attachFileName, completion: nil)
    }
    
    
    func getAttachPreviewForFileNamed(fileName:String) throws -> NSData
    {
        guard fileName.characters.count > 0 else
        {
            throw OrigamiError.PreconditionFailure(message: "File with empty file name requested.")
        }
        
        var error:ErrorType?
        let lvFileHandler = FileHandler()
      
        var returnPreviewData:NSData?
        
        let currentQueue = getBackgroundQueue_SERIAL()
        
        dispatch_sync(currentQueue) { _ in
            
            lvFileHandler.loadFileNamed(fileName) { (imageFullData, fileReadingError) -> Void in
                if let lvData = imageFullData
                {
                    let scale = UIScreen.mainScreen().scale
                    let size = CGSizeMake(90.0 * scale, 70.0 * scale)
                    guard let
                        fullImage = UIImage(data: lvData), scaledToSizeImage = DataSource.sharedInstance.reduceImageSize(fullImage, toSize: size),
                        imagePreviewData = UIImageJPEGRepresentation(scaledToSizeImage, 1.0)
                        else
                    {
                        error = OrigamiError.UnknownError
                        return
                    }
                    
                    returnPreviewData = imagePreviewData
                }
                else if let readError = fileReadingError as? ErrorType
                {
                    error = readError
                }
            }
        }
        
        if let anError = error
        {
            throw anError
        }
        
        if let data = returnPreviewData
        {
            return data
        }
        
        throw OrigamiError.UnknownError
    }
    
    /**
     Calls `eraseFileFromDiscForAttach` on every attach found for anElementId, then assigs nil to in-memory stored attchInfo array for element by Id
     - Parameter elementId: An integer value of element`s elementId property
     */
    func cleanAttachesForElement(elementId:Int)
    {
        if  let attaches = DataSource.sharedInstance.getAttachesForElementById(elementId)
        {
            for lvAttach in attaches
            {
                if let fileName = lvAttach.fileName
                {
                    DataSource.sharedInstance.eraseFileFromDiscForAttach(fileName) //delete files from disk
                }
            }
        }
    }
    
    func downloadAttachDataForAttachById(id:Int, completion:((data:NSData?, error:NSError?)->())? ) -> (Bool)
    {
        if let _ = DataSource.sharedInstance.pendingAttachFileDataDownloads[id]
        {
            return false
        }
        
        do
        {
            let downLoadAttachTask = try DataSource.sharedInstance.serverRequester.loadDataForAttach(id) {(attachFileData, loadingError) -> () in
                completion?(data:attachFileData, error: loadingError)
                
                DataSource.sharedInstance.cancelDownloadingFileForAttachById(id)
            }
            
            let downloadOperation = NSBlockOperation() { _ in
                
                downLoadAttachTask.resume()
            }
            
            if #available(iOS 8.0, *)
            {
                downloadOperation.qualityOfService = NSQualityOfService.Utility
            }
            else
            {
                downloadOperation.queuePriority = .Low
            }
            
            DataSource.sharedInstance.pendingAttachFileDataDownloads[id] = downLoadAttachTask
            
            DataSource.sharedInstance.avatarOperationQueue.addOperation(downloadOperation)
            
            return true
            
        }
        catch let taskCreationError
        {
            print("Could Not create attach File Data DOwnloading task:")
            print(taskCreationError)
            return false
        }
        
    }
    
    func cancelDownloadingAttachesByIDs(attachIDs:Set<Int>)
    {
        for anAttachId in attachIDs
        {
            DataSource.sharedInstance.pendingAttachFileDataDownloads[anAttachId]?.cancel()
            DataSource.sharedInstance.pendingAttachFileDataDownloads[anAttachId] = nil
        }
    }
    
    func cancelDownloadingFileForAttachById(id:Int) -> Bool
    {
        if let downloadingDataTask = DataSource.sharedInstance.pendingAttachFileDataDownloads[id]
        {
            downloadingDataTask.cancel()
            DataSource.sharedInstance.pendingAttachFileDataDownloads[id] = nil
            return true
        }
        return false
    }
    
    private func reduceImageSize(image:UIImage, toSize size:CGSize) -> UIImage?
    {
        //let reduceTagretSize = CGSizeMake(180, 140) // 90x70 cell size x 2
        //NSLog(" -> Image Size Before reducing: \(image.size)")
        
        let largestDimension:CGFloat = max(image.size.width, image.size.height)
        
        var ratio:CGFloat = 1.0
        if largestDimension == image.size.width
        {
            ratio = (size.width / largestDimension)
        }
        else if largestDimension == image.size.height
        {
            ratio = (size.height / largestDimension)
        }
        
        let reducedImageSize = CGSizeMake(image.size.width * ratio, image.size.height * ratio)
        if let scaledToSizeImage = image.scaleToSizeKeepAspect(reducedImageSize)
        {
            //NSLog(" -> Image Size After reducing: \(scaledToSizeImage.size)")
            return scaledToSizeImage
        }
        
        return nil
    }
    
    
    
    //MARK: - Contact
    func addNewContacts(contacts:[Contact], completion:voidClosure?)
    {        
        DataSource.sharedInstance.contacts += contacts
        if completion != nil
        {
            completion!()
        }
    }
    /**
     - TODO: get rid of dispatch_semaphore with delay of 3 seconds
     */
    func getMyContacts() throws -> [DBContact]
    {
        var contactsToReturn:[DBContact]?
        let dbReadingSemaphore = dispatch_semaphore_create(0)
        DataSource.sharedInstance.localDatadaseHandler?.readAllMyContacts({ (presentContacts) -> () in
            if let foundContacts = presentContacts
            {
                contactsToReturn = foundContacts
            }
            dispatch_semaphore_signal(dbReadingSemaphore)
        })
       
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 3.0)) //3 seconds should be enough to read all contacts from sqLite database
       
        dispatch_semaphore_wait(dbReadingSemaphore, timeout)
        
        if let contacts = contactsToReturn
        {
            let counter = contacts.count
            print("returning existing contacts (\(counter))")
            return contacts
        }
        
        throw OrigamiError.NotFoundError(message: " -> getMyContacts() -> No contacts found in local database.")
    }
    
    /**
     starts downloading user`s contacts from server and saving them to local database if loaded any contacts
     - completion contains SAVE value of localDatabaseHandler and error from it, or error from server request prompt
     */
    func downloadMyContactsFromServer(completion:((didSaveToLocalDatabase:Bool, error:NSError?)->())?)
    {
        DataSource.sharedInstance.serverRequester.downloadMyContacts { (contacts, error) -> () in
            if let recievedContacts = contacts
            {
                DataSource.sharedInstance.localDatadaseHandler?.saveContactsToDataBase(recievedContacts) { (saved, error) -> () in
                    completion?(didSaveToLocalDatabase: saved, error: error)
                }
            }
            else
            {
                completion?(didSaveToLocalDatabase: false, error: error)
            }
        }
    }
    
    func getAllContacts(completion:((contacts:[Contact]?, error:NSError?)->())?) throws -> NSURLSessionDataTask
    {
        do
        {
            let allContactsTask = try DataSource.sharedInstance.serverRequester.loadAllContacts(completion)
            return allContactsTask
        }
        catch let error
        {
            throw error
        }
    }
    
    
    
    func getContactsByIds(contactIDs:Set<Int>) -> [Contact]?
    {
        if !DataSource.sharedInstance.contacts.isEmpty
        {
            let foundContacts = DataSource.sharedInstance.contacts.filter({ (contact) -> Bool in
                
                if contactIDs.contains(contact.contactId)
                {
                    return true
                }
                
                return false
            })
            
            if !foundContacts.isEmpty
            {
                return foundContacts
            }
            
        }
        return nil
    }
//    
//    func getContactsForElement(elementId:Int, completion:contactsArrayClosure?)
//    {
//        if let completionClosure = completion
//        {
//            var contactsToReturn:[Contact]
//            
//            if let lvElement = DataSource.sharedInstance.getElementById(elementId)
//            {
//                if lvElement.passWhomIDs.count > 0
//                {
//                    contactsToReturn = [Contact]()
//                    for lvContactId in lvElement.passWhomIDs
//                    {
//                        var lvContacts = DataSource.sharedInstance.contacts.filter {lvContact -> Bool in
//                            
//                            return (lvContact.contactId == lvContactId)
//                        }
//                        
//                        if lvContacts.count > 0
//                        {
//                            let lastContact = lvContacts.removeLast()
//                            contactsToReturn.append(lastContact)
//                        }
//                    }
//                    
//                    if contactsToReturn.isEmpty
//                    {
//                        completionClosure(nil)
//                        return
//                    }
//                    completionClosure(contactsToReturn)
//                    return
//                }
//            }
//            
//            completionClosure(nil)
//            return
//        }
//    }
    
    func addContact(contactId:Int, toElement elementId:Int, completion completionClosure:(success:Bool, error:NSError?) -> ())
    {
        DataSource.sharedInstance.serverRequester.passElement(elementId, toContact: contactId, forDeletion: false) { (requestSuccess, resuertError) -> () in
           
            if requestSuccess
            {
                DataSource.sharedInstance.participantIDsForElement[elementId]?.insert(contactId)
            }
            completionClosure(success: requestSuccess, error: resuertError)
        }
    }
    
    func removeContact(contactId:Int, fromElement elementId:Int, completion completionClosure:(success:Bool, error:NSError?) -> ())
    {
        DataSource.sharedInstance.serverRequester.passElement(elementId, toContact: contactId, forDeletion: true) { (requestSuccess, resuertError) -> () in
            
            if requestSuccess
            {
                DataSource.sharedInstance.participantIDsForElement[elementId]?.remove(contactId)
            }
            
            completionClosure(success:requestSuccess, error: resuertError)
        }
    }
    
    func addSeveralContacts(contactIDs:Set<Int>?, toElement elementId:Int, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())? )
    {
        guard let contactNumbers = contactIDs else
        {
            completionClosure?(succeededIDs: [], failedIDs: [])
            return
        }
        
        if contactNumbers.isEmpty
        {
            completionClosure?(succeededIDs: [], failedIDs: [])
            return
        }
        
        let backgroundQueue = NSOperationQueue()
        
        backgroundQueue.maxConcurrentOperationCount = 2
        
        backgroundQueue.addOperationWithBlock(){ () -> Void in
            
            DataSource.sharedInstance.serverRequester.passElement(elementId, toSeveratContacts: contactNumbers) { (succeededIDs, failedIDs) -> () in

                if !succeededIDs.isEmpty
                {
//                    if let existingElement = DataSource.sharedInstance.getElementById(elementId)
//                    {
//                        var alreadyExistIDsSet = Set<Int>()
//                        for number in existingElement.passWhomIDs
//                        {
//                            alreadyExistIDsSet.insert(number)
//                        }
//                        
//                        let succseededIDsSet = Set(succeededIDs)
//                        
//                        let commonValuesSet = alreadyExistIDsSet.union(succseededIDsSet)
//                        
//                        var idsArray = [Int]()
//                        for integer in commonValuesSet
//                        {
//                            idsArray.append(integer)
//                        }
//                        
//                        existingElement.passWhomIDs = idsArray
//                        
//                    }
                }
                else
                {
                    if failedIDs.count > 0
                    {
                        print("failed to assign contacts to current element: Contact IDs: \(failedIDs)")
                    }
                }

                completionClosure?(succeededIDs: succeededIDs, failedIDs: failedIDs)
            }
            
        }//end of operationQueue Block
            

        
        
    }
    
    func removeSeveralContacts(contactsIDsSet:Set<Int>, fromElement elementId:Int, completion completionBlock:((succeededIDs:[Int]?, failedIDs:[Int]?)->())?)
    {
        NSOperationQueue().addOperationWithBlock { () -> Void in
            DataSource.sharedInstance.serverRequester.unPassElement(elementId, fromSeveralContacts: contactsIDsSet) { (succeededIds, failedIds) -> () in
                
                if let existingParticipants = DataSource.sharedInstance.participantIDsForElement[elementId]
                {
                    if !succeededIds.isEmpty
                    {
                        let succeededSet = Set(succeededIds)
                        let currentPassWhomIDs = existingParticipants.subtract(succeededSet)
                        
//                        let filteredOut = currentPassWhomIDs.filter({ (contactID) -> Bool in
//                            if succeededSet.contains(contactID)
//                            {
//                                return false
//                            }
//                            return true
//                        })
                        DataSource.sharedInstance.participantIDsForElement[elementId] = currentPassWhomIDs
                    }
                    if !failedIds.isEmpty
                    {
                        print("\n FAILED to detach contacts:\(failedIds) from element \(elementId)\n")
                    }
                }
                
                if let completionClosure = completionBlock
                {
                    completionClosure(succeededIDs: succeededIds, failedIDs: failedIds)
                }
            }
        }
        
    }
    
    
    func updateContactIsFavourite(contactId:Int, completion:((success:Bool, error:NSError?)->())?)
    {
        DataSource.sharedInstance.serverRequester.toggleContactFavourite(contactId, completion: { (success, error) -> () in
           
            if let errorForRequest = error
            {
                if let completionBlock = completion
                {
                    completionBlock(success: false, error: errorForRequest)
                }
            }
            else
            {
                if let completionBlock = completion
                {
                    completionBlock(success: true, error: nil)
                }
            }
        })
    }
    
    func deleteMyContact(contact:Contact, completion:((success:Bool, error:NSError?)->())?)
    {
        guard contact.contactId > 0 else
        {
            completion?(success:false, error:NSError(domain: "com.Origami.InvalidContactIdError", code: -3030, userInfo: [NSLocalizedDescriptionKey:"Requested deletion of contact with id == 0(zero)"]))
            return
        }
        
        DataSource.sharedInstance.serverRequester.removeMyContact(contact.contactId, completion: { (success, error) -> () in
            if success
            {
                var currentContacts = Set(DataSource.sharedInstance.contacts)
                let countBefore = currentContacts.count
                currentContacts.remove(contact)
                let countAfter = currentContacts.count
                if countAfter == countBefore
                {
                    print("\n Warning!! DataSource did NOT REMOVE contact from mycontacts\n")
                }
                
                let sorted = Array(currentContacts).sort({ (contact1, contact2) -> Bool in
                    if let
                        firstName1 = contact1.firstName, //as? String,
                        firstName2 = contact2.firstName //as? String
                    {
                        return firstName1.caseInsensitiveCompare(firstName2) == .OrderedAscending
                    }
                    
                    return true
                })
                
                DataSource.sharedInstance.contacts = sorted
            }
            
            //return from function
            if let completionBlock = completion
            {
                completionBlock(success: success, error: error)
            }
        })
    }
    
    func addNewContactToMyContacts(contact:Contact, completion:((success:Bool, error:NSError?)->())?)
    {
        guard contact.contactId > 0 else
        {
            completion?(success:false, error:NSError(domain: "com.Origami.InvalidContactIdError", code: -3031, userInfo: [NSLocalizedDescriptionKey:"Requested adding of contact with id == 0(zero)"]))
            return
        }
        
        DataSource.sharedInstance.serverRequester.addToMyContacts(contact.contactId, completion: { (success, error) -> () in
            if success
            {                
                DataSource.sharedInstance.localDatadaseHandler?.saveContactsToDataBase([contact], completion: { (saved, error) -> () in
                    if saved{
                        completion?(success:true, error: nil)
                    }
                    else if let saveError = error
                    {
                        completion?(success:false, error:saveError)
                    }
                    else{
                        completion?(success:saved, error:nil)
                    }
                })
                return
            }
            
            completion?(success:success, error:error)
        })
    }
    
    
    func searchForContactByEmail(emailString:String, completion:((Contact?)->())?)
    {
        dispatch_async( getBackgroundQueue_UTILITY()) {
           
            DataSource.sharedInstance.serverRequester.searchForNewContactByEmail(emailString) { (userInfo, error) -> () in
                
                dispatch_async(dispatch_get_main_queue()) {
                        if let lvError = error
                        {
                            completion?(nil)
                            print("Could not fing person by given email: ")
                            
                            print(lvError)
                            return
                        }
                        
                        guard let info = userInfo else
                        {
                            completion?(nil)
                            return
                        }
                        
                        let aContact = Contact(info: info)
                        
                        completion?(aContact)
                }
            }
        }       
    }
    
    //MARK: - Avatars
    
    func getAvatarForUserId(userIdInt:Int) -> UIImage?
    {
        if let ramImage = DataSource.sharedInstance.userAvatarsHolder[userIdInt]
        {
            return ramImage
        }
        
        if let avatarData = DataSource.sharedInstance.localDatadaseHandler?.readAvatarPreviewForContactId(userIdInt), image = UIImage(data: avatarData)
        {
            DataSource.sharedInstance.userAvatarsHolder[userIdInt] = image
            return self.getAvatarForUserId(userIdInt)
        }
        
        return nil
    }
    
    func loadAvatarFromDiscForLoginName(loginName:String, completion completionBlock:((image:UIImage?, error:NSError?) ->())? )
    {
        let fileHandler = FileHandler()
        
        fileHandler.loadAvatarDataForLoginName(loginName) { (avatarData, error) -> Void in
            if let fileData = avatarData
            {
                guard let image = UIImage(data: fileData) else
                {
                    let imageCreatingError = NSError(domain: "Origami.ImageDataConvertingError", code: 509, userInfo: [NSLocalizedDescriptionKey:"Could not convert data object to image object"])
                    completionBlock?(image: nil, error: imageCreatingError)

                    return
                }
                completionBlock?(image: image, error: nil)
            }
            else if let fileError = error
            {
                completionBlock?(image:nil, error: fileError)
            }
        }
    }
    
    func startLoadingAvatarForUserName(info:(name:String, id:Int))
    {
        let aName = info.name
        
        if let _ = DataSource.sharedInstance.pendingUserAvatarsDownolads[aName]
        {
            print(" - Current avatar is pending. Will not try to load in again...")
            return
        }
        
        print(" Loading Avatar: \(aName)")
        
        DataSource.sharedInstance.pendingUserAvatarsDownolads[aName] = Int(1)
        let syncingContactId = info.id
        
        DataSource.sharedInstance.serverRequester.loadAvatarDataForUserName(aName, completion: { (avatarData, error) -> () in
            if let avatarBytes = avatarData
            {
                //debug  
                print("-> Downloaded \(avatarBytes.length) bytes for avatar.")
                
                if let avatar = UIImage(data: avatarBytes)
                {
                    if let reducedImage = DataSource.sharedInstance.reduceImageSize(avatar, toSize: CGSizeMake(200, 200)), let avatarData = UIImageJPEGRepresentation(reducedImage, 1.0)
                    {
                        print(" got avatar from Server... Saving small preview data to ram")
                        //DataSource.sharedInstance.addAvatarData(avatarData, forContactUserName: aName)//save to RAM also
                        DataSource.sharedInstance.userAvatarsHolder[syncingContactId] = reducedImage
                        DataSource.sharedInstance.localDatadaseHandler?.saveAvatarPreview(avatarData, forUserId: syncingContactId, fileName: aName)
                    }
                    
                    //save to disc
                    print(" saving avatar to disc...")
                    let fileHandler = FileHandler()
                    fileHandler.saveAvatar(avatarBytes, forLoginName: aName, completion: { (errorSaving) -> Void in
                        if let error = errorSaving
                        {
                            print(" Did not save currently loaded avatar for user name: \(aName) \n Error: \(error.localizedDescription)")
                        }
                        DataSource.sharedInstance.pendingUserAvatarsDownolads[aName] = nil
                        DataSource.sharedInstance.setLastAvatarSyncDate(NSDate(), forContactId: syncingContactId)
                        let avatarFinishLoadingNotif = NSNotification(name: kAvatarDidFinishDownloadingNotification, object: nil, userInfo: ["userName":aName, "userId":info.id])
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                           NSNotificationCenter.defaultCenter().postNotification(avatarFinishLoadingNotif)
                        })
                        
                    })
                }
                else
                {
                    print(" Did not recieve avatar image bytes.")
                    DataSource.sharedInstance.pendingUserAvatarsDownolads[aName] = nil
                    let avatarFinishLoadingNotif = NSNotification(name: kAvatarDidFinishDownloadingNotification, object: nil, userInfo: ["userName":aName, "userId":info.id])
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotification(avatarFinishLoadingNotif)
                    })
                }
             
                return
            }
            
            if let anError = error
            {
                print(" Error while downloading avatar for userName: \(aName): \n \(anError.description) ")
            }
            DataSource.sharedInstance.pendingUserAvatarsDownolads[aName] = nil
            let avatarFinishLoadingNotif = NSNotification(name: kAvatarDidFinishDownloadingNotification, object: nil, userInfo: ["userName":aName, "userId":info.id])
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotification(avatarFinishLoadingNotif)
            })
        })

    }
    
    func uploadAvatarForCurrentUser(data:NSData, completion completionBlock:((success:Bool, error:NSError?)->())?)
    {
        DataSource.sharedInstance.serverRequester.uploadUserAvatarBytes(data, completion: { (response, error) -> () in
            if let _ = response
            {
                completionBlock?(success: true, error: nil)
                
                //save to disc
                if let userName = DataSource.sharedInstance.user?.userName //as? String
                {
                    let fileHandler = FileHandler()
                    fileHandler.saveAvatar(data, forLoginName: userName, completion: { (error) -> Void in
                        if let saveError = error
                        {
                            print("-> Could not update current user avatar on disc. \n->Error: \(saveError)")
                            return
                        }
                    })
                }
            }
            else if let errorSending = error
            {
                completionBlock?(success: false, error: errorSending)
            }
            else
            {
                completionBlock?(success: false, error: nil)
            }
        })
    }
    
    /**
    Cleans avatar file from disc and removes avatar preview from RAM
    */
    func cleanAvatarDataForUserName(name:String, userId:Int)
    {
        let aFileHandler = FileHandler()
        aFileHandler.eraseAvatarForUserName(name, completion: nil)
        DataSource.sharedInstance.userAvatarsHolder[userId] = nil
        DataSource.sharedInstance.localDatadaseHandler?.eraseAvatarPreviewForUserId(userId)
    }
    /**
    Synchronous method that searches for existing dictionary in UserDefaults and overrides it if found.  If no stored info found, it creates info dictionsty with passed values
    - Note: consider using non main thread when calling it.
    - Note: *synchronize* is not called by this method
    */
    func setLastAvatarSyncDate(date:NSDate, forContactId:Int)
    {
        if let syncInfo = NSUserDefaults.standardUserDefaults().objectForKey(kAvatarsSyncHolder) as? [String:NSDate]
        {
            var newSyncInfo = syncInfo
            newSyncInfo["\(forContactId)"] = date
            
            NSUserDefaults.standardUserDefaults().setObject(newSyncInfo, forKey: kAvatarsSyncHolder)
        }
        else{
            
            let newSyncInfo = ["\(forContactId)" : date]
            
            NSUserDefaults.standardUserDefaults().setObject(newSyncInfo, forKey: kAvatarsSyncHolder)
        }
    }
    /**
    synchronous method, which reads NSUserDefaults.
    - Note: Consider threading, when calling it.
    */
    func getLastAvatarSyncDateForContactId(contactId:Int) -> NSDate?
    {
        if let syncInfo = NSUserDefaults.standardUserDefaults().objectForKey(kAvatarsSyncHolder) as? [String:NSDate]
        {
            if let syncDate = syncInfo["\(contactId)"]
            {
                print("\n-> Last Avatar Sync Date for ContactId: \(contactId)  is \(syncDate)")
                return syncDate
            }
        }
        return nil
    }
    
    //MARK: - Languages & Countries
    func getCountries(completion:((countries:[Country]?, error:NSError?)->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let bgQueue = dispatch_queue_create("filereader.queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue, { () -> Void in
            
            let aFileHandler = FileHandler()
            if let countriesDictsArray = aFileHandler.getCountriesFromDisk() as? [[String:AnyObject]]
            {
                if let aCountries = ObjectsConverter.convertToCountries(countriesDictsArray)
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    completion?(countries:aCountries, error:nil)
                }
                else
                {
                    DataSource.sharedInstance.serverRequester.loadCountries { (countries, error) -> () in
                        if let aCountries = countries
                        {
                            if let dictionaries = ObjectsConverter.convertCountriesToPlistArray(aCountries)
                            {
                                aFileHandler.saveCountriesToDisk(dictionaries)
                            }
                            
                            completion?(countries:aCountries, error:nil)
                        }
                        else
                        {
                            completion?(countries: nil, error: nil)
                        }
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                }
            }
            else
            {
                DataSource.sharedInstance.serverRequester.loadCountries { (countries, error) -> () in
                    if let aCountries = countries
                    {
                        if let dictionaries = ObjectsConverter.convertCountriesToPlistArray(aCountries)
                        {
                            aFileHandler.saveCountriesToDisk(dictionaries)
                        }
                        
                        completion?(countries:aCountries, error:nil)
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }
            
        })
    }
    
    func getLanguages(completion:((languages:[Language]?, error:NSError?)->())?)
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let bgQueue = dispatch_queue_create("filereader.queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue, { () -> Void in
            
            let aFileHandler = FileHandler()
            if let languageDictsArray = aFileHandler.getLanguagesFromDisk() as? [[String:AnyObject]]
            {
                if let langArray = ObjectsConverter.convertToLanguages(languageDictsArray)
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    completion?(languages:langArray, error:nil)
                }
                else
                {
                    DataSource.sharedInstance.serverRequester.loadLanguages({ (languages, error) -> () in
                        if let  langArray = languages
                        {
                            if let dictionaries = ObjectsConverter.convertLanguagesToPlistArray(langArray)
                            {
                                aFileHandler.saveLanguagesToDisk(dictionaries)
                            }
                            completion?(languages:langArray, error:nil)
                        }
                        else
                        {
                            completion?(languages:nil, error:nil)
                        }
                    })
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            }
            else
            {
                DataSource.sharedInstance.serverRequester.loadLanguages({ (languages, error) -> () in
                    if let  langArray = languages
                    {
                        if let dictionaries = ObjectsConverter.convertLanguagesToPlistArray(langArray)
                        {
                            aFileHandler.saveLanguagesToDisk(dictionaries)
                        }
                        completion?(languages:langArray, error:nil)
                    }
                    else
                    {
                        completion?(languages:nil, error:nil)
                    }
                })
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }) //end of dispatch queue block
    }
    
    func countryByName(countryName:String?) -> Country?
    {
        guard let name = countryName else
        {
            return nil
        }
        
        for aCountry in DataSource.sharedInstance.countries
        {
            if aCountry.countryName == name
            {
                return aCountry
            }
        }
        
        return nil
    }
    
    func languageByName(languageName:String?) -> Language?
    {
        guard let name = languageName else
        {
            return nil
        }
        
        for aLanguage in DataSource.sharedInstance.languages
        {
            if aLanguage.languageName == name
            {
                return aLanguage
            }
        }
        
        return nil
    }
}
