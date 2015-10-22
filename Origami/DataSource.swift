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
    
    override init() {
        super.init()
        
        self.dataCache.countLimit = 50
        
//        self.databaseHandler = DatabaseHandler(completionCallBack: {[weak self] () -> Void in
//            print("Finished initializing CoreData handler in DataSource.");
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
    
    private lazy var attaches = [Int:[AttachFile]]()
    
    private lazy var avatarsHolder = [String:NSData]()
    
    private let serverRequester = ServerRequester()
 
    var shouldReloadAfterElementChanged = false
    var isRemovingObsoleteMessages = false
    var shouldLoadAllMessages = true
    
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
    
    private lazy var dataCache:NSCache = NSCache()
    lazy var pendingAttachFileDataDownloads = [Int:Bool]()
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
            print("AvatarsHolder Before cleaning: \(DataSource.sharedInstance.avatarsHolder.count)")
            DataSource.sharedInstance.avatarsHolder.removeAll(keepCapacity: false)
            print("AvatarsHolder After cleaning: \(DataSource.sharedInstance.avatarsHolder.count)")
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
                    completion?()
                })
            }

            //no need to reload avatars and attaches everytime user loggs in.  May be later or deleting by user initiated process(e.g. in app settings a button to clear documents)
//            let aFiler = FileHandler()
//            aFiler.deleteAvatars()
//            aFiler.deleteAttachedImages()
        })
    }
    
    func cleanDataCache()
    {
        print("..Datasource is clearing Data Cache...")
        
        DataSource.sharedInstance.dataCache.removeAllObjects()
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
        
        if let userName = NSUserDefaults.standardUserDefaults().objectForKey(loginNameKey) as? String, let password = NSUserDefaults.standardUserDefaults().objectForKey(passwordKey) as? String
        {
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
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        dispatch_async(queue, { () -> Void in
            if let info = FileHandler().getAllExistingAvatarsPreviews() as? [String:NSData]
            {
                for (name, data) in info
                {
                    if let previewData =  ImageFilter.getImagePreviewDataFromData(data)
                    {
                        DataSource.sharedInstance.addAvatarData(previewData, forContactUserName: name)
                    }
                }
            }
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
                    var lvMessagesHolder = [NSNumber:[Message]]()
                    for lvMessage in messagesTuple.chat
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
                    
                    
                    //handle service messages if present
                    
                    
                    //currently handling "avatar change" messages only
                    var avatarChangeMessages = messagesTuple.service.filter({ (serviceMessage) -> Bool in
                        return serviceMessage.type == .UserPhotoUpdated
                    })
                    
                    if !avatarChangeMessages.isEmpty
                    {
                        ObjectsConverter.sortMessagesByDate(&avatarChangeMessages, < )

                        //detect all users who had changed avatar
                        var usersAndMessages = [Int:NSDate]()
                        while  avatarChangeMessages.count > 0
                        {
                            let existingMessage = avatarChangeMessages.removeLast()
                            if let textBody = existingMessage.textBody, userId = Int(textBody)
                            {
                                if let _ = usersAndMessages[userId]
                                {
                                    continue
                                }
                                if let messageDate = existingMessage.dateCreated
                                {
                                    usersAndMessages[userId] = messageDate
                                }
                            }
                        }
                        
                        for (userId, date) in usersAndMessages
                        {
                            if let existingSyncDateForUserID = DataSource.sharedInstance.getLastAvatarSyncDateForContactId(userId)
                            {
                                //compare message date and stored date
                                if date.compare(existingSyncDateForUserID) != .OrderedAscending
                                {
                                    //delete current avatar for refreshing later
                                    if let contact = DataSource.sharedInstance.getContactsByIds(Set([userId]))?.first
                                    {
                                        DataSource.sharedInstance.cleanAvatarDataForUserName(contact.userName)
                                    }
                                }
                            }
                            else
                            {
                                //delete current avatar for refreshing later
                                if let contact = DataSource.sharedInstance.getContactsByIds(Set([userId]))?.first
                                {
                                    DataSource.sharedInstance.cleanAvatarDataForUserName(contact.userName)
                                }
                            }
                        }
                    }
                    
//                    DataSource.sharedInstance.messagesLoader = MessagesLoader()
//                    DataSource.sharedInstance.startRefreshingNewMessages()
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
            print(" ->handleRecievedMessagesTuple: >>> \(lvMessage.textBody!)))")
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
                DataSource.sharedInstance.addMessages([messageToInsert], forElementId: message.elementId!, completion: nil)
                //return callback to ChatVC
                completion?(nil)
                
                if let existingElement = DataSource.sharedInstance.getElementById(messageElementId)
                {
                    if let currentStringDate = NSDate().dateForServer()
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
    
    func getChatPreviewMessagesForElementId(elementId:NSNumber) -> [Message]?
    {
        let messagesQuantity:Int = 3
        guard let existingMessagesForElementId = DataSource.sharedInstance.getAllMessagesForElementId(elementId) else
        {
            return nil
        }
        
        let sorted = existingMessagesForElementId.sort { (message1, message2) -> Bool in
            return message1 < message2 //(message1.dateCreated!.compare(message2.dateCreated!) == NSComparisonResult.OrderedAscending)
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
                //print(" i = \(i)")
            }
            
            return messagesToReturn
        }
        
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
            
            ObjectsConverter.sortMessagesByDate(&sortedArray, > )
            var lastThreeItems = [Message]()
            var index = 0
            
            var elementIDsToDeleteMessageSet = Set<Int>()
            for aMessage in sortedArray
            {
                if lastThreeItems.count > 2
                {
                    break
                }
                
                index += 1
                
                if let elementIdInt = aMessage.elementId
                {
                    if let _ = DataSource.sharedInstance.getElementById(elementIdInt)
                    {
                        lastThreeItems.insert(aMessage, atIndex: 0)
                    }
                    else
                    {
                        elementIDsToDeleteMessageSet.insert(elementIdInt)
                    }
                }
                
            }
            
            if !elementIDsToDeleteMessageSet.isEmpty
            {
                print(" \n -> deleting messages for non existing elements...")
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
    
        - Returns: new created Element or NSError if fails
    */
    func submitNewElementToServer(newElement:Element, completion closure:(newElementId:Int?, error:NSError?) ->())
    {
        DataSource.sharedInstance.serverRequester.submitNewElement(newElement, completion: { (result, error) -> () in
            if let successElement = result as? Element
            {
                DataSource.sharedInstance.addNewElements([successElement], completion: { () -> () in
                    closure(newElementId: successElement.elementId, error: nil)
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
    
    /**
    returns array of elements, containing at leats one *Element* object
    */
    func getRootElementTreeForElement(targetElement:Element) -> [Element]?
    {
        var root = targetElement.rootElementId
        guard  root > 0 else{
            return nil
        }
        
        var elements = [Element]()
        
        while root > 0
        {
            if let foundRootElement = DataSource.sharedInstance.getElementById(root)
            {
                elements.append(foundRootElement)
                root = foundRootElement.rootElementId
            }
            else
            {
                break
            }
        }
        
        if elements.isEmpty
        {
            return nil
        }
        return elements
        
    }
    
    func getSubordinateElementsForElement(elementId:Int?, shouldIncludeArchived:Bool) -> [Element]?
    {
        guard let lvElementId = elementId else {
            return nil
        }
        
        var elementsToReturn = [Element]()
        for lvElement in DataSource.sharedInstance.elements
        {
            if lvElement.rootElementId == lvElementId
            {
                elementsToReturn.append(lvElement)
            }
        }
        
        if !elementsToReturn.isEmpty
        {
            ObjectsConverter.sortElementsByDate(&elementsToReturn)
            if !shouldIncludeArchived
            {
                let newElements = ObjectsConverter.filterArchiveElements(false, elements: elementsToReturn)
                return newElements
            }
        }
    
        return nil
    }
    
    func getSubordinateElementsTreeForElement(targetRootElement:Element) -> [Element]?
    {
        //var treeToReturn = [Element]()
        
        guard let currentSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(targetRootElement.elementId, shouldIncludeArchived:false) else
        {
            return nil
        }
        if currentSubordinates.isEmpty
        {
            return nil
        }
        
        //let countSubordinates = currentSubordinates.count
        var subordinatesSet = Set<Element>()
        
        for lvElement in currentSubordinates
        {
            if let subordinatesFirst =  DataSource.sharedInstance.getSubordinateElementsForElement(lvElement.elementId, shouldIncludeArchived:false)
            {
                if !subordinatesFirst.isEmpty
                {
                    let subSetFirst = Set(subordinatesFirst)
                    subordinatesSet.exclusiveOrInPlace(subSetFirst)
                }
            }
        }
    
        return Array(subordinatesSet)
       
    }
    
    func getDashboardElements( completion:([Int:[Element]]?)->() )
    {
        
        let dispatchQueue = dispatch_queue_create("elements.sorting", DISPATCH_QUEUE_SERIAL)
        dispatch_async(dispatchQueue,
        {
            if DataSource.sharedInstance.elements.isEmpty
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion(nil)
                })
                return
            }
            
            var toReturnDict = [Int:[Element]]()
            
            let preFavouriteElements = DataSource.sharedInstance.elements.filter({ (checkedElement) -> Bool in
                return checkedElement.isFavourite.boolValue
            })
            
            var favouriteElements =  ObjectsConverter.filterArchiveElements(false, elements: preFavouriteElements)
            
            if let _ = favouriteElements {
                ObjectsConverter.sortElementsByDate(&favouriteElements!)
                toReturnDict[2] = favouriteElements!
            }
            else {
                toReturnDict[2] = [Element]()
            }
        
            // ----
            var otherElementsSet = Set<Element>()//[Element]()
            
            let filteredMainElements = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
                //let rootId = element.rootElementId
                return (element.rootElementId == 0)
                
            })
            
            for lvElement in filteredMainElements
            {
                otherElementsSet.insert(lvElement)
            }
            
            let preOtherElementsArray = Array(otherElementsSet)
            var otherElementsArray = ObjectsConverter.filterArchiveElements(false, elements: preOtherElementsArray)
            if let _ = otherElementsArray {
                ObjectsConverter.sortElementsByDate(&otherElementsArray!)
                toReturnDict[3] = otherElementsArray!
            }
            else {
                toReturnDict[3] = [Element]()
            }
            
            // get all signals
            let filteredSignals = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
                
                let signalValue = element.isSignal.boolValue
                //let  rootId = element.rootElementId.integerValue
                
                return (signalValue )
            })
            
            let signalElementsSet = Set(filteredSignals)
            let preSignalElementsArray = Array(signalElementsSet)
            
            //filter out archiveElements
            
            
            var signalElementsArray = ObjectsConverter.filterArchiveElements(false, elements: preSignalElementsArray)
            if let _ = signalElementsArray{
                 ObjectsConverter.sortElementsByDate(&signalElementsArray!)
                toReturnDict[1] = signalElementsArray!
            }
            else{
                toReturnDict[1] = [Element]()
            }
            
            dispatch_async(dispatch_get_main_queue(),
            {
                _ in
                //let toReturn : [Int:[Element]] = [1:signalElementsArray, 2:favouriteElements, 3:otherElementsArray]
                completion(toReturnDict)
            })
        })
    }
    
    func getAllElementsSortedByActivity( completion:((elements:[Element]?) -> ())? )
    {
        //NSLog("_________ Started gathering elements for RecentActivityTableVC.....")
        
        let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_async(bgQueue, { () -> Void in
            
            var elementsToSort = DataSource.sharedInstance.elements
            print("-> DataSource->  getAllElementsSortedByActivity. All elements: \(elementsToSort.count)\n")
            ObjectsConverter.sortElementsByDate(&elementsToSort)
            
            print("-> DataSource->  getAllElementsSortedByActivity. All elements Sorted by date: \(elementsToSort.count)\n")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?(elements: elementsToSort)
            })
        })
    }

    
    func loadAllElementsInfo(completion:(success:Bool, failure:NSError?) ->())
    {
        DataSource.sharedInstance.loadingAllElementsInProgress = true
        
        DataSource.sharedInstance.serverRequester.loadAllElements {(result, error) -> () in
            
            
            if let allElements = result as? [Element]
            {
                
                if allElements .isEmpty
                {
                    completion(success: false, failure: nil)
                    return
                }
                
                DataSource.sharedInstance.localDatadaseHandler?.saveElementsToLocalDatabase(allElements, completion: { (didSave, error) -> () in
                    if didSave == true
                    {
                        let backgroundQueue = dispatch_queue_create("elements-handler-queue", DISPATCH_QUEUE_SERIAL)
                        dispatch_async(backgroundQueue, { () -> Void in
                            DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
                            
                            
                            let elementsSet = Set(allElements)
                            var elementsArrayFromSet = Array(elementsSet)
                            
                            ObjectsConverter.sortElementsByDate(&elementsArrayFromSet)
                            
                            DataSource.sharedInstance.elements += elementsArrayFromSet
                            print("\n -> Added Elements = \(elementsArrayFromSet.count)")
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completion(success: true, failure: nil)
                            })
                        })
                    }
                    else
                    {
                        if let insertError = error
                        {
                            print(insertError)
                        }
                    }
                })
                
                let backgroundQueue = dispatch_queue_create("elements-handler-queue", DISPATCH_QUEUE_SERIAL)
                dispatch_async(backgroundQueue, { () -> Void in
                    DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
                    
                    
                    let elementsSet = Set(allElements)
                    var elementsArrayFromSet = Array(elementsSet)
                    
                    ObjectsConverter.sortElementsByDate(&elementsArrayFromSet)
                    
                    DataSource.sharedInstance.elements += elementsArrayFromSet
                    print("\n -> Added Elements = \(elementsArrayFromSet.count)")                
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(success: true, failure: nil)
                    })
                })
                
                //start loading ather info in background
                let bgOperationQueue = NSOperationQueue()
                bgOperationQueue.maxConcurrentOperationCount = 3
                
                
                for anElement in allElements//DataSource.sharedInstance.elements
                {
                    if let anInt = anElement.elementId //?.integerValue
                    {
                        if !anElement.isArchived()
                        {
                            
                            bgOperationQueue.addOperationWithBlock({ () -> Void in
                                // load attach files info
                                if !anElement.attachIDs.isEmpty
                                {
                                    DataSource.sharedInstance.loadAttachesInfoForElement(anInt, completion: nil)
                                }
                                else if anElement.hasAttaches.boolValue
                                {
                                    DataSource.sharedInstance.loadAttachesInfoForElement(anInt, completion: nil)
                                }
                            })
                        }
                    }
                }
            }
            else
            {
                completion(success: false, failure: error)
            }
            
            DataSource.sharedInstance.loadingAllElementsInProgress = false
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
        let deletedNotif = NSNotification(name: kElementWasDeletedNotification, object: nil, userInfo:["elementIdInts":elementsToDelete])
  
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
        if let elementId = element.elementId //?.integerValue
        {
            DataSource.sharedInstance.serverRequester.editElement(element, completion: { (success, error) -> () in
                NSOperationQueue().addOperationWithBlock({ () -> Void in
                    
                    if success
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
                            
                            existingElement.responsible = element.responsible
                            existingElement.finishState = element.finishState
                            
                            if let remindDate = element.remindDate
                            {
                                existingElement.remindDate = remindDate
                            }
                            
                            if let rootTree = DataSource.sharedInstance.getRootElementTreeForElement(existingElement)
                            {
                                for aParent in rootTree
                                {
                                    aParent.changeDate = existingElement.changeDate
                                }
                            }
                            
                            existingElement.archiveDate = element.archiveDate
                            if existingElement.isArchived()
                            {
                                if let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(elementId, shouldIncludeArchived:false)
                                {
                                    for aSubElement in subordinates
                                    {
                                        aSubElement.archiveDate = element.archiveDate
                                    }
                                }
                            }
                            
                            DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                        }
                    }
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock()
                        { () -> Void in
                            if success
                            {
                                completion(edited: true)
                            }
                            else
                            {
                                print("! Warning ! Could not edit element.")
                                if let errorDict = error?.userInfo
                                {
                                    print("Reason : \(errorDict[NSLocalizedDescriptionKey])")
                                }
                                completion(edited: false)
                            }
                    }
                })
            })
        }
    }
    
    func setElementFinishDate(elementId:Int, date:String, completion:((success:Bool)->())?)
    {
        DataSource.sharedInstance.serverRequester.setElementFinished(elementId, finishDate: date) { (success) -> () in
            if success
            {
                if let existElement = DataSource.sharedInstance.getElementById(elementId)
                {
                    existElement.finishDate = date.dateFromHumanReadableDateString()
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
                if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                {
                    existingElement.finishState = newFinishState
                }
            }
            completion?(success: success)
        }
    }
    
    func updateElement(element:Element, isFavourite favourite:Bool, completion completionClosure:((edited:Bool)->())? )
    {
        guard let elementId = element.elementId else{
            completionClosure?(edited:false)
            return
        }
       
        DataSource.sharedInstance.serverRequester.setElementWithId(element.elementId!, favourite: favourite) { (success, error) -> () in
            
            if success{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                    if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                    {
                        existingElement.isFavourite = favourite
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
                //print(" -->DataSource -> Recieved passWhomIds: \(recievedIDs)")
                if let elementFromDataSource = DataSource.sharedInstance.getElementById(elementIdInt)
                {
                    var ordered = Array(recievedIDs)
                    
                    ordered.sortInPlace {$0 < $1}
                    
                    elementFromDataSource.passWhomIDs = ordered
                }
                //element.passWhomIDs = recievedIDs
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
                    let bgQueue = NSOperationQueue()
                    bgQueue.maxConcurrentOperationCount = 2
                    
                    
                    for lvSubordinateElement in allSubordinatesTree
                    {
                        bgQueue.addOperationWithBlock({ () -> Void in
                            if let _ = lvSubordinateElement.elementId {
                                DataSource.sharedInstance.cleanAttachesForElement(lvSubordinateElement.elementId!)
                            }
                        })
                    }
                    
                    //clean elements themselves
                    let allElements = Set(DataSource.sharedInstance.elements)
                    var toDelete = Set(allSubordinatesTree)
                    toDelete.insert(target)
                    
                    let afterDeletionSet = allElements.subtract(toDelete)
                    let cleanedElements = Array(afterDeletionSet)
                  
                    DataSource.sharedInstance.elements = cleanedElements
                }
                
                
                // iterate through all elements and if element has Root element id, but the root element id is not found - delete it
                var setToDelete = Set<Element>()
                for lvElement in DataSource.sharedInstance.elements
                {
                    if lvElement.rootElementId > 0
                    {
                        if DataSource.sharedInstance.getElementById(lvElement.rootElementId) == nil
                        {
                            setToDelete.insert(lvElement)
                        }
                    }
                }
                
                for lvElement in setToDelete
                {
                    if let _ = lvElement.elementId
                    {
                        DataSource.sharedInstance.cleanAttachesForElement(lvElement.elementId!)
                    }
                }
                
                let filterAgain = Set(DataSource.sharedInstance.elements)
                let newSet = filterAgain.subtract(setToDelete)
                
                var remainingElements = Array(newSet)
                
                ObjectsConverter.sortElementsByDate(&remainingElements)
                
                DataSource.sharedInstance.elements = remainingElements
                //Recheck after deleting
                if let reCheckSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(elementId, shouldIncludeArchived:false)
                {
                    if !reCheckSubordinates.isEmpty
                    {
                        // assert(false, "Check properly deleted subordinates....")
                        print("Did not delete subordinates for current element Id: \(elementId)")
                    }
                }
            }
        }
        
        DataSource.sharedInstance.shouldReloadAfterElementChanged = true
        print("   ->Finished deleting element from local storage.")
        if shouldNotify
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(kElementWasDeletedNotification, object: nil, userInfo: ["elementId" : NSNumber(integer:elementId)])
            })
        }
        
   
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
                DataSource.sharedInstance.eraseFileFromDiscForAttach(lvAttach) //delete files from disk
            }
        }
        DataSource.sharedInstance.attaches[elementId] = nil // delete attachFile from memory
    }
    
    //MARK: - Attaches
    /** 
    Queries attach info from the RAM
    - Returns: **nil** if no attaches info was found or if attaches info is empty
    */
    func getAttachesForElementById(elementId:Int?) -> [AttachFile]?
    {
        guard let lvElementId = elementId else
        {
            return nil
        }
        
        if let foundAttaches = DataSource.sharedInstance.attaches[lvElementId]
        {
            if !foundAttaches.isEmpty
            {
                return foundAttaches
            }
        }
        
        return nil
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
                DataSource.sharedInstance.attaches[localInt] = nil
                DataSource.sharedInstance.attaches[localInt] = attachesArray
                if let aReturnBlock = completion
                {
                    aReturnBlock(DataSource.sharedInstance.attaches[localInt]!)
                }
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
    func refreshAttachesForElement(elementIdInt:Int, completion:attachesArrayClosure?)
    {
    
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        DataSource.sharedInstance.serverRequester.loadAttachesListForElementId(elementIdInt,
            completion:
            { (result, error) -> ()
                in
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let attachesArray = result as? [AttachFile]
                {
                    DataSource.sharedInstance.attaches[elementIdInt] = attachesArray
                    if let existAttaches = DataSource.sharedInstance.attaches[elementIdInt]
                    {
                        completion?(existAttaches)
                        return
                    }
                    completion?(nil)
                }
                else
                {
                    completion?(nil)
                }
        })
    }
    
    func attachFile(file:MediaFile, toElementId elementId:NSNumber?, completion completionClosure:(success:Bool, error: NSError?)->() ) {
        
        if elementId == nil || (elementId!.integerValue <= 0)
        {
            let errorId = NSError(domain: "Element id error", code: -65, userInfo: [NSLocalizedDescriptionKey:"Colud not start attaching file. Reason: wrong element id format."])
            completionClosure(success: false, error: errorId)
            return
        }
        
        DataSource.sharedInstance.serverRequester.attachFile(file, toElement: elementId!) { (successAttached, attachId ,errorAttached) -> () in
            
            if successAttached {
                
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
    
    func deleteAttachedFileNamed(fileName:String, fromElement elementId:Int, completion completionClosure:((success:Bool, error:NSError?)->())? ) {
        
        //response key "RemoveFileFromElementResult"
        DataSource.sharedInstance.serverRequester.unAttachFile(fileName, fromElement: elementId) { (success, fromServerError) -> () in
            let backgroundQueue = NSOperationQueue()
            backgroundQueue.maxConcurrentOperationCount = 1
            if success
            {
                //remove attachesPreview also
                DataSource.sharedInstance.dataCache.removeObjectForKey(fileName)
                
                var attachesToEdit = [AttachFile]()
                if let attachesForElement = DataSource.sharedInstance.attaches.removeValueForKey(elementId) // DataSource.sharedInstance.attaches[NSNumber(integer:elementId)]
                {
                    for anAttach in attachesForElement
                    {
                        if let attachName = anAttach.fileName
                        {
                            if attachName != fileName
                            {
                                attachesToEdit.append(anAttach)
                            }
                        }
                    }
                }
                
                if !attachesToEdit.isEmpty
                {
                    print("\n _> Remaining attaches count: \(attachesToEdit.count)")
                    DataSource.sharedInstance.attaches[elementId] = attachesToEdit
                }
//                else
//                {
//                    DataSource.sharedInstance.attaches[elementId] = nil
//                }
                
               
                backgroundQueue.addOperationWithBlock({ () -> Void in
                    let fileHandler = FileHandler()
                    fileHandler.eraseFileNamed(fileName, completion: { (erased, eraseError) -> Void in
                        //return to main queue to return from function
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            if erased
                            {
                                //we don`t care - if file was erased or simply not found - anyway file does not exist at Documents folder
                                completionClosure?(success:erased, error:nil)
                            }
                            else
                            {
                                print("Could not erase file from disc: \n Error: \n\(fromServerError)")
                                completionClosure?(success: false, error: eraseError)
                            }
                        })
                    })
                })
            }
            else
            {
                print("\n ->Could not deAttach file on server: \n Error: \n\(fromServerError)")
                completionClosure?(success: success, error: fromServerError)
            }
        }
    }
    /**
    Function creates an instance of FileHandler and tries to erase file by file name, stored in AttachFile
    - Parameter attach: attach file that shoud be cleaned from user device`s disc
    */
    func eraseFileFromDiscForAttach(attach:AttachFile)
    {
        if let fileName = attach.fileName
        {
            let fileHandler = FileHandler()
            fileHandler.eraseFileNamed(fileName, completion: nil)
        }
    }
    
    /**
    Founds elementIDs for every attach, then looping through elementIDs searches for AttachFile arrays and in found arrays deletes supplied AttachFiles
    - Note: it is not desirable to feed attaches from several elements to this method(function)
    - Parameter attaches: an array of AttachFile.
    */
    func eraseFileInfoFromMemoryForAttaches(attaches:[AttachFile])
    {
        if attaches.isEmpty
        {
            return
        }
        
        var elementIDs = Set<Int>()
        
        for anAttachFile in attaches
        {
            if anAttachFile.elementID > 0
            {
                elementIDs.insert(anAttachFile.elementID)
            }
        }
        
        if elementIDs.isEmpty
        {
            return
        }
        
        let setOfAttachesToDelete = Set(attaches)
        var toReplaceDictValues = [Int:[AttachFile]]()
        for anElementIdIntKey in elementIDs
        {
            if let attaches = DataSource.sharedInstance.attaches[anElementIdIntKey]
            {
                print("attach count before loop: \(attaches.count)")
                var valueAtachesArray = [AttachFile]()
                for anExistingAttach in attaches
                {
                    if setOfAttachesToDelete.contains(anExistingAttach)
                    {
                        continue
                    }
                    valueAtachesArray.append(anExistingAttach)
                }
                if valueAtachesArray.isEmpty
                {
                    continue
                }
                
                ObjectsConverter.sortAttachesByAttachId(&valueAtachesArray)
                print("new attach count after loop: \(valueAtachesArray.count)")
                toReplaceDictValues[anElementIdIntKey] = valueAtachesArray
            }
        }
        
        if toReplaceDictValues.isEmpty
        {
            return
        }
        
        for (keyNum, valueArray) in toReplaceDictValues //insert new decreased arrays of attach files
        {
            if let _ = DataSource.sharedInstance.attaches.removeValueForKey(keyNum)
            {
                DataSource.sharedInstance.attaches[keyNum] = valueArray
            }
        }
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
            print(" empty snapshots array. returning nil.")
            return nil
        }
        
        print("  -> returning \(toReturnArray.count) snapshotDatas for \(attaches.count) AttacFiles\n")
        return toReturnArray
    }
    
    func getSnapshotImageDataForAttachFile(file:AttachFile) -> [AttachFile:NSData]?
    {
        
        if let cachedData = DataSource.sharedInstance.getAttachFileDataFromCache(file.fileName)
        {
            print(" ->returning attach snapshot from cache..")
            return [file:cachedData]
        }
        else
        {
            if let fileSystemData = DataSource.sharedInstance.getAttachFilePreviewImageDataFromFileSystem(file)
            {
                print(" ->returning attach snapshot from disc..")
                return [file:fileSystemData]
            }
            print(" ->returning nil attach snapshot")
            return nil
        }
    }
    
    /**
    Tries to read file by name from disc
    If file data was found, the previewImage is stored in cache
    - Returns: created previewImage JPEG NSData object, which is also stored to cache
    - Note: Method is synchronous. *Do not* call this method on main thread.
    */
    private func getAttachFilePreviewImageDataFromFileSystem(attachFile:AttachFile) -> NSData?
    {
        let lvFileHandler = FileHandler()
        var outerFileData:NSData? = nil
        
            lvFileHandler.loadFileNamed(attachFile.fileName!, completion: {
                (fileData, readingError) -> Void in
                if let attachData = fileData
                {
                    //reduce image size, and insert into cache already reduced image data
                    
                    if let fullImage = UIImage(data: attachData), scaledToSizeImage = DataSource.sharedInstance.reduceImageSize( fullImage, toSize: CGSizeMake(180, 140)), imagePreviewData = UIImageJPEGRepresentation(scaledToSizeImage, 1.0)
                    {
                            //print("\n--- Inserting imagePreview data \(imagePreviewData.length) bytes to cache...")
                            DataSource.sharedInstance.dataCache.setObject(imagePreviewData, forKey: attachFile.fileName!)
                            outerFileData = imagePreviewData
                    }
                    else
                    {
                        assert(false, "Check image preview data.")
                    }
                }
                else if let error = readingError
                {
                    print(" ->FileReadingError: \n\(error.localizedDescription)")
                }
            })
        
        return outerFileData
    }
    
    /**
    Reads attach previewData from local cache by file name
    - Parameter fileName: fileName of AttachFile
    - Returns:
        - an image preview NSData object.
        - nil if fileName is nil or if requested data was not found in cache
    - Note: this method is synchronous.
        - Do not call it on main thread.
    */
    private func getAttachFileDataFromCache(fileName:String?) -> NSData?
    {
        if let aName = fileName
        {
            return DataSource.sharedInstance.dataCache.objectForKey(aName) as? NSData
        }
        return nil
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
    
    
    func loadAttachFileDataForAttaches(attaches:[AttachFile], completion completionClosure:(()->())? = nil )
    {
        if attaches.isEmpty
        {
            completionClosure?()
            return
        }
        
     
        let recievedAttachesCount = attaches.count
        print("\n -> Starting to filter pending attaches..")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
     
        var localAttaches = [AttachFile]()
        
        for lvAttachFileLoading in attaches
        {
            if let pending = DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttachFileLoading.attachID]
            {
                if pending
                {
                    print("is pending")
                    continue
                }
                else
                {
                    print("pending is waiting to be cleared")
                    continue
                }
            }
            else
            {
                DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttachFileLoading.attachID] = true
                localAttaches.append(lvAttachFileLoading)
            }
        }
        
        if !localAttaches.isEmpty
        {
            let dispatchGroup = dispatch_group_create()
            let fileManager = FileHandler()
            
            let localAttachesCount = localAttaches.count
            
            print("\n -> Processing \(localAttachesCount) out of \(recievedAttachesCount) atatches...")
            
            let operationQueue = NSOperationQueue()
            operationQueue.maxConcurrentOperationCount = 2
            
            
            let lvQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
            dispatch_apply(localAttachesCount, lvQueue) { (currentIteration) -> Void in
                
                dispatch_group_enter(dispatchGroup)
                let lvAttach = localAttaches[currentIteration]
                
                if let name = lvAttach.fileName, _ = fileManager.synchronouslyLoadFileNamed(name)
                {
                    print("\n -> DataSource Will not load existing attach file several times. Attach File: \(lvAttach.fileName!)\n")
                    
                    if let name = lvAttach.fileName
                    {
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1))
                        dispatch_after(timeout, lvQueue, { () -> Void in
                            
                            NSNotificationCenter.defaultCenter().postNotificationName(kAttachDataDidFinishLoadingNotification, object: nil, userInfo: ["fileName" : name])
                        })
                    }
                    DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttach.attachID] = false
                    
                    dispatch_group_leave(dispatchGroup)
                }
                else
                {
                    let attachFileName = lvAttach.fileName
                    let attachId = lvAttach.attachID
                    print("\n -> Starting to load AttachFile Data from server... . Attach File: \(lvAttach.fileName!)\n")
                    DataSource.sharedInstance.serverRequester.loadDataForAttach(attachId, completion: { (attachFileData, error) -> () in
                        if let attachData = attachFileData, aFileName = attachFileName
                        {
                            fileManager.saveFileToDisc(attachData, fileName: aFileName , completion: { (path, saveError) -> Void in
                                if let _ = path
                                {
                                    //print("\n -> Saved a file")
                                    
                                    let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.1))
                                    dispatch_after(timeout, lvQueue, { () -> Void in
                                        
                                        NSNotificationCenter.defaultCenter().postNotificationName(kAttachDataDidFinishLoadingNotification, object: nil, userInfo: ["fileName" : aFileName])
                                    })
                                    
                                }
                                
                                if let savedError = saveError
                                {
                                    print("\n ->Failed to save data to disc: \n \(savedError.localizedDescription)")
                                }
                                DataSource.sharedInstance.pendingAttachFileDataDownloads[attachId] = false
                                dispatch_group_leave(dispatchGroup)
                            })
                        }
                        else
                        {
                            print(" \n ->Failed to load attach file data: \n \(error?.localizedDescription)")
                            DataSource.sharedInstance.pendingAttachFileDataDownloads[attachId] = false
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
                        let lvAttachId = anAttach.attachID
                        if lvAttachId > 0 {
                            DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttachId] = nil
                            print("\n Cleared pending \(lvAttachId)\n")
                        }
                        else {
                            print("\n Wrong (zero) attach id found.. Breaking up")
                            assert(false, "loadAttachFileDataForAttaches ->  AttachId = 0")
                        }
                    }
                })
            })
        }
        else
        {
            print("\n -> Will not process queried attach files - all are currently pending..")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let completionBlock = completionClosure
            {
                completionBlock()
            }
        }
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
    
    func getMyContacts() -> [Contact]?
    {
        if DataSource.sharedInstance.contacts.isEmpty
        {
            DataSource.sharedInstance.serverRequester.downloadMyContacts(completion: { (contacts, error) -> () in
                if error != nil
                {
                    print("Contacts loading failed: \n \(error!.localizedDescription)")
                }
                else if let aContacts = contacts
                {
                    if aContacts.isEmpty
                    {
                        print("WARNING!: Loaded empty contacts!!!!!")
                    }
                    else
                    {
                        print(" -> Loaded contacts: \(aContacts.count)")
                        DataSource.sharedInstance.contacts = aContacts
                    }
                }
            })
            
            return nil
        }
        
        let counter = DataSource.sharedInstance.contacts.count
        print("returning existing contacts (\(counter))")
        
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
                print(" ALL Contacts loading failed: \n \(error!.localizedDescription)")
                if let completionBlock = completion
                {
                    completionBlock(contacts: nil, error: error)
                }
            }
            else
            {
                if contacts!.isEmpty
                {
                    print("WARNING!: Loaded empty contacts!!!!!")
                    if let completionBlock = completion
                    {
                        completionBlock(contacts: nil, error: error)
                    }
                }
                else
                {
                    print(" -> Loaded ALL contacts: \(contacts!.count)")
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
                            
                            return (lvContact.contactId == lvContactId)
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
                        print("Added contact to chat Locally also.")
                    }
                    let newPassWhomIDs = Array(passWhomSet)
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
                        if let _ = passWhomSet.remove(contactId)
                        {
                            // successfully removed contact id from element`s pass whom ids
                            print("Removed contact from chat Locally also.")
                        }
                        let newPassWhomIDs = Array(passWhomSet)
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
                            alreadyExistIDsSet.insert(number)
                        }
                        
                        let succseededIDsSet = Set(succeededIDs)
                        
                        let commonValuesSet = alreadyExistIDsSet.union(succseededIDsSet)
                        
                        var idsArray = [Int]()
                        for integer in commonValuesSet
                        {
                            idsArray.append(integer)
                        }
                        
                        existingElement.passWhomIDs = idsArray
                        
                    }
                }
                else
                {
                    if failedIDs.count > 0
                    {
                        print("failed to assign contacts to current element: Contact IDs: \(failedIDs)")
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
                            if succeededSet.contains(contactID)
                            {
                                return false
                            }
                            return true
                        })
                        existingElement.passWhomIDs = filteredOut
                    }
                    if !failedIds.isEmpty
                    {
                        print("\n Failed to detach contacts:\(failedIds) from element \(elementId)\n")
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
                var currentContacts = Set(DataSource.sharedInstance.contacts)
                let countBefore = currentContacts.count
                currentContacts.insert(contact)
                let countAfter = currentContacts.count
                if countAfter == countBefore
                {
                    print("\n Warning!! DataSource did NOT ADD contact from myContacts\n")
                }
                
                let sorted = Array(currentContacts).sort({ (contact1, contact2) -> Bool in
                    if let
                        firstName1 = contact1.firstName,// as? String,
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
    
    
    //MARK: - Avatars
    func addAvatarData(avatarBytes:NSData, forContactUserName userName:String) -> ResponseType
    {
        var response:ResponseType
        if let imageData = DataSource.sharedInstance.avatarsHolder[userName]
        {
            if imageData == avatarBytes //checking NSData for equality of contents, not objects
            {
                print(" Will NOT Rewrite the same avatar data again for user name: \(userName)")
                return .Denied
            }
            response = .Replaced
            print(" -> Replaced avatar data for username: \(userName)")
        }
        else
        {
            response = .Added
            //print(" -> Added avatar data for username: \(userName)")
        }
        DataSource.sharedInstance.avatarsHolder[userName] = avatarBytes
        
        return response
    }
    
    func getAvatarDataForContactUserName(userName:String?) -> NSData?
    {
        if let lvName = userName
        {
            guard !lvName.characters.isEmpty else
            {
                return nil
            }
            
            if let existingBytes = DataSource.sharedInstance.avatarsHolder[lvName]
            {
                return existingBytes
            }
            
            if DataSource.sharedInstance.pendingUserAvatarsDownolads[lvName] == nil
            {
                let lowQueue:dispatch_queue_t
                if #available(iOS 8.0, *)
                {
                    let attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0)
                    lowQueue = dispatch_queue_create("com.Origami.BackgroundImage.Queue", attributes)
                }
                else
                {
                    lowQueue = dispatch_queue_create("com.Origami.BackgroundImage.Queue", DISPATCH_QUEUE_SERIAL)
                }
                
                dispatch_async(lowQueue, { () -> Void in
                     DataSource.sharedInstance.loadAvatarFromDiscForLoginName(lvName, completion: nil)
                })
            }
        }
        
        return nil
    }
    
    func getAvatarForUserId(userIdInt:Int) -> UIImage?
    {
        guard let currentUserId = DataSource.sharedInstance.user?.userId else {
            print("\n  NO USER ID in DATA SOURCE!\n")
            return nil
        }
        
        if userIdInt == currentUserId
        {
            if let data = DataSource.sharedInstance.getAvatarDataForContactUserName(DataSource.sharedInstance.user?.userName /*as? String*/)
            {
                return UIImage(data: data)
            }
        }
        else if let
            contacts = DataSource.sharedInstance.getContactsByIds(Set([userIdInt])),
            firstContact = contacts.first,
            cData = DataSource.sharedInstance.getAvatarDataForContactUserName(firstContact.userName)
        {
            let image = UIImage(data: cData)
            return image
        }
        
        return nil

    }
    
    func loadAvatarFromDiscForLoginName(loginName:String, completion completionBlock:((image:UIImage?, error:NSError?) ->())? )
    {
        let fileHandler = FileHandler()
        
        fileHandler.loadAvatarDataForLoginName(loginName, completion: { (avatarData, error) -> Void in
            if let avatarBytes = avatarData
            {
                guard let image = UIImage(data: avatarBytes) else {
                    let imageCreatingError = NSError(domain: "Origami.ImageDataConvertingError", code: 509, userInfo: [NSLocalizedDescriptionKey:"Could not convert data object to image object"])
                    completionBlock?(image: nil, error: imageCreatingError)
                    
                    return
                }
                
                completionBlock?(image: image, error: nil) //return value  
                
                //and continue background work
                
                if let avatarData = DataSource.sharedInstance.avatarsHolder[loginName]
                {
                    if let reducedImage = DataSource.sharedInstance.reduceImageSize(image, toSize: CGSizeMake(200, 200)),  avatarIconData = UIImageJPEGRepresentation(reducedImage, 1.0)
                    {
                        if avatarIconData != avatarData
                        {
                            DataSource.sharedInstance.addAvatarData(avatarIconData, forContactUserName: loginName)
                        }
                    }
                    
                }
                else
                {
                    if let reducedImage = DataSource.sharedInstance.reduceImageSize(image, toSize: CGSizeMake(200, 200)), avatarIconData = UIImageJPEGRepresentation(reducedImage, 1.0)
                    {
                        DataSource.sharedInstance.addAvatarData(avatarIconData, forContactUserName: loginName)
                    }
                }
            }
            else if let anError = error
            {
                completionBlock?(image: nil, error: error)
                
                if anError.code == 406 //no file or directory
                {
                    //find contact ID
                    let allContacts = DataSource.sharedInstance.contacts.filter {(aContact) in return aContact.userName == loginName}
                    if allContacts.isEmpty
                    {
                        return
                    }
                    
                    
                    let foundContact = allContacts.first!
                    let passingParameter = (name:foundContact.userName, id:foundContact.contactId)
                    DataSource.sharedInstance.startLoadingAvatarForUserName(passingParameter)
                }
            }
        })
    }
    
    /**
    Method first tries to get avatar thumbnail stored in RAM, if it is not found, the search on device`s disc is started, and if file is not fund, avatar downloading process starts.
    */
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
                
                print(" got avatar from RAM..")
                return
            }
            
            
            //step 2 try to get from disc
            DataSource.sharedInstance.loadAvatarFromDiscForLoginName(loginName, completion: { (image, error) -> () in
                
                if let _ = error
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completionBlock?(image: nil)
                    })
                }
                else
                {
                    if let avatarReducedImageData = DataSource.sharedInstance.getAvatarDataForContactUserName(loginName), image = UIImage(data: avatarReducedImageData)
                    {
                        completionBlock?(image:image)
                    }
                    else
                    {
                        completionBlock?(image:nil)
                    }
                }
                //step 3 try to load from server
                
            })

        })
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
                if let avatar = UIImage(data: avatarBytes)
                {
                    if let reducedImage = DataSource.sharedInstance.reduceImageSize(avatar, toSize: CGSizeMake(200, 200)), let avatarData = UIImageJPEGRepresentation(reducedImage, 1.0)
                    {
                        print(" got avatar from Server... Saving small preview data to ram")
                        DataSource.sharedInstance.addAvatarData(avatarData, forContactUserName: aName)//save to RAM also
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
                    })
                }
                else
                {
                    print(" Did not recieve avatar image bytes.")
                    DataSource.sharedInstance.pendingUserAvatarsDownolads[aName] = nil
                }
             
                return
            }
            
            if let anError = error
            {
                print(" Error while downloading avatar for userName: \(aName): \n \(anError.description) ")
            }
            DataSource.sharedInstance.pendingUserAvatarsDownolads[aName] = nil
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
    
    /**
    Cleans avatar file from disc and removes avatar preview from RAM
    */
    func cleanAvatarDataForUserName(name:String)
    {
        let aFileHandler = FileHandler()
        aFileHandler.eraseAvatarForUserName(name, completion: nil)
        DataSource.sharedInstance.avatarsHolder[name] = nil
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
