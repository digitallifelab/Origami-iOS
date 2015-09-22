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
    }
    
    override init() {
        super.init()
        
        self.dataCache.countLimit = 50
        
//        self.databaseHandler = DatabaseHandler(completionCallBack: {[weak self] () -> Void in
//            println("Finished initializing CoreData handler in DataSource.");
//        })
    }
    
    //singletone
    static let sharedInstance = DataSource()
    
    // properties
    lazy var messagesObservers = [NSNumber:MessageObserver]()
    
    var user:User?
    
    private var messages =  [NSNumber:[Message]] () // {elementId: [Messages]}
    
    private lazy var contacts = [Contact]()
    
    private lazy var elements = [Element]()
    
    private lazy var attaches = [NSNumber:[AttachFile]]()
    
    private lazy var avatarsHolder = [String:NSData]()
    
    private let serverRequester = ServerRequester()
    #if SHEVCHENKO
    #else
       private var databaseHandler:DatabaseHandler?
    #endif
 
    var shouldReloadAfterElementChanged = false
    var isRemovingObsoleteMessages = false
    var shouldLoadAllMessages = true
    
    var messagesLoader:MessagesLoader?
    var dataRefresher:DataRefresher?
    
    private lazy var dataCache:NSCache = NSCache()
    lazy var pendingAttachFileDataDownloads = [NSNumber:Bool]()
    lazy var pendingUserAvatarsDownolads = [String:Int]()
    //private stuff
    private func getMessagesObserverForElementId(elementId:NSNumber) -> MessageObserver?
    {
        if let existingObserver = DataSource.sharedInstance.messagesObservers[elementId]
        {
            return existingObserver
        }
        return nil
    }
    
    
    func saveDB()
    {
        #if SHEVCHENKO
        #else
        DataSource.sharedInstance.databaseHandler?.save()
        #endif
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
            DataSource.sharedInstance.user = nil
            DataSource.sharedInstance.cleanDataCache()
            DataSource.sharedInstance.contacts.removeAll(keepCapacity: false)
            DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
            DataSource.sharedInstance.attaches.removeAll(keepCapacity: false)
            println("AvatarsHolder Before cleaning: \(DataSource.sharedInstance.avatarsHolder.count)")
            DataSource.sharedInstance.avatarsHolder.removeAll(keepCapacity: false)
            println("AvatarsHolder After cleaning: \(DataSource.sharedInstance.avatarsHolder.count)")
            DataSource.sharedInstance.stopRefreshingNewMessages()
            DataSource.sharedInstance.messagesLoader?.cancelDispatchSource()
            
            DataSource.sharedInstance.removeAllObserversForNewMessages()
            
            DataSource.sharedInstance.messagesLoader = nil
            
            NSUserDefaults.standardUserDefaults().removeObjectForKey(passwordKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            if  completion != nil
            {
                //return into main queue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion!()
                })
            }
            
            let aFiler = FileHandler()
            aFiler.deleteAvatars()
            aFiler.deleteAttachedImages()
        })
    }
    
    func cleanDataCache()
    {
        println("..Datasource is clearing Data Cache...")
        
        DataSource.sharedInstance.dataCache.removeAllObjects()
    }
    //MARK: User
    func tryToGetUser(completion:(user:User?, error:NSError?)->())
    {
        if DataSource.sharedInstance.user != nil
        {
            completion(user: DataSource.sharedInstance.user, error: nil)
            return
        }
        
        //try to perform auto login
        
        if let userName = NSUserDefaults.standardUserDefaults().objectForKey(loginNameKey) as? String, let password = NSUserDefaults.standardUserDefaults().objectForKey(passwordKey) as? String
        {
            serverRequester.loginWith(userName, password: password, completion: { (userResult, loginError) -> () in
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
        }
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
    
    //MARK: Message
    
    func isMessagesEmpty() -> Bool{
        return DataSource.sharedInstance.messages.isEmpty
    }
    
    func loadAllMessagesFromServer()
    {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        DataSource.sharedInstance.serverRequester.loadAllMessages {
            (resultArray, serverError) -> () in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                if let messagesArray = resultArray as? [Message]
                {
                    var lvMessagesHolder = [NSNumber:[Message]]()
                    for lvMessage in messagesArray
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
                        for (keyElementId, messages) in lvMessagesHolder
                        {
                            DataSource.sharedInstance.addMessages(messages, forElementId: keyElementId, completion: nil)
                        }
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoadingMessages, object: DataSource.sharedInstance)
                        
                        if let observerForHomeScreen = DataSource.sharedInstance.messagesObservers[All_New_Messages_Observation_ElementId]
                        {
                            DataSource.sharedInstance.getLastMessagesForDashboardCount(MaximumLastMessagesCount, completion: { (lastMessages) -> () in
                        
                                if let lastMessagesReal = lastMessages
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        observerForHomeScreen.newMessagesAdded(lastMessagesReal)
                                    })
                                }
                            })
                        }
                        
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    DataSource.sharedInstance.messagesLoader = MessagesLoader()
                    DataSource.sharedInstance.startRefreshingNewMessages()
                    
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
         
        }
    }
    
    func sendNewMessage(message:Message, completion:errorClosure)
    {
        //can be not main queue
        let elementId = message.elementId?.integerValue

        serverRequester.sendMessage(message, toElement: message.elementId!) { (result, error) -> () in
            
            //main queue
            if error != nil
            {
                completion(error)
            }
            else
            {
                DataSource.sharedInstance.addMessages([message], forElementId: message.elementId!, completion: nil)
                //return callback to ChatVC
                completion(nil)
                
                if let intElementId = elementId
                {
                    if let existingElement = DataSource.sharedInstance.getElementById(intElementId)
                    {
                        let date = NSDate()
                        if let currentStringDate = date.dateForServer()
                        {
                            existingElement.changeDate = currentStringDate
                            if let rootTree = DataSource.sharedInstance.getRootElementTreeForElement(existingElement)
                            {
                                for aParent in rootTree
                                {
                                    aParent.changeDate = existingElement.changeDate
                                }
                            }
                            DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                        }
                    }
                }
            }
        }
    }
    
    func addMessages(messageObjects:[Message], forElementId elementId:NSNumber, completion:voidClosure?)
    {
        // add to our array container
        if let existingMessages = messages[elementId]
        {
            var mutableExisting = existingMessages
            mutableExisting += messageObjects// addObjectsFromArray:
            //replace existing messages with new array
            messages[elementId] = mutableExisting
        }
        else
        {
            messages[elementId] = messageObjects
        }
        
        // also check if there are any observers waiting for new messages
        if let observer =  getMessagesObserverForElementId(elementId)
        {
           observer.newMessagesAdded(messageObjects)
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
    
    func getMessagesQuantyty(quantity:Int, forElementId elementId:NSNumber?, lastMessageId messageId:NSNumber?) -> [Message]?
    {
        if elementId == nil
        {
            return nil//[Message]()
        }
        
        let validQuantity = max(0, min(quantity, Int.max))
        
        
        if let existingMessagesForElementId = DataSource.sharedInstance.getAllMessagesForElementId(elementId!)
        {
            var messagesToReturn:[Message] = [Message]()
            let existingCount:Int = existingMessagesForElementId.count
            
            if messageId != nil
            {
                if validQuantity >= existingCount
                {
                    messagesToReturn += existingMessagesForElementId
                }
                else
                {
                    let reversedArray = existingMessagesForElementId//.reverse()
                    for var i = 0; i < validQuantity; i++
                    {
                        let lvMessageToCheck = reversedArray[i]
                        if lvMessageToCheck.messageId?.integerValue == messageId // stop adding messages to returning array and quit
                        {
                            break
                        }
                        messagesToReturn.insert(reversedArray[i], atIndex: 0)
                    }
                }
            }
            else // no messageID specified returning last messages by quantity
            {
                if validQuantity >= existingCount
                {
                    messagesToReturn += existingMessagesForElementId
                }
                else
                {
                    let reversedArray = existingMessagesForElementId//.reverse()
                    for var i = 0; i < validQuantity; i++
                    {
                        messagesToReturn.insert(reversedArray[i], atIndex: 0)
                    }
                }
            }
            messagesToReturn.sort({ (message1, message2) -> Bool in
                return (message1.dateCreated!.compare(message2.dateCreated!) == NSComparisonResult.OrderedAscending)
            })
            return messagesToReturn
        }
        else
        {
            return nil //[Message]()//empty array
        }
    }
    
    func getChatPreviewMessagesForElementId(elementId:NSNumber) -> [Message]?
    {
        let messagesQuantity:Int = 3
        if let existingMessagesForElementId = DataSource.sharedInstance.getAllMessagesForElementId(elementId)
        {
            let sorted = existingMessagesForElementId.sorted { (message1, message2) -> Bool in
                return (message1.dateCreated!.compare(message2.dateCreated!) == NSComparisonResult.OrderedAscending)
            }
            let count = sorted.count
            if count <= messagesQuantity
            {
                return sorted
            }
            else
            {
                var messagesToReturn = [Message]()
                for var i = count - 1; i > count - (messagesQuantity + 1); i--
                {
                    let lastMessage = sorted[i]
                    messagesToReturn.insert(lastMessage, atIndex: 0)
                    //println(" i = \(i)")
                }
                
                return messagesToReturn
            }
        }
        return nil
    }
    
    func getLastMessagesForDashboardCount(messagesQuantity:Int, completion completionClosure:((messages:[Message]?)->())? = nil)
    {
        
        let bgQueue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        dispatch_async(bgQueue, { () -> Void in
            if DataSource.sharedInstance.messages.isEmpty
            {
                
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let completionBlock = completionClosure
                        {
                            completionBlock(messages: nil)
                        }
                    })
                return
            }
            
            var allMessagesSet = Set<Message>()
            for (_,lvMessages) in DataSource.sharedInstance.messages
            {
                allMessagesSet.unionInPlace( Set(lvMessages))
            }
            var sortedArray = Array(allMessagesSet)
            
            ObjectsConverter.sortMessagesByDate(&sortedArray)
            

                var lastThreeItems = [Message]()
                let reversed = sortedArray.reverse()
                var index = 0
            
            var elementIDsToDeleteMessageSet = Set<NSNumber>()
            for aMessage in reversed
            {
                if lastThreeItems.count > 2
                {
                    break
                }
                
                let lastMessage = reversed[index]
                index += 1
                
                if let elementId = lastMessage.elementId
                {
                    if let existElementForMEssage = DataSource.sharedInstance.getElementById(elementId.integerValue)
                    {
                        lastThreeItems.insert(lastMessage, atIndex: 0)
                    }
                    else
                    {
                        elementIDsToDeleteMessageSet.insert(elementId)
                    }
                }
                
            }
            
            if !elementIDsToDeleteMessageSet.isEmpty
            {
                println(" \n -> deleting messages for non existing elements...")
                DataSource.sharedInstance.removeMessagesForDeletedElements(elementIDsToDeleteMessageSet)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let completionBlock = completionClosure
                {
                    completionBlock(messages: lastThreeItems) //return result
                }
            })
        })
        
    }
    
    func addObserverForNewMessagesForElement(newObserver:MessageObserver, elementId:NSNumber) -> ResponseType
    {
        var response:ResponseType
        if let existingMessagesObserver = DataSource.sharedInstance.getMessagesObserverForElementId(elementId) // array exists for this element
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
    
    func removeMessagesForDeletedElements(elementIDs:Set<NSNumber>)
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
                if DataSource.sharedInstance.messages.removeValueForKey(anId) != nil
                {
                    println(" -> Deleted messages array.")
                }
            }
        }
        aLock.unlock()
        
        DataSource.sharedInstance.isRemovingObsoleteMessages = false
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
            }
            else
            {
                if let messagesArray = messages
                {
                    var lvMessagesHolder = [NSNumber:[Message]]()
                    for lvMessage in messagesArray
                    {
                        println(" ->New message: >>> \(lvMessage.toDictionary().description)))")
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
                        for (keyElementId, messages) in lvMessagesHolder
                        {
                            DataSource.sharedInstance.addMessages(messages, forElementId: keyElementId, completion: nil)
                        }
                        
                        
                        if let observerForHomeScreen = DataSource.sharedInstance.messagesObservers[All_New_Messages_Observation_ElementId]
                        {
                            DataSource.sharedInstance.getLastMessagesForDashboardCount(MaximumLastMessagesCount, completion: { (lastMessages) -> () in
                                
                                if let lastMessagesReal = lastMessages
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        observerForHomeScreen.newMessagesAdded(lastMessagesReal)
                                    })
                                }
                            })
                        }
                        
                    }
                }
                
                if let completionBlock = completion
                {
                    completionBlock(success: true, error: nil)
                }
            }
        }
    }
    //MARK: Element
    /**
        submitNewElementToServer completion : Sends POST request to server to create new Element.
    
        - Returns: new created Element or NSError if fails
    */
    func submitNewElementToServer(newElement:Element, completion closure:(newElementId:Int?, error:NSError?) ->())
    {
        DataSource.sharedInstance.serverRequester.submitNewElement(newElement, completion: { (result, error) -> () in
            if let successElement = result as? Element
            {
                DataSource.sharedInstance.addNewElements([successElement], completion: { () -> () in
                    closure(newElementId: successElement.elementId?.integerValue, error: nil)
                })
                
            }
            else
            {
                closure(newElementId: nil, error: error)
            }
            
        })
    }
    
    func addNewElements(elements:[Element], completion:voidClosure?)
    {
        DataSource.sharedInstance.elements += elements
        var elementIDs = Set<NSNumber>()
        for anElement in elements
        {
            if let id = anElement.elementId
            {
                elementIDs.insert(id)
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil, userInfo: ["IDs" : elementIDs])
        
        if (completion != nil)
        {
            completion!()
        }
    }
    
    func getElementById(elementId:Int) -> Element?
    {
        let foundElements = DataSource.sharedInstance.elements.filter
        { lvElement -> Bool in
            if let existId = lvElement.elementId
            {
                return existId == elementId
            }
            return false
        }
        
        if !foundElements.isEmpty
        {
            return foundElements.last
        }
        return  nil
    }
    
    func getRootElementTreeForElement(targetElement:Element) -> [Element]?
    {
        let root = targetElement.rootElementId.integerValue
        if root > 0
        {
            var elements = [Element]()
            
            var tempElement = targetElement
            
            while tempElement.rootElementId.integerValue > 0
            {
                if let foundRootElement = DataSource.sharedInstance.getElementById(tempElement.rootElementId.integerValue)
                {
                    elements.append(foundRootElement)
                    tempElement = foundRootElement
                }
                else
                {
                    break
                }
            }
            return elements
        }
        else
        {
            return nil
        }
    }
    
    func getSubordinateElementsForElement(elementId:Int?, shouldIncludeArchived:Bool) -> [Element]
    {
       
        var elementsToReturn:[Element] = [Element]()
        if elementId == nil
        {
            return elementsToReturn
        }
        
        for lvElement in DataSource.sharedInstance.elements
        {
            if lvElement.rootElementId.integerValue == elementId!
            {
                elementsToReturn.append(lvElement)
            }
        }
        
        ObjectsConverter.sortElementsByDate(&elementsToReturn)
        if !shouldIncludeArchived
        {
            var newElements = ObjectsConverter.filterArchiveElements(false, elements: elementsToReturn)
            return newElements
        }
        return elementsToReturn
    }
    
    func getSubordinateElementsTreeForElement(targetRootElement:Element) -> [Element]?
    {
        var treeToReturn = [Element]()
        
        let currentSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(targetRootElement.elementId?.integerValue, shouldIncludeArchived:false)
        if currentSubordinates.isEmpty
        {
            return nil
        }
        
        let countSubordinates = currentSubordinates.count
        var subordinatesSet = Set<Element>()
        
        for lvElement in currentSubordinates
        {
            let subordinatesFirst =  DataSource.sharedInstance.getSubordinateElementsForElement(lvElement.elementId?.integerValue, shouldIncludeArchived:false)
            if !subordinatesFirst.isEmpty
            {
                let subSetFirst = Set(subordinatesFirst)
                subordinatesSet.exclusiveOrInPlace(subSetFirst)
            }
        }
    
        return Array(subordinatesSet)
       
    }
    
    func getDashboardElements( completion:([Int:[Element]]?)->() )
    {
        //NSLog("\r _________ Started gathering elements for Dashboard.....")
        let dispatchQueue = dispatch_queue_create("elements.sorting", DISPATCH_QUEUE_SERIAL)
        dispatch_async(dispatchQueue,
        {
            if DataSource.sharedInstance.elements.isEmpty
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    //NSLog("\r _________ Finished gathering elements for Dashboard..... Returning empty.")
                    completion(nil)
                })
                return
            }
            var preFavouriteElements = DataSource.sharedInstance.elements.filter({ (checkedElement) -> Bool in
                return checkedElement.isFavourite.boolValue
            })
            
            var favouriteElements =  ObjectsConverter.filterArchiveElements(false, elements: preFavouriteElements)
            
            ObjectsConverter.sortElementsByDate(&favouriteElements)
        
            
            
        
            // ----
            var otherElementsSet = Set<Element>()//[Element]()
            
            let filteredMainElements = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
                let rootId = element.rootElementId
                return (rootId.integerValue == 0)
                
            })
            
            for lvElement in filteredMainElements
            {
                otherElementsSet.insert(lvElement)
            }
            
            var preOtherElementsArray = Array(otherElementsSet)
            var otherElementsArray = ObjectsConverter.filterArchiveElements(false, elements: preOtherElementsArray)
            ObjectsConverter.sortElementsByDate(&otherElementsArray)
            
            // get all signals
            var filteredSignals = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
                
                let signalValue = element.isSignal.boolValue
                //let  rootId = element.rootElementId.integerValue
                
                return (signalValue )
            })
            
            var signalElementsSet = Set(filteredSignals)
            var preSignalElementsArray = Array(signalElementsSet)
            
            //filter out archiveElements
            
            
            var signalElementsArray = ObjectsConverter.filterArchiveElements(false, elements: preSignalElementsArray)
            for aSignal in signalElementsArray
            {
                assert(!aSignal.isArchived(), "\n Tried to insert archived element to main dashboard.")
            }
            
            ObjectsConverter.sortElementsByDate(&signalElementsArray)
            
            dispatch_async(dispatch_get_main_queue(),
            {
                _ in
                let toReturn : [Int:[Element]] = [1:signalElementsArray, 2:favouriteElements, 3:otherElementsArray]
                
                // NSLog("\r _________ Finished gathering elements for Dashboard.....")
                completion(toReturn)
            })
        })
    }
    
    func getAllElementsSortedByActivity( completion:((elements:[Element]?) -> ())? )
    {
        NSLog("_________ Started gathering elements for RecentActivityTableVC.....")
        
        let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_async(bgQueue, { () -> Void in
            
            var elementsToSort = DataSource.sharedInstance.elements
            
            ObjectsConverter.sortElementsByDate(&elementsToSort)
            NSLog("_________ Finished gathering elements for RecentActivityTableVC.....")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?(elements: elementsToSort)
            })
        })
    }

    
    #if SHEVCHENKO
    #else
    func loadExistingDashboardElementsFromLocalDatabaseCompletion( completion:((elements:[String:[DBElement]]?, error:NSError?)->()) )
    {
        DataSource.sharedInstance.databaseHandler?.queryDashboardElementsCompletion({ (elementsContainerDict) -> Void in
            
            if let dbElements = elementsContainerDict as? [String:[DBElement]]
            {
                completion(elements: dbElements, error: nil)
                return
            }
//            else
//            {
//                if let error = elementsRequestEror
//                {
//                    completion(elements: nil, error: error)
//                }
//                else
//                {
//                    let unknownError = NSError(domain: "Origami.UnknownError", code: 100509, userInfo: [NSLocalizedDescriptionKey:"Unknown error while querrying Home screen elements"])
//                    completion(elements: nil, error: unknownError);
//                    
//                }
//            }
        })
    }
    #endif
    func loadAllElementsInfo(completion:(success:Bool, failure:NSError?) ->())
    {
        DataSource.sharedInstance.serverRequester.loadAllElements {(result, error) -> () in
            
            if let allElements = result as? [Element]
            {
                if allElements .isEmpty
                {
                    completion(success: false, failure: nil)
                    return
                }
                
                let backgroundQueue = dispatch_queue_create("elements-handler-queue", DISPATCH_QUEUE_SERIAL)
                dispatch_async(backgroundQueue, { () -> Void in
                    DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
                    
                    
                    var elementsSet = Set(allElements)
                    var elementsArrayFromSet = Array(elementsSet)
                    
                    ObjectsConverter.sortElementsByDate(&elementsArrayFromSet)
                    
                    DataSource.sharedInstance.elements += elementsArrayFromSet
                    println("Count Elements = \(elementsArrayFromSet.count)")
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(success: true, failure: nil)
                    })
                })
                
                
                
                
                //test stuff
//                DataSource.sharedInstance.databaseHandler?.insertElements(Set(DataSource.sharedInstance.elements), completion: { (finishInfo, error) -> Void in
//                    if let successInfo = finishInfo
//                    {
//                        println("\(successInfo)")
//                    }
//                    
//                    if let insertError = error
//                    {
//                        println("Error while saving ELEMENTS to local database;")
//                    }
//                })
                
                //start loading ather info in background
                let bgOperationQueue = NSOperationQueue()
                bgOperationQueue.maxConcurrentOperationCount = 3
                
                
                for anElement in DataSource.sharedInstance.elements
                {
                    bgOperationQueue.addOperationWithBlock({ () -> Void in
                        // load connected userIDs for element
                       // println(" -> Loading Pass Whom IDs for element. >- \n")
                        DataSource.sharedInstance.loadPassWhomIdsForElement(anElement, comlpetion:
                            { (finished) -> () in
                                //println(" loadPassWhomIdsForElement completion block.")
                        })
                    })
                    
                    
                    bgOperationQueue.addOperationWithBlock({ () -> Void in
                        // load attach files info
                        if !anElement.attachIDs.isEmpty
                        {
                              //println(" -> not IsEmpty: Loading attach info for element. >- \n")
                            DataSource.sharedInstance.loadAttachesInfoForElement(anElement, completion: { (attaches) -> () in
                                if let existAttaches = attaches
                                {
                                    println("\n --> not empty IDS - > DataSource has loaded \"\(existAttaches.count)\" attaches for elementID: \(anElement.elementId)")
                                }
                            })
                        }
                        else if anElement.hasAttaches.boolValue
                        {
                            //println(" -> Has Attaches: Loading attach info for element. >- \n")
                            DataSource.sharedInstance.loadAttachesInfoForElement(anElement, completion: { (attaches) -> () in
                                if let existAttaches = attaches
                                {
                                    println("\n --> Has Attaches: - > DataSource has loaded \"\(existAttaches.count)\" attaches for elementID: \(anElement.elementId)")
                                }
                            })
                        }
                    })
                }
            }
            else
            {
                completion(success: false, failure: error)
            }
        }
    }
    func countExistingElementsLocked() -> Int
    {
        var elementsCount:Int = 0
        
        let aLock =  NSLock()
        aLock.lock()
            elementsCount = DataSource.sharedInstance.elements.count
        aLock.unlock()
        
        return elementsCount
        
    }
    func getAllElementsLocked() -> [Element]?
    {
        let aLock = NSLock()
        var elements = [Element]()
        aLock.lock()
            elements += DataSource.sharedInstance.elements
        aLock.unlock()
        
        if elements.isEmpty
        {
            return nil
        }
        return elements
    }
    
    func addElementsLocked(newElements:[Element])
    {
        let aLock = NSLock()
        aLock.lock()
        DataSource.sharedInstance.elements += newElements
        
        aLock.unlock()
        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
        NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil, userInfo: nil)
        
    }
    
    func deleteElementsLocked(elementsToDelete:[Int])
    {
        let aLock = NSLock()
        aLock.lock()
        for anElementId in elementsToDelete
        {
            DataSource.sharedInstance.deleteElementFromLocalStorage(anElementId, shouldNotify:false)
        }
        aLock.unlock()
        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
        var deletedNotif = NSNotification(name: kElementWasDeletedNotification, object: nil, userInfo:["elementIdInts":elementsToDelete])
  
        NSNotificationCenter.defaultCenter().postNotification(deletedNotif)
    }
    
    func replaceAllElementsToNew(newElements:[Element])
    {
        let aLock = NSLock()
        aLock.name = "Elements replacer lock"
        aLock.lock()
        DataSource.sharedInstance.elements.removeAll(keepCapacity: true)
        DataSource.sharedInstance.elements += newElements
        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
        aLock.unlock()
        
        NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil)
    }
//    func getRootElementTitlesFor(element:Element) -> [String]
//    {
//        var lvTitles = [String]()
//        var currentElement = element
//        while getRootElementTitle(currentElement) != nil
//        {
//            let lvStringTitle = getRootElementTitle(currentElement)
//            lvTitles.append(lvStringTitle!)
//            if let rootElementId = currentElement.rootElementId, let rootElement = getElementById(rootElementId)
//            {
//                currentElement = rootElement
//            }
//        }
//        
//        return lvTitles
//    }
//    private func getRootElementTitle(element:Element) -> String?
//    {
//        if element.rootElementId != nil, let lvRootElement = getElementById(element.rootElementId!), let lvTitle = lvRootElement.title as? String
//        {
//            return lvTitle
//        }
//        return nil
//    }
    
    func editElement(element:Element, completionClosure completion:(edited:Bool) -> () )
    {
       DataSource.sharedInstance.serverRequester.editElement(element, completion: { (success, error) -> () in
       NSOperationQueue().addOperationWithBlock({ () -> Void in
        
            if success
            {
                if let elementId = element.elementId?.integerValue
                {
                    if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                    {
                        existingElement.title = element.title
                        existingElement.details = element.details
                        existingElement.isFavourite = element.isFavourite
                        existingElement.isSignal = element.isSignal
                        existingElement.typeId = element.typeId
                        let currentDate = NSDate()
                        if let dateForServer = currentDate.dateForServer()
                        {
                            existingElement.changeDate = dateForServer
                        }
                        existingElement.archiveDate = element.archiveDate
                        
                        if let rootTree = DataSource.sharedInstance.getRootElementTreeForElement(existingElement)
                        {
                            for aParent in rootTree
                            {
                                aParent.changeDate = existingElement.changeDate
                            }
                        }
                        
                        let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(elementId, shouldIncludeArchived:false)
                        for aSubElement in subordinates
                        {
                            aSubElement.archiveDate = element.archiveDate
                        }
                        
                        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                    }
                }
            }
        
            NSOperationQueue.mainQueue().addOperationWithBlock()
                { () -> Void in
                    if success
                    {
                        //println("\r - Edit successfull")
                        
                        completion(edited: true)
                    }
                    else
                    {
                        println("! Warning ! Could not edit element.")
                        if let errorDict = error?.userInfo
                        {
                            println("Reason : \(errorDict[NSLocalizedDescriptionKey])")
                        }
                        completion(edited: false)
                    }
            }
           })
       })
       
    }
    
    func updateElement(element:Element, isFavourite favourite:Bool, completion completionClosure:(edited:Bool)->() )
    {
        let elementId = element.elementId!.integerValue
        
        serverRequester.setElementWithId(element.elementId!, favourite: favourite) { (success, error) -> () in
            
            if success{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                    {
                        let date = NSDate()
                        if let currentStringDate = date.dateForServer()
                        {
                            existingElement.changeDate = currentStringDate
                            DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                        }
                    }
                })
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionClosure(edited: true)
                })
            }
            else
            {
                completionClosure(edited: false)
                println("Error did not update FAVOURITE for element.")
            }
        }
    }
    
    
    func loadPassWhomIdsForElement(element:Element, comlpetion completionClosure:(finished:Bool)->() ) {
        
        let elementIdInt = element.elementId!.integerValue
        DataSource.sharedInstance.serverRequester.loadPassWhomIdsForElementID(elementIdInt, completion: { (passWhomIds, error) -> () in
            if let recievedIDs = passWhomIds
            {
                //println(" -->DataSource -> Recieved passWhomIds: \(recievedIDs)")
                if let elementFromDataSource = DataSource.sharedInstance.getElementById(elementIdInt)
                {
                    var ordered = Array(recievedIDs)
                    
                    ordered.sort {$0.integerValue < $1.integerValue}
                    
                    elementFromDataSource.passWhomIDs = ordered
                }
                //element.passWhomIDs = recievedIDs
                completionClosure(finished: true)
            }
            else
            {
                println("did not load passWhomIDs for element: \(elementIdInt)")
                completionClosure(finished: false)
            }
        })
    }
    
    func deleteElementFromServer(elementId:Int, completion closure:(deleted:Bool, error:NSError?) ->())
    {
        DataSource.sharedInstance.serverRequester.deleteElement(elementId, completion: closure)
    }
    
    func deleteElementFromLocalStorage(elementId:Int, shouldNotify:Bool)
    {
        var index = -1
        var counter = 0
        for element in DataSource.sharedInstance.elements
        {
            if element.elementId! == elementId
            {
                index = counter
                break
            }
            counter += 1
        }
        if index > -1
        {
            //clean also subordinateElements and attached files from disc if present;
            if let target = DataSource.sharedInstance.getElementById(elementId)
            {
                var set = Set(DataSource.sharedInstance.elements)
                set.remove(target)
                DataSource.sharedInstance.elements = Array(set)
                
                if let allSubordinatesTree = DataSource.sharedInstance.getSubordinateElementsTreeForElement(target)
                {
                    //clean attaches if present
                    var bgQueue = NSOperationQueue()
                    bgQueue.maxConcurrentOperationCount = 2
                    
                    
                    
                    for lvSubordinateElement in allSubordinatesTree
                    {
                        bgQueue.addOperationWithBlock({ () -> Void in
                            DataSource.sharedInstance.cleanAttachesForElement(lvSubordinateElement.elementId!.integerValue)
                        })
                    }
                    
                    //clean elements themselves
                    var allElements = Set(DataSource.sharedInstance.elements)
                    var toDelete = Set(allSubordinatesTree)
                    toDelete.insert(target)
                    
                    let afterDeletionSet = allElements.subtract(toDelete)
                    var cleanedElements = Array(afterDeletionSet)
                  
                    DataSource.sharedInstance.elements = cleanedElements
                }
                
                
                // iterate through all elements and if element has Root element id, but the root element id is not found - delete it
                var setToDelete = Set<Element>()
                for lvElement in DataSource.sharedInstance.elements
                {
                    if lvElement.rootElementId.integerValue > 0
                    {
                        if DataSource.sharedInstance.getElementById(lvElement.rootElementId.integerValue) == nil
                        {
                            setToDelete.insert(lvElement)
                        }
                    }
                }
                
                for lvElement in setToDelete
                {
                    DataSource.sharedInstance.cleanAttachesForElement(lvElement.elementId!.integerValue)
                }
                
                var filterAgain = Set(DataSource.sharedInstance.elements)
                let newSet = filterAgain.subtract(setToDelete)
                
                var remainingElements = Array(newSet)
                
                ObjectsConverter.sortElementsByDate(&remainingElements)
                
                DataSource.sharedInstance.elements = remainingElements
                //Recheck after deleting
                let reCheckSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(elementId, shouldIncludeArchived:false)
                if !reCheckSubordinates.isEmpty
                {
                    // assert(false, "Check properly deleted subordinates....")
                    println("Did not delete subordinates for current element Id: \(elementId)")
                }
            }
        }
        
        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
        println("   ->Finished deleting element from local storage.")
        if shouldNotify
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(kElementWasDeletedNotification, object: nil, userInfo: ["elementId" : NSNumber(integer:elementId)])
            })
        }
        
   
    }
    
    func cleanAttachesForElement(elementId:Int)
    {
//        if let currentElement = DataSource.sharedInstance.getElementById(NSNumber(integer:elementId))
//        {
            if  let attaches = DataSource.sharedInstance.getAttachesForElementById(elementId)
            {
                for lvAttach in attaches
                {
                    DataSource.sharedInstance.eraseFileFromDiscForAttach(lvAttach) //delete files from disk
                }
            }
            DataSource.sharedInstance.attaches[NSNumber(integer: elementId)] = nil // delete attachFile from memory
//        }
    }
    
    //MARK: Attaches
    func getAttachesForElementById(elementId:NSNumber?) -> [AttachFile]?
    {
        if elementId == nil
        {
            return nil
        }
        
        var foundAttaches:[AttachFile]?
        
        if let attaches = DataSource.sharedInstance.attaches[elementId!]
        {
            if attaches.isEmpty
            {
                return nil
            }
            foundAttaches = attaches
            return foundAttaches
        }
        
        return nil
    }
    
    func loadAttachesInfoForElement(element:Element, completion:attachesArrayClosure)
    {
        if let localElementId = element.elementId
        {            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
          
            serverRequester.loadAttachesListForElementId(localElementId,
            completion:
            { (result, error) -> ()
                in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let attachesArray = result as? [AttachFile]
                {
                    DataSource.sharedInstance.attaches[localElementId] = attachesArray
                    completion(DataSource.sharedInstance.attaches[localElementId]!)
                }
                else
                {
                    completion(nil)
                }
            })
        }
        else
        {
            completion(nil)
        }
    }
    
    func refreshAttachesForElement(element:Element?, completion:attachesArrayClosure?)
    {
        if let localElementId = element?.elementId
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            serverRequester.loadAttachesListForElementId(localElementId,
                completion:
                { (result, error) -> ()
                    in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let attachesArray = result as? [AttachFile]
                    {
                        DataSource.sharedInstance.attaches[localElementId] = attachesArray
                        completion?(DataSource.sharedInstance.attaches[localElementId]!)
                    }
                    else
                    {
                        completion?(nil)
                    }
            })
        }
        else
        {
            completion?(nil)
        }
    }
    
    func attachFile(file:MediaFile, toElementId elementId:NSNumber?, completion completionClosure:(success:Bool, error: NSError?)->() ) {
        
        if elementId == nil || (elementId!.integerValue <= 0)
        {
            let errorId = NSError(domain: "Element id error", code: -65, userInfo: [NSLocalizedDescriptionKey:"Colud not start attaching file. Reason: wrong element id format."])
            completionClosure(success: false, error: nil)
            return
        }
        
        serverRequester.attachFile(file, toElement: elementId!) { (successAttached, attachId ,errorAttached) -> () in
            
            if successAttached {
                
                /*
                
                NSNumber *attachID = [successResponse objectForKey:@"AttachFileToElementResult"];
                AttachFile *newAttach = [[AttachFile alloc] init];
                newAttach.createDate = [[NSDate date] dateForServer];
                newAttach.creatorID = weakSelf.writerUser.userID;
                newAttach.fileName = fileName;
                newAttach.fileSize = imageSize;
                newAttach.elementID = weakSelf.chatElementId;
                newAttach.attachID = attachID;
                
                */
                
                let lvFileHandle = FileHandler()
                lvFileHandle.saveFileToDisc(file.data, fileName: file.name, completion: { (filePath, saveError) -> Void in
                    if filePath != nil
                    {
                        completionClosure(success: true, error: nil)
                    }
                    else
                    {
                        completionClosure(success: true, error: NSError(domain: "FileSavingError", code: -61, userInfo: [NSLocalizedDescriptionKey:"Could not save file to disc."]) )
                    }
                })
            }
            else
            {
                completionClosure(success: false, error: errorAttached)
            }
        }
    }
    
    func deleteAttachedFileNamed(fileName:String, fromElement elementId:NSNumber, completion completionClosure:(success:Bool, error:NSError?)->() ) {
        
        //response key "RemoveFileFromElementResult"
        serverRequester.unAttachFile(fileName, fromElement: elementId) { (success, fromServerError) -> () in
            let backgroundQueue = NSOperationQueue()
            backgroundQueue.maxConcurrentOperationCount = 2
            if success
            {
                backgroundQueue.addOperationWithBlock({ () -> Void in
                    let fileHandler = FileHandler()
                    fileHandler.eraseFileNamed(fileName, completion: { (erased, eraseError) -> Void in
                        //return to main queue to return from function
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            if erased
                            {
                                //we don`t care - if file was erased or simply not found - anyway file does not exist at Documents folder
                                completionClosure(success:erased, error:nil)
                            }
                            else
                            {
                                println("Could not erase file from disc: \n Error: \n\(fromServerError)")
                                completionClosure(success: false, error: eraseError)
                            }
                        })
                    })
                })
            }
            else
            {
                println("Could not deAttach file on server: \n Error: \n\(fromServerError)")
                completionClosure(success: success, error: fromServerError)
            }
        }
    }
    
    func eraseFileFromDiscForAttach(attach:AttachFile)
    {
        let fileHandler = FileHandler()
        fileHandler.eraseFileNamed(attach.fileName, completion: nil)
    }
    
    func getSnapshotsArrayForAttaches(attaches:[AttachFile]) -> [[AttachFile:NSData]]?
    {
        if attaches.isEmpty
        {
            return nil
        }
        
        var toReturnArray = [[AttachFile:NSData]]()
        for anAttach in attaches
        {
            if let existingSnapshot = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(anAttach)
            {
                toReturnArray.append(existingSnapshot)
            }
        }
        
        if toReturnArray.isEmpty
        {
            println(" empty snapshots array. returning nil.")
            return nil
        }
        
        println("  -> returning \(toReturnArray.count) snapshotDatas for \(attaches.count) AttacFiles\n")
        return toReturnArray
    }
    
    func getSnapshotImageDataForAttachFile(file:AttachFile) -> [AttachFile:NSData]?
    {
        if let cachedData = DataSource.sharedInstance.getAttachFileDataFromCache(file)
        {
        
            println(" ->returning attach snapshot from cache..")
            return [file:cachedData]
        }
        else
        {
            if let fileSystemData = DataSource.sharedInstance.getAttachFileDataFromFileSystem(file)
            {
                println(" ->returning attach snapshot from disc..")
                return [file:fileSystemData]
            }
            println(" ->returning nil attach snapshot")
            return nil
        }
    }
    
    private func getAttachFileDataFromFileSystem(attachFile:AttachFile) -> NSData?
    {
        let lvFileHandler = FileHandler()
        //let waiterGroup = dispatch_group_create()
        //dispatch_group_enter(waiterGroup)
        var outerFileData:NSData? = nil
        //let bgQueue:dispatch_queue_t = dispatch_queue_create("Origami.DataReading.Queue", DISPATCH_QUEUE_SERIAL)
        //dispatch_sync(bgQueue, { () -> Void in
            
            lvFileHandler.loadFileNamed(attachFile.fileName!, completion: {
                (fileData, readingError) -> Void in
                if fileData != nil
                {
                    //reduce image size, and insert into cache already reduced image data
                    
                    
                    if let fullImage = UIImage(data: fileData!)
                    {
                        var scaledToSizeImage = DataSource.sharedInstance.reduceImageSize( fullImage, toSize: CGSizeMake(180, 140))
                        
                        if let imagePreviewData = UIImageJPEGRepresentation(scaledToSizeImage, 1.0)
                        {
                            //println("\n--- Inserting imagePreview data \(imagePreviewData.length) bytes to cache...")
                            DataSource.sharedInstance.dataCache.setObject(imagePreviewData, forKey: attachFile.fileName!)
                            outerFileData = imagePreviewData
                        }
                    }
                    else
                    {
                        assert(false, "Check image preview data.")
                    }
                }
                else
                {
                    println(" ->FileReadingError: \n\(readingError.localizedDescription)")
                }
                //dispatch_group_leave(waiterGroup)
            })
        //})
        
        
        //dispatch_group_wait(waiterGroup, DISPATCH_TIME_FOREVER)
        
        return outerFileData
    }
    
    private func getAttachFileDataFromCache(file:AttachFile) -> NSData?
    {
        return DataSource.sharedInstance.dataCache.objectForKey(file.fileName!) as? NSData
    }
    
    private func reduceImageSize(image:UIImage, toSize size:CGSize) -> UIImage
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
        let scaledToSizeImage = image.scaleToSizeKeepAspect(reducedImageSize)
        //NSLog(" -> Image Size After reducing: \(scaledToSizeImage.size)")
        return scaledToSizeImage
    }
    
    
    func loadAttachFileDataForAttaches(attaches:[AttachFile], completion completionClosure:(()->())? = nil )
    {
        if attaches.isEmpty
        {
            completionClosure?()
            return
        }
        
     
        let recievedAttachesCount = attaches.count
        println("\n -> Starting to filter pending attaches..")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
     
        var localAttaches = [AttachFile]()
        
        for lvAttachFileLoading in attaches
        {
            if let pending = DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttachFileLoading.attachID!]
            {
                if pending
                {
                    println("is pending")
                    continue
                }
                else
                {
                    println("pending is waiting to be cleared")
                    continue
                }
            }
            else
            {
                DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttachFileLoading.attachID!] = true
                localAttaches.append(lvAttachFileLoading)
            }
        }
        
        if !localAttaches.isEmpty
        {
            let dispatchGroup = dispatch_group_create()
            let fileManager = FileHandler()
            
            var localAttachesCount = localAttaches.count
            
            println("\n -> Processing \(localAttachesCount) out of \(recievedAttachesCount) atatches...")
            
            let lvQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
            dispatch_apply(localAttachesCount, lvQueue) { (currentIteration) -> Void in
                
                dispatch_group_enter(dispatchGroup)
                let lvAttach = localAttaches[currentIteration]
                
                if let attachData = fileManager.synchronouslyLoadFileNamed(lvAttach.fileName)
                {
                    println("\n -> DataSource Will not load existing attach file several times. Attach File: \(lvAttach.fileName!)\n")
                    
                    if let name = lvAttach.fileName
                    {
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1))
                        dispatch_after(timeout, lvQueue, { () -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName(kAttachDataDidFinishLoadingNotification, object: nil, userInfo: ["fileName" : name])
                        })
                    }
                    DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttach.attachID!] = false
                    
                    dispatch_group_leave(dispatchGroup)
                }
                else
                {
                    let attachFileName = lvAttach.fileName
                    println("\n -> DataSource Will  load  attach file . Attach File: \(lvAttach.fileName!)\n")
                    DataSource.sharedInstance.serverRequester.loadDataForAttach(lvAttach.attachID!, completion: { (attachFileData, error) -> () in
                        if attachFileData != nil
                        {
                            fileManager.saveFileToDisc(attachFileData!, fileName: lvAttach.fileName! , completion: { (path, saveError) -> Void in
                                if path != nil
                                {
                                    //println("\n -> Saved a file")
                                    if let name = attachFileName
                                    {
                                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1))
                                        dispatch_after(timeout, lvQueue, { () -> Void in
                                            NSNotificationCenter.defaultCenter().postNotificationName(kAttachDataDidFinishLoadingNotification, object: nil, userInfo: ["fileName" : name])
                                        })
                                    }
                                }
                                
                                if saveError != nil
                                {
                                    println("\n ->Failed to save data to disc: \n \(saveError?.localizedDescription)")
                                }
                                DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttach.attachID!] = false
                                dispatch_group_leave(dispatchGroup)
                            })
                        }
                        else
                        {
                            println(" \n ->Failed to load attach file data: \n \(error?.localizedDescription)")
                            DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttach.attachID!] = false
                            dispatch_group_leave(dispatchGroup)
                        }
                    })
                }
            }
            
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), { () -> Void in
                print("\n ....finished loading all \(recievedAttachesCount) attachment file datas. >>>>>\n")
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let completionBlock = completionClosure
                {
                    completionBlock()
                }
                
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
                dispatch_after(timeout, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
                    
                    for anAttach in localAttaches
                    {
                        if let number = anAttach.attachID
                        {
                            DataSource.sharedInstance.pendingAttachFileDataDownloads[number] = nil
                            println("\n Cleared pending \(number.integerValue)\n")
                        }
                    }
                })
                
            })

        }
        else
        {
            println("\n -> Will not process queried attach files - all are currently pending..")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let completionBlock = completionClosure
            {
                completionBlock()
            }
        }
        
    }
    
    
    
    //MARK: Contact
    func addNewContacts(contacts:[Contact], completion:voidClosure?)
    {        
        DataSource.sharedInstance.contacts += contacts
        if completion != nil
        {
            completion!()
        }
    }
    
    func getMyContacts() -> [Contact]?
    {
        if DataSource.sharedInstance.contacts.isEmpty
        {
            DataSource.sharedInstance.serverRequester.downloadMyContacts(completion: { (contacts, error) -> () in
                if error != nil
                {
                    println("Contacts loading failed: \n \(error!.localizedDescription)")
                }
                else if let aContacts = contacts
                {
                    if aContacts.isEmpty
                    {
                        println("WARNING!: Loaded empty contacts!!!!!")
                    }
                    else
                    {
                        println(" -> Loaded contacts: \(aContacts.count)")
                        DataSource.sharedInstance.contacts = aContacts
                        
                        //println(" -> Started saving and resizing MY contact avatars in background")
                        
                        //memory footprint
                        var screenScale = UIScreen.mainScreen().scale
                        if screenScale > 2.0
                        {
                            screenScale = 2.0
                        }
                        let sizeOfAvatar = CGSizeMake(50 * screenScale , 50 * screenScale)
                        
                        let aFiler = FileHandler()
                        
                        let group = dispatch_group_create()
                        for aContact in aContacts
                        {
                            dispatch_group_enter(group)

                            
                            if let avatarBigData = aContact.photo, userName = aContact.userName as? String
                            {
                                if let image = UIImage(data: avatarBigData)
                                {
                                    let smallImage = DataSource.sharedInstance.reduceImageSize(image, toSize: sizeOfAvatar)
                                    let smallImageData = UIImageJPEGRepresentation(smallImage, 1.0)
                                    println(" \n reduced avatar data size: \(smallImageData.length)  bytes")
                                    DataSource.sharedInstance.addAvatarData(smallImageData, forContactUserName: userName)
                                    if let anId = aContact.contactId
                                    {
                                        NSNotificationCenter.defaultCenter().postNotificationName("FinishedProcessingContactAvatars", object: nil, userInfo:["avatarOwnerId":anId])
                                    }
                                    
                                }
                                //println(" \n -> Saving Avatar to disc")
                                aFiler.saveAvatar(avatarBigData, forLoginName: userName, completion: { (errorSaving) -> Void in
                                    
                                })
                            }
                            
                        }
                        dispatch_group_notify(group, dispatch_queue_create("bg-queue", DISPATCH_QUEUE_CONCURRENT), { () -> Void in
                            println(" finishd loading avatars for contacts")
                            
                        })
                    }
                }
            })
            return nil
        }
        
        println("returning existing contacts")
        
        return DataSource.sharedInstance.contacts
    }
    
    func getAllContacts(completion:((contacts:[Contact]?, error:NSError?)->())?)
    {
//        let sender = NSProcessInfo.processInfo()
//        let name = sender.processName
//        let identifier = sender.processIdentifier
//        let availableMenory = sender.physicalMemory
        
        DataSource.sharedInstance.serverRequester.loadAllContacts { (contacts, error) -> () in
            if error != nil
            {
                println(" ALL Contacts loading failed: \n \(error!.localizedDescription)")
                if let completionBlock = completion
                {
                    completionBlock(contacts: nil, error: error)
                }
            }
            else
            {
                if contacts!.isEmpty
                {
                    println("WARNING!: Loaded empty contacts!!!!!")
                    if let completionBlock = completion
                    {
                        completionBlock(contacts: nil, error: error)
                    }
                }
                else
                {
                    println(" -> Loaded ALL contacts: \(contacts!.count)")
                    if let completionBlock = completion
                    {
                        completionBlock(contacts: contacts, error: nil)
                    }
                }
            }
        }
    }
    
    func getContactsByIds(contactIDs:Set<Int>) -> [Contact]?
    {
        if !DataSource.sharedInstance.contacts.isEmpty
        {
            
            let foundContacts = DataSource.sharedInstance.contacts.filter({ (contact) -> Bool in
                if let contactId = contact.contactId
                {
                    if contactIDs.contains(contactId.integerValue)
                    {
                        return true
                    }
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
    
    func getContactsForElement(elementId:Int, completion:contactsArrayClosure?)
    {
        if let completionClosure = completion
        {
            var contactsToReturn:[Contact]
            
            if let lvElement = DataSource.sharedInstance.getElementById(elementId)
            {
                if lvElement.passWhomIDs.count > 0
                {
                    contactsToReturn = [Contact]()
                    for lvContactId in lvElement.passWhomIDs
                    {
                        var lvContacts = DataSource.sharedInstance.contacts.filter {lvContact -> Bool in
                            
                            if let lvId = lvContact.contactId
                            {
                                return (lvId == lvContactId)
                            }
                            return false
                        }
                        
                        if lvContacts.count > 0
                        {
                            let lastContact = lvContacts.removeLast()
                            contactsToReturn.append(lastContact)
                        }
                    }
                    
                    if contactsToReturn.isEmpty
                    {
                        completionClosure(nil)
                        return
                    }
                    completionClosure(contactsToReturn)
                    return
                }
            }
            
            completionClosure(nil)
            return
        }
    }
    
    func addContact(contactId:Int, toElement elementId:Int, completion completionClosure:(success:Bool, error:NSError?) -> ())
    {
        DataSource.sharedInstance.serverRequester.passElement(elementId, toContact: contactId, forDeletion: false) { (requestSuccess, resuertError) -> () in
           
            if requestSuccess
            {
                if let element = DataSource.sharedInstance.getElementById(elementId)
                {
                    let passWhomIDs = element.passWhomIDs
                    if !passWhomIDs.isEmpty
                    {
                        
                    }
                    var passWhomSet = Set(passWhomIDs)
                    let preInsertCount = passWhomSet.count
                    passWhomSet.insert(contactId)
                    let postInsertCount = passWhomSet.count
                    if preInsertCount < postInsertCount
                    {
                        // successfully removed contact id from element`s pass whom ids
                        println("Added contact to chat Locally also.")
                    }
                    var newPassWhomIDs = Array(passWhomSet)
                    element.passWhomIDs = newPassWhomIDs
                }
            }
            completionClosure(success: requestSuccess, error: resuertError)
        }
    }
    
    func removeContact(contactId:Int, fromElement elementId:Int, completion completionClosure:(success:Bool, error:NSError?) -> ())
    {
        DataSource.sharedInstance.serverRequester.passElement(elementId, toContact: contactId, forDeletion: true) { (requestSuccess, resuertError) -> () in
            
            if requestSuccess
            {
                if let element = DataSource.sharedInstance.getElementById(elementId)
                {
                    let passWhomIDs = element.passWhomIDs
                    if !passWhomIDs.isEmpty
                    {
                        var passWhomSet = Set(passWhomIDs)
                        if let removedContactId = passWhomSet.remove(contactId)
                        {
                            // successfully removed contact id from element`s pass whom ids
                            println("Removed contact from chat Locally also.")
                        }
                        var newPassWhomIDs = Array(passWhomSet)
                        element.passWhomIDs = newPassWhomIDs
                    }
                }
            }
            
            completionClosure(success:requestSuccess, error: resuertError)
        }
    }
    
    func addSeveralContacts(contactIDs:Set<Int>?, toElement elementId:Int, completion completionClosure:((succeededIDs:[Int], failedIDs:[Int])->())? )
    {
        if let contactNumbers = contactIDs
        {
            if contactNumbers.isEmpty
            {
                completionClosure?(succeededIDs: [], failedIDs: [])
                return
            }
            
            let backgroundQueue = NSOperationQueue()
            backgroundQueue.addOperationWithBlock({ () -> Void in
                
                DataSource.sharedInstance.serverRequester.passElement(elementId, toSeveratContacts: contactNumbers, completion: { (succeededIDs, failedIDs) -> () in

                if !succeededIDs.isEmpty
                {
                    if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                    {
                        var alreadyExistIDsSet = Set<Int>()
                        for number in existingElement.passWhomIDs
                        {
                            alreadyExistIDsSet.insert(number.integerValue)
                        }
                        
                        let succseededIDsSet = Set(succeededIDs)
                        
                        let commonValuesSet = alreadyExistIDsSet.union(succseededIDsSet)
                        
                        var idsArray = [NSNumber]()
                        for integer in commonValuesSet
                        {
                            idsArray.append(NSNumber(integer:integer))
                        }
                        
                        existingElement.passWhomIDs = idsArray
                        
                    }
                }
                else
                {
                    if failedIDs.count > 0
                    {
                        println("failed to assign contacts to current element: Contact IDs: \(failedIDs)")
                    }
                }

                    completionClosure?(succeededIDs: succeededIDs, failedIDs: failedIDs)
                })
                
            })//end of operationQueue Block
            

        }
        else
        {
            completionClosure?(succeededIDs: [], failedIDs: [])
        }
    }
    
    func removeSeveralContacts(contactsIDsSet:Set<Int>, fromElement elementId:Int, completion completionBlock:((succeededIDs:[Int]?, failedIDs:[Int]?)->())?)
    {
        NSOperationQueue().addOperationWithBlock { () -> Void in
            DataSource.sharedInstance.serverRequester.unPassElement(elementId, fromSeveralContacts: contactsIDsSet) { (succeededIds, failedIds) -> () in
                
                if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                {
                    if !succeededIds.isEmpty
                    {
                        let succeededSet = Set(succeededIds)
                        let currentPassWhomIDs = existingElement.passWhomIDs
                        let filteredOut = currentPassWhomIDs.filter({ (contactID) -> Bool in
                            if succeededSet.contains(contactID.integerValue)
                            {
                                return false
                            }
                            return true
                        })
                        existingElement.passWhomIDs = filteredOut
                    }
                    if !failedIds.isEmpty
                    {
                        println("\n Failed to detach contacts:\(failedIds) from element \(elementId)\n")
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
        DataSource.sharedInstance.serverRequester.removeMyContact(contact.contactId!.integerValue, completion: { (success, error) -> () in
            if success
            {
                var currentContacts = Set(DataSource.sharedInstance.contacts)
                let countBefore = currentContacts.count
                currentContacts.remove(contact)
                let countAfter = currentContacts.count
                if countAfter == countBefore
                {
                    println("\n Warning!! DataSource did NOT REMOVE contact from mycontacts\n")
                }
                
                var sorted = Array(currentContacts).sorted({ (contact1, contact2) -> Bool in
                    if let firstName1 = contact1.firstName as? String, firstName2 = contact2.firstName as? String
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
        DataSource.sharedInstance.serverRequester.addToMyContacts(contact.contactId!.integerValue, completion: { (success, error) -> () in
            if success
            {
                var currentContacts = Set(DataSource.sharedInstance.contacts)
                let countBefore = currentContacts.count
                currentContacts.insert(contact)
                let countAfter = currentContacts.count
                if countAfter == countBefore
                {
                    println("\n Warning!! DataSource did NOT ADD contact from myContacts\n")
                }
                
                var sorted = Array(currentContacts).sorted({ (contact1, contact2) -> Bool in
                    if let firstName1 = contact1.firstName as? String, firstName2 = contact2.firstName as? String
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
    
    
    //MARK: Avatars
    func addAvatarData(avatarBytes:NSData, forContactUserName userName:String) -> ResponseType
    {
        var response:ResponseType
        if let imageData = DataSource.sharedInstance.avatarsHolder[userName]
        {
            response = .Replaced
        }
        else
        {
            response = .Added
        }
        DataSource.sharedInstance.avatarsHolder[userName] = avatarBytes
        
        return response
    }
    
    func getAvatarDataForContactUserName(userName:String?) -> NSData?
    {
        if let lvName = userName
        {
            if let existingBytes = DataSource.sharedInstance.avatarsHolder[lvName]
            {
                //println(" returning avatar Data from avatarsHolder")
                return existingBytes
            }
        }
        return nil
    }
    
    func loadAvatarFromDiscForLoginName(loginName:String, completion completionBlock:((image:UIImage?, error:NSError?) ->())? )
    {
        if let block = completionBlock
        {
            let fileHandler = FileHandler()
            
            fileHandler.loadAvatarDataForLoginName(loginName, completion: { (avatarData, error) -> Void in
                if let avatarBytes = avatarData
                {
                    if let image = UIImage(data: avatarBytes)
                    {
                        let reducedImage = DataSource.sharedInstance.reduceImageSize(image, toSize: CGSizeMake(200, 200))
                        let avatarIconData = UIImageJPEGRepresentation(reducedImage, 1.0)
                        DataSource.sharedInstance.addAvatarData(avatarIconData, forContactUserName: loginName)
                     
                        block(image: image, error: nil)
                    }
                    else
                    {
                        let imageCreatingError = NSError(domain: "Origami.ImageDataConvertingError", code: 509, userInfo: [NSLocalizedDescriptionKey:"Could not convert data object to image object"])
                        block(image: nil, error: imageCreatingError)
                    }
                }
                else
                {
                    block(image: nil, error: error)
                    if error.code == 406
                    {
                        
                        DataSource.sharedInstance.startLoadingAvatarForUserName(loginName)
                    }
                    
                }
            })
        }
    }
        
    func loadAvatarForLoginName(loginName:String, completion completionBlock:((image:UIImage?) ->())? )
    {
        let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(bgQueue, { () -> Void in
            //step 1 try to get from RAM
            if let existingAvatarData = DataSource.sharedInstance.getAvatarDataForContactUserName(loginName), avatarImage = UIImage(data: existingAvatarData)
            {
                let toReturnImage = DataSource.sharedInstance.reduceImageSize(avatarImage, toSize: CGSizeMake(200, 200))
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionBlock?(image: toReturnImage)
                })
                
                println(" got avatar from RAM..")
                return
            }
            
            
            //step 2 try to get from disc
            DataSource.sharedInstance.loadAvatarFromDiscForLoginName(loginName, completion: { (image, error) -> () in
                
                if let avatarImage = image
                {
                    let toReturnImage = DataSource.sharedInstance.reduceImageSize(avatarImage, toSize: CGSizeMake(200, 200))
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionBlock?(image: toReturnImage)
                    })
                    println(" got avatar from Disc..")
                    return
                }
                //step 3 try to load from server
                
            })

        })
    }
    
    func startLoadingAvatarForUserName(name:String)
    {
        if let existValue = DataSource.sharedInstance.pendingUserAvatarsDownolads[name]
        {
            println(" - Current avatar is pending. Will not try to load in again...")
            return
        }
        
        println(" Loading Avatar: \(name)")
        DataSource.sharedInstance.pendingUserAvatarsDownolads[name] = Int(1)
        
        DataSource.sharedInstance.serverRequester.loadAvatarDataForUserName(name, completion: { (avatarData, error) -> () in
            if let avatarBytes = avatarData
            {
                if let avatar = UIImage(data: avatarBytes)
                {
                    let reducedImage = DataSource.sharedInstance.reduceImageSize(avatar, toSize: CGSizeMake(200, 200))
                    let avatarData = UIImageJPEGRepresentation(reducedImage, 1.0)
                    println(" got avatar from Server..")
                    DataSource.sharedInstance.avatarsHolder[name] = avatarData //save to RAM also
                    
                    //save to disc
                    let fileHandler = FileHandler()
                    
                    fileHandler.saveAvatar(avatarBytes, forLoginName: name, completion: { (errorSaving) -> Void in
                        if let error = errorSaving
                        {
                            println(" Did not save currently loaded avatar for user name: \(name)")
                        }
                        DataSource.sharedInstance.pendingUserAvatarsDownolads[name] = nil
                    })
                }
                else
                {
                    println(" Did not recieve avatar image bytes.")
                    DataSource.sharedInstance.pendingUserAvatarsDownolads[name] = nil
                }
             
                return
            }
            
            if let anError = error
            {
                println(" Error while downloading avatar for userName: \(name): \n \(anError.description) ")
            }
            DataSource.sharedInstance.pendingUserAvatarsDownolads[name] = nil
        })

    }
    
    func uploadAvatarForCurrentUser(data:NSData, completion completionBlock:((success:Bool, error:NSError?)->())?)
    {
        DataSource.sharedInstance.serverRequester.uploadUserAvatarBytes(data, completion: { (response, error) -> () in
            if let responseSending = response
            {
                completionBlock?(success: true, error: nil)
                
                //save to disc
                if let userName = DataSource.sharedInstance.user?.userName as? String
                {
                    let fileHandler = FileHandler()
                    fileHandler.saveAvatar(data, forLoginName: userName, completion: { (error) -> Void in
                        if let saveError = error
                        {
                            println("-> Could not update current user avatar on disc.")
                            return
                        }
                        DataSource.sharedInstance.avatarsHolder.removeValueForKey(userName) //for later re-reloading new avatar from disc
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
    
    //MARK: Languages & Countries
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
            if let countriesDictsArray = aFileHandler.getLanguagesFromDisk() as? [[String:AnyObject]]
            {
                if let langArray = ObjectsConverter.convertToLanguages(countriesDictsArray)
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


}
