//
//  DataSource.swift
//  Origami
//
//  Created by CloudCraft on 02.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit
import ImageIO
@objc class DataSource: NSObject
{
    typealias voidClosure = () -> ()
    typealias successErrorClosure = (success:Bool, error:NSError?) -> ()
    typealias messagesArrayClosure = ([Message]?) -> ()
    typealias elementsArrayClosure = ([Element]?) -> ()
    typealias contactsArrayClosure = ([Contact]?) -> ()
    typealias attachesArrayClosure = ([AttachFile]) -> ()
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
    }
    
    //singletonegetSubordinateElementsForElement
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
    
    private lazy var dataCache:NSCache = NSCache()
    lazy var pendingAttachFileDataDownloads = [NSNumber:Bool]()
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
            DataSource.sharedInstance.avatarsHolder.removeAll(keepCapacity: false)
            DataSource.sharedInstance.removeAllObserversForNewMessages()
            if  completion != nil
            {
                //return into main queue
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion!()
                })
            }
        })
    }
    
    func cleanDataCache()
    {
        println("..Datasource is clearing Data Cache...")
        
        DataSource.sharedInstance.dataCache.removeAllObjects()
    }
    //User
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
            serverRequester.loginWith(userName, password: password, completion: {[weak self] (userResult, loginError) -> () in
                if let lvUser = userResult as? User
                {
                    self!.user = lvUser
                    completion(user: self!.user, error: nil)
                }
                else
                {
                    completion(user: nil, error: loginError)
                }
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
        serverRequester.loadAllMessages {
            (resultArray, serverError) -> () in
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), { () -> Void in
                if let messagesArray = resultArray as? [Message]
                {
                    var lvMessagesHolder = [NSNumber:[Message]]()
                    for lvMessage in messagesArray
                    {
                        //println(">>> ElementId:\(lvMessage.elementId) , Message: \(lvMessage.textBody)")
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
//                            if var existingMessages = DataSource.sharedInstance.messages[keyElementId]
//                            {
                                DataSource.sharedInstance.addMessages(messages, forElementId: keyElementId, completion: nil)
//                                existingMessages += messages
//                                DataSource.sharedInstance.messages[keyElementId] = existingMessages
//                            }
//                            else
//                            {
//                                DataSource.sharedInstance.messages[keyElementId] = messages
//                            }
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
                }
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
         
        }
    }
    
    func sendNewMessage(message:Message, completion:errorClosure)
    {
        //can be not main queue
        println(" -> Send new message Called.")
        serverRequester.sendMessage(message, toElement: message.elementId!) { (result, error) -> () in
            
            //main queue
            if error != nil
            {
                completion(error)
            }
            else
            {
                DataSource.sharedInstance.addMessages([message], forElementId: message.elementId!, completion: nil)
                completion(nil)
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
        
//        //also check for HomeVC embeded VC observing for new messages
//        if let allMessagesObserver = getMessagesObserverForElementId(All_New_Messages_Observation_ElementId)
//        {
//            allMessagesObserver.newMessagesAdded(messageObjects)
//        }
        
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
    
    func getMessagesQuantyty(quantity:Int, forElementId elementId:NSNumber?, lastMessageId messageId:NSNumber?) -> [Message]
    {
        if elementId == nil
        {
            return [Message]()
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
                    let reversedArray = existingMessagesForElementId.reverse()
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
                    let reversedArray = existingMessagesForElementId.reverse()
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
            return [Message]()//empty array
        }
    }
    
    func getLastMessagesForDashboardCount(messagesQuantity:Int, completion completionClosure:((messages:[Message]?)->())? = nil)
    {
        
        let bgQueue:dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
        
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
            
            println(" Starting sorting for last 3 messages in background")
            
            var allMessagesSet = Set<Message>()
            for (_,lvMessages) in DataSource.sharedInstance.messages
            {
                allMessagesSet.unionInPlace( Set(lvMessages))
            }
            var unsortedArray = Array(allMessagesSet)
            
            ObjectsConverter.sortMessagesByDate(&unsortedArray)
            
            if unsortedArray.count > messagesQuantity //now the array is actually SORTED
            {
                var lastThreeItems = [Message]()
                for var i = 0; i < messagesQuantity; i++
                {
                    var last = unsortedArray.removeLast()
                    lastThreeItems.insert(last, atIndex: 0)
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let completionBlock = completionClosure
                    {
                        println(" Finished sorting last 3 messages for HomeScreen.")
                        completionBlock(messages: lastThreeItems) //return result
                    }
                })
                
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let completionBlock = completionClosure
                    {
                        println(" Finished sorting last 3 messages for HomeScreen.")
                        completionBlock(messages: unsortedArray) //return result
                    }
                })
            }
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
                DataSource.sharedInstance.addNewElements([successElement], completion: nil)
                closure(newElementId: successElement.elementId!.integerValue, error: nil)
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
        if (completion != nil)
        {
            completion!()
        }
    }
    
    func getElementById(elementId:NSNumber) -> Element?
    {
        let foundElements = DataSource.sharedInstance.elements.filter
        { lvElement -> Bool in
            return lvElement.elementId?.integerValue == elementId.integerValue
        }
        if !foundElements.isEmpty
        {
            return foundElements.last
        }
        return  nil
    }
    
    func getRootElementTreeForElement(targetElement:Element) -> [Element]?
    {
        if let root = targetElement.rootElementId
        {
            var elements = [Element]()
            
            var tempElement = targetElement
            
            while let rootElementId = tempElement.rootElementId
            {
                if let foundRootElement = DataSource.sharedInstance.getElementById(rootElementId)
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
    
    func getSubordinateElementsForElement(elementId:NSNumber?) -> [Element]
    {
       
        var elementsToReturn:[Element] = [Element]()
        if elementId == nil
        {
            return elementsToReturn
        }
        
        for lvElement in DataSource.sharedInstance.elements
        {
            if lvElement.rootElementId?.integerValue == elementId!.integerValue
            {
                elementsToReturn.append(lvElement)
            }
        }
        
        elementsToReturn.sort({ (elt1, elt2) -> Bool in
            if elt1.createDate != nil && elt2.createDate != nil
            {
                if let
                    date1 = elt1.createDate!.dateFromServerDateString()
                    ,date2 = elt2.createDate!.dateFromServerDateString()
                {
                    if let changeDate1 = elt1.changeDate?.dateFromServerDateString() , changeDate2 = elt2.changeDate?.dateFromServerDateString()
                    {
                        let changedComparing = changeDate1.compare(changeDate2)
                        return changedComparing == .OrderedDescending
                    }
                    else
                    {
                        let result = date1.compare(date2)
                        return result == NSComparisonResult.OrderedDescending
                    }
                }
                else
                {
                    return true
                }
            }
            else
            {
                return true
            }
        })

        
        return elementsToReturn
    }
    
    func getSubordinateElementsTreeForElement(targetRootElement:Element) -> [Element]?
    {
        var treeToReturn = [Element]()
        
        let currentSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(targetRootElement.elementId)
        if currentSubordinates.isEmpty
        {
            return nil
        }
        
        let countSubordinates = currentSubordinates.count
        var subordinatesSet = Set<Element>()
        
        for lvElement in currentSubordinates
        {
            let subordinatesFirst =  DataSource.sharedInstance.getSubordinateElementsForElement(lvElement.elementId)
            if !subordinatesFirst.isEmpty
            {
                let subSetFirst = Set(subordinatesFirst)
                subordinatesSet.exclusiveOrInPlace(subSetFirst)
            }
        }
    
        return Array(subordinatesSet)
       
    }
    
    func getDashboardElements( completion:([Int:[Element]])->() )
    {
        //println("\r _________ Started gathering elements for Dashboard.....")
        let dispatchQueue = dispatch_queue_create("elements.sorting", DISPATCH_QUEUE_SERIAL)
        dispatch_async(dispatchQueue,
        {
            [unowned self] in
            
            var signalElements = [Element]()
            var favouriteElements = DataSource.sharedInstance.elements.filter({ (checkedElement) -> Bool in
                if let hasFavSet = checkedElement.isFavourite
                {
                    return hasFavSet.boolValue
                }
                return false
            })
            
            ObjectsConverter.sortElementsByDate(&favouriteElements)
            
            var otherElements = [Element]()
            
            let filteredMainElements = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
                let testReturned = (element.rootElementId!.integerValue == 0)
                return testReturned
            })
            
            for lvElement in filteredMainElements
            {
                if lvElement.isSignal!.boolValue
                {
                    //println("appending SIGNALS: id= \(lvElement.elementId!)")
                    signalElements.append(lvElement)
                }
//                if lvElement.isFavourite!.boolValue
//                {
//                    //println("appending FAVOURITES: id= \(lvElement.elementId!)")
//                    favouriteElements.append(lvElement)
//                }
                
                //println("appending OTHER: id= \(lvElement.elementId!)")
                otherElements.append(lvElement)
            }
            
            // get all signals
            var filteredSignals = DataSource.sharedInstance.elements.filter({ (element) -> Bool in
                
                if element.isSignal != nil
                {
                    return (element.isSignal!.boolValue && (element.rootElementId!.integerValue > 0))
                }
                return false
            })
            if !filteredSignals.isEmpty
            {
                ObjectsConverter.sortElementsByDate(&filteredSignals)
                
                //DEBUG START
//                for lvElement in filteredSignals
//                {
//                    println("appending Non Root SIGNALS: id= \(lvElement.elementId!)")
//                }
                //DEBUG END
                signalElements += filteredSignals
            }
            
            
            dispatch_async(dispatch_get_main_queue(),
            {
                _ in
                let toReturn = [1:signalElements, 2:favouriteElements, 3:otherElements]
                completion(toReturn)
            })
        })
    }
    
    func loadAllElements(completion:(success:Bool, failure:NSError?) ->())
    {
        serverRequester.loadAllElements {(result, error) -> () in
            
            if let allElements = result as? [Element]
            {
                //if let elements = DataSource.sharedInstance.elements
                //{
                    DataSource.sharedInstance.elements.removeAll(keepCapacity: false)
                //}
                DataSource.sharedInstance.elements += allElements
                completion(success: true, failure: nil)
            }
            else
            {
                completion(success: false, failure: error)
            }
        }
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
       serverRequester.editElement(element, completion: { (success, error) -> () in
        
        NSOperationQueue.mainQueue().addOperationWithBlock()
        { () -> Void in
            if success
            {
                println("\r - Edit successfull")
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
    }
    
    func updateElement(element:Element, isFavourite favourite:Bool, completion completionClosure:(edited:Bool)->() )
    {
        serverRequester.setElementWithId(element.elementId!, favourite: favourite) { (success, error) -> () in
            if success{
                completionClosure(edited: true)
            }
            else
            {
                completionClosure(edited: false)
                println("Error did not update FAVOURITE for element.")
            }
        }
    }
    
    
    func loadPassWhomIdsForElement(element:Element, comlpetion completionClosure:(finished:Bool)->() ) {
        
        serverRequester.loadPassWhomIdsForElementID(element.elementId!, completion: { (passWhomIds, error) -> () in
            if passWhomIds != nil
            {
                element.passWhomIDs = passWhomIds
                completionClosure(finished: true)
            }
            else
            {
                completionClosure(finished: false)
            }
        })
    }
    
    func deleteElementFromServer(elementId:Int, completion closure:(deleted:Bool, error:NSError?) ->())
    {
        DataSource.sharedInstance.serverRequester.deleteElement(elementId, completion: closure)
    }
    
    func deleteElementFromLocalStorage(elementId:Int)
    {
        var index = -1
        var counter = 0
        for element in DataSource.sharedInstance.elements
        {
            if element.elementId!.integerValue == elementId
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
                    DataSource.sharedInstance.elements = Array(afterDeletionSet)
                }
                
                
                // iterate through all elements and if element has Root element id, but the root element id is not found - delete it
                var setToDelete = Set<Element>()
                for lvElement in DataSource.sharedInstance.elements
                {
                    if lvElement.rootElementId!.integerValue > 0
                    {
                        if DataSource.sharedInstance.getElementById(lvElement.rootElementId!) == nil
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
                let reCheckSubordinates = DataSource.sharedInstance.getSubordinateElementsForElement(elementId)
                if !reCheckSubordinates.isEmpty
                {
                    // assert(false, "Check properly deleted subordinates....")
                    println("Did not delete subordinates for current element Id: \(elementId)")
                }
            }
        }
    }
    
    func cleanAttachesForElement(elementId:Int)
    {
//        if let currentElement = DataSource.sharedInstance.getElementById(NSNumber(integer:elementId))
//        {
            let attaches = DataSource.sharedInstance.getAttachesForElementById(elementId)
            if !attaches.isEmpty
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
    func getAttachesForElementById(elementId:NSNumber?) -> [AttachFile]
    {
        var foundAttaches = [AttachFile]()
        
        if elementId == nil
        {
            return foundAttaches
        }
        
        if let attaches = DataSource.sharedInstance.attaches[elementId!]
        {
            foundAttaches += attaches
        }
        return foundAttaches
    }
    
    func loadAttachesForElement(element:Element, completion:attachesArrayClosure)
    {
        if let localElementId = element.elementId
        {
            let existingAttachObjects = DataSource.sharedInstance.getAttachesForElementById(localElementId)
            if !existingAttachObjects.isEmpty
            {
                //println("Datasource returning existing attach objects for element:\(element.title!)")
                completion(existingAttachObjects)
                return
            }
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
                    completion([AttachFile]())
                }
            })
        }
        else
        {
            completion([AttachFile]())
        }
    }
    
    func refreshAttachesForElement(element:Element, completion:attachesArrayClosure)
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
                        completion([AttachFile]())
                    }
            })
        }
    }
    
    func attachFile(file:MediaFile, toElementId elementId:NSNumber, completion completionClosure:(success:Bool, error: NSError?)->() ) {
        serverRequester.attachFile(file, toElement: elementId) { (successAttached, attachId ,errorAttached) -> () in
            
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
                println("Could not deattach file on server: \n Error: \n\(fromServerError)")
                completionClosure(success: success, error: fromServerError)
            }
        }
    }
    
    func eraseFileFromDiscForAttach(attach:AttachFile)
    {
        let fileHandler = FileHandler()
        fileHandler.eraseFileNamed(attach.fileName, completion: nil)
    }
    
    func getSnapshotImageDataForAttachFile(file:AttachFile) -> NSData?
    {
        if let cachedData = DataSource.sharedInstance.getAttachFileDataFromCache(file)
        {
            return cachedData
        }
        else
        {
            var fileSystemData = DataSource.sharedInstance.getAttachFileDataFromFileSystem(file)
            return fileSystemData
        }
    }
    
    private func getAttachFileDataFromFileSystem(attachFile:AttachFile) -> NSData?
    {
        let lvFileHandler = FileHandler()
        let waiterGroup = dispatch_group_create()
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
                    println("FileReadingError: \n\(readingError.localizedDescription)")
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
        
        return scaledToSizeImage
    }
    
    
    func loadAttachFileDataForAttaches(attaches:[AttachFile], completion completionClosure:(()->())? = nil )
    {
        let dispatchGroup = dispatch_group_create()
        let fileManager = FileHandler()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        for lvRttachFileLoading in attaches
        {
            DataSource.sharedInstance.pendingAttachFileDataDownloads[lvRttachFileLoading.attachID!] = true
        }
        
        let attachesCount = attaches.count
        
        let lvQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_apply(attachesCount, lvQueue) { (currentIteration) -> Void in
            
            dispatch_group_enter(dispatchGroup)
            let lvAttach = attaches[currentIteration]
            
            DataSource.sharedInstance.serverRequester.loadDataForAttach(lvAttach.attachID!, completion: { (attachFileData, error) -> () in
                if attachFileData != nil
                {
                    fileManager.saveFileToDisc(attachFileData!, fileName: lvAttach.fileName! , completion: { (path, saveError) -> Void in
                        if path != nil {
                            //println("Saved file to : \(path!)")
                        }
                        if saveError != nil{
                            println("Failed to save data to disc: \n \(saveError?.localizedDescription)")
                        }
                         DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttach.attachID!] = nil
                        dispatch_group_leave(dispatchGroup)
                    })
                }
                else
                {
                    println("Failed to load attach file data: \n \(error?.localizedDescription)")
                     DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttach.attachID!] = nil
                    dispatch_group_leave(dispatchGroup)
                }
            })
        }
        
       
    
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue(), { () -> Void in
            print("\n ....finished loading all attachment file datas. >>>>>\n")
            
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if completionClosure != nil
            {
                completionClosure!()
            }
        })
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
    
    func getAllContacts() -> [Contact]?
    {
        if DataSource.sharedInstance.contacts.isEmpty
        {
            serverRequester.downloadAllContacts(completion: { (contacts, error) -> () in
                if error != nil
                {
                    println("Contacts loading failed: \n \(error!.localizedDescription)")
                }
                else
                {
                    if contacts!.isEmpty
                    {
                        println("WARNING!: Loaded empty contacts!!!!!")
                    }
                    else
                    {
                        DataSource.sharedInstance.contacts = contacts!
                    }
                }
            })
            return nil
        }
        return DataSource.sharedInstance.contacts
    }
    
    func getContactsForElement(elementId:NSNumber, completion:contactsArrayClosure?)
    {
        if completion != nil
        {
            var contactsToReturn:[Contact]
            if let lvElement = DataSource.sharedInstance.getElementById(elementId)
            {
                if lvElement.passWhomIDs?.count > 0
                {
                    contactsToReturn = [Contact]()
                    for lvContactId in lvElement.passWhomIDs!
                    {
                        var lvContacts = DataSource.sharedInstance.contacts.filter {lvContact -> Bool in  return lvContact.contactId?.integerValue == lvContactId.integerValue}
                        if lvContacts.count > 0
                        {
                            let lastContact = lvContacts.removeLast()
                            contactsToReturn.append(lastContact)
                        }
                    }
                    completion!(contactsToReturn)
                    return
                }
                completion!(nil)
                return
            }
            completion!(nil)
        }
    }
    func addContact(contactId:NSNumber, toElement elementId:NSNumber, completion completionClosure:(success:Bool, error:NSError?) -> ())
    {
        serverRequester.passElement(elementId, toContact: contactId, forDeletion: false) { (requestSuccess, resuertError) -> () in
           
            if requestSuccess
            {
                if let element = DataSource.sharedInstance.getElementById(elementId), passWhomIDs = element.passWhomIDs
                {
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
    func removeContact(contactId:NSNumber, fromElement elementId:NSNumber, completion completionClosure:(success:Bool, error:NSError?) -> ())
    {
        serverRequester.passElement(elementId, toContact: contactId, forDeletion: true) { (requestSuccess, resuertError) -> () in
            
            if requestSuccess
            {
                if let element = DataSource.sharedInstance.getElementById(elementId), passWhomIDs = element.passWhomIDs
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
            
            completionClosure(success:requestSuccess, error: resuertError)
        }
    }
    
    func addSeveralContacts(contactIDs:[Int], toElement elementId:NSNumber, completion completionClosure:(succeededIDs:[Int], failedIDs:[Int])->())
    {
        DataSource.sharedInstance.serverRequester.passElement(elementId.integerValue, toSeveratContacts: contactIDs, completion: { (succeededIDs, failedIDs) -> () in
           
            if succeededIDs.count > 0
            {
                if let existingElement = DataSource.sharedInstance.getElementById(elementId)
                {
                    var numberIDs = [NSNumber]()
                    for integer in succeededIDs
                    {
                        numberIDs.append(NSNumber(integer: integer))
                    }
                    existingElement.passWhomIDs = numberIDs
                }
            }
            
            completionClosure(succeededIDs: succeededIDs, failedIDs: failedIDs)
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
                return existingBytes
            }
        }
        
        return nil
    }    
}
