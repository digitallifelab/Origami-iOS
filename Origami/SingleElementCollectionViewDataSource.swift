//
//  SingleElementCollectionViewDataSource.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, MessageTapDelegate, AttachmentCellDelegate
{
    var displayMode:DisplayMode = .Day
    var titleCellMode:ElementDashboardTitleCellMode = .Title
    var editingEnabled = false
    var subordinateTapDelegate:ElementSelectionDelegate?
    var attachTapDelegate:AttachmentSelectionDelegate?
    var messageTapDelegate:MessageTapDelegate?
    
    var titleCell:SingleElementTitleCell?
    var detailsCell:SingleElementDetailsCell?
    var currentCellsOptions:ElementCellsOptions?
    
    //var attachesHandler:ElementAttachedFilesCollectionHandler?
    var subordinatesByIndexPath:[NSIndexPath : Element]?
    var taskUserAvatar:UIImage?
    var currentAttaches:[AttachFile]?
    weak var handledCollectionView:UICollectionView?
    
    weak var handledElement:Element? {
        didSet {
            // detect visible cells by checking options
            var options:[ElementCellType] = [ElementCellType]()
            if let _ = getElementTitle()
            {
                //print("\n appended Title")
                options.append(.Title)
            }
            if let _ = getElementLastMessages()
            {
                //print("\n appended CHAT\n")
                options.append(.Chat)
            }
            if let details = getElementDetails()
            {
                if !details.isEmpty
                {
                    //print("\n appended DETAILS")
                    options.append(.Details)
                }
                
            }
            
            //self.attachesHandler = nil
            
            if let attachesForElement = getElementAttaches()//let attachesCollectionHandler = getElementAttachesHandler()
            {
                print("\n -> Current Attaches : \(attachesForElement.count)")
                self.currentAttaches = attachesForElement
                options.append(.Attaches)
            }           
            
            if let _ = getElementSubordinates()
            {
                //print("\n appended Subordinates")
                options.append(.Subordinates)
            }
            
            self.currentCellsOptions = ElementCellsOptions(types: Set(options))
            
            calculateAllCellTypes()
            
        }
    }
    
 

    override init() {
        //self.handledElement = Element()
        super.init()
        
    }
    
    convenience init?(element:Element?)
    {
        self.init()
        
        if element == nil
        {
            return nil
        }
        else if element!.elementId == nil
        {
            return nil
        }
        else if element!.elementId!.integerValue <= 0
        {
            return nil
        }
        
        //self.handledElement = element!
    }
    
    func getElementTitle() -> String?
    {
        if let elementTitle = handledElement?.title as? String
        {
            return elementTitle
        }
        return nil
    }
    
    func getElementDetails() -> String?
    {
        if let elementDetails = handledElement?.details as? String
        {
            return elementDetails
        }
        
        return nil
    }
    
    func getElementLastMessages() -> [Message]?
    {
        if let currentElement = handledElement, messages = DataSource.sharedInstance.getChatPreviewMessagesForElementId(currentElement.elementId!)// DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: handledElement?.elementId, lastMessageId: nil)
        {
            return messages
        }
        return nil
    }
    
    func getElementAttaches() -> [AttachFile]?
    {
        if let attaches =  DataSource.sharedInstance.getAttachesForElementById(handledElement?.elementId?.integerValue)
        {
            return  attaches
        }
        return nil
    }
    
    func getElementSubordinates() -> [Element]?
    {
        let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(handledElement?.elementId?.integerValue, shouldIncludeArchived: true)
        
        if subordinates.isEmpty
        {
            return nil
        }
        else
        {
            let unarchivedSubordinates = ObjectsConverter.filterArchiveElements(false, elements: subordinates)
            if unarchivedSubordinates.isEmpty
            {
                return nil
            }
            return unarchivedSubordinates
        }
        //return subordinates
    }
    
    func elementIsTask() -> Bool
    {
        if let element = self.handledElement
        {
            let optionsCovnerter = ElementOptionsConverter()
            return optionsCovnerter.isOptionEnabled(.Task, forCurrentOptions: element.typeId.integerValue)
        }
        return false
    }
    
    func getLayoutInfo() -> ElementDetailsStruct?
    {
        if let options = self.currentCellsOptions
        {
            //prepare easy values
            var elementTitle:String?
            if let title = self.handledElement?.title as? String
            {
                elementTitle = title
            }
            if elementTitle == nil
            {
                return nil
            }
            
            var elementDetails:String? = self.handledElement?.details as? String
            if elementDetails != nil
            {
                if elementDetails!.isEmpty
                {
                    elementDetails = nil
                }
            }
            let messages:Bool = options.cellTypes.contains(.Chat)
            let attaches:Bool = options.cellTypes.contains(.Attaches)
            //var buttons = options.cellTypes.contains(.Buttons)
            
            
            var subordinatesInfo:[SubordinateItemLayoutWidth]?
            //prepare subordinate cells values
            if let subordinateStore = self.subordinatesByIndexPath
            {
                //get ordered array of indexPaths for subordinates
                var allValues = Array(subordinateStore)
                allValues.sortInPlace({ (item1, item2) -> Bool in
                    
                     return item1.0.item < item2.0.item  //item1 - (NSIndexPath, Element), we are interested in sorting by indexPath
                })
                
                //create array with subordinate layout characteristics
                var lvSubordinatesInfo = [SubordinateItemLayoutWidth]()
                for var i = 0; i < allValues.count; i++
                {
                    let value = allValues[i] //again tuple
                    let lvElement = value.1
                    if DataSource.sharedInstance.getSubordinateElementsForElement(lvElement.elementId?.integerValue, shouldIncludeArchived: false).count > 0
                    {
                        lvSubordinatesInfo.append(.Wide)
                    }
                    else
                    {
                        lvSubordinatesInfo.append(.Normal)
                    }
                }
                if !lvSubordinatesInfo.isEmpty
                {
                    subordinatesInfo = lvSubordinatesInfo
                }
            }
            
            //finally
            let targetStruct = ElementDetailsStruct(title: elementTitle!,
                details: elementDetails,
                messagesCell: messages, /* buttonsCell: buttons,*/
                attachesCell: attaches,
                subordinateItems: subordinatesInfo)
            
            return targetStruct
        }
        else
        {
            return nil
        }
    }
    
    private func calculateAllCellTypes()
    {
        if let options = self.currentCellsOptions
        {
            var indexCount = 0
            var cellTypes = [ElementCellType]()
            if options.cellTypes.contains(.Title)
            {
                cellTypes.append(.Title)
                indexCount += 1
            }
            if options.cellTypes.contains(.Chat)
            {
                cellTypes.append(.Chat)
                indexCount += 1
            }
            if options.cellTypes.contains(.Details)
            {
                cellTypes.append(.Details)
                indexCount += 1
            }
            if options.cellTypes.contains(.Attaches)
            {
                cellTypes.append(.Attaches)
                indexCount += 1
            }
            
            if options.cellTypes.contains(.Subordinates)
            {
                if let subordinates = getElementSubordinates()
                {
                    var lvSubordinateIndexPaths = [NSIndexPath : Element]()
                    for var i = 0; i < subordinates.count; i++
                    {
                        cellTypes.append(.Subordinates)
                        let subordinateIndexPath = NSIndexPath(forItem: indexCount, inSection: 0)
                        lvSubordinateIndexPaths[subordinateIndexPath] = subordinates[i]
                        indexCount += 1
                    }
                    self.subordinatesByIndexPath = lvSubordinateIndexPaths
                }
            }
        }
    }
    
    //MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let itemsCount = countAllItems()
        //print("SingleElementCOllectionDataSource  -> \n items count: \(itemsCount)\n")
        return itemsCount
    }
    
    func countAllItems() -> Int
    {
        if let cellOptions = self.currentCellsOptions
        {
            var count = cellOptions.countOptions
            if cellOptions.cellTypes.contains(.Subordinates)
            {
                count -= 1
            }
            if let subordinates = self.subordinatesByIndexPath
            {
                count += subordinates.count
            }
            return count
        }
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        if let orderedOptions = currentCellsOptions?.orderedOptions
        {
            if indexPath.item >= orderedOptions.count
            {
                return returnCellByType(ElementCellType.Subordinates, forIndexPath: indexPath, collection: collectionView)
            }
            
            let currentCellType = orderedOptions[indexPath.item]
            
            return returnCellByType(currentCellType, forIndexPath: indexPath, collection: collectionView)
        }
        else
        {
            let defaultCell = UICollectionViewCell(frame: CGRectMake(10, 10, 50.0, 50.0))
            defaultCell.backgroundColor = UIColor.purpleColor()
            return defaultCell
        }
    }
    
    func returnCellByType(type:ElementCellType, forIndexPath indexPath:NSIndexPath, collection collectionView:UICollectionView) -> UICollectionViewCell
    {
        
        switch type
        {
        case .Title:
            
            switch titleCellMode
            {
            case .Title:
                let titleCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementTitleCell",
                                                                                forIndexPath: indexPath) as! SingleElementTitleCell
                
                titleCell.displayMode = self.displayMode
                
                //titleCell.labelTitle.text = getElementTitle()
                if let title = getElementTitle()
                {
                    titleCell.titleTextView?.attributedText = NSAttributedString(string: title, attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 30)!, NSForegroundColorAttributeName:kWhiteColor])
                }
                
                titleCell.labelDate.text = handledElement?.lastChangeDateReadableString()// changeDate?.dateFromServerDateString()?.timeDateStringShortStyle() as? String
                if let isFavourite = self.handledElement?.isFavourite.boolValue
                {
                    titleCell.favourite = isFavourite
                }
                titleCell.handledElement = self.handledElement
                titleCell.setupActionButtons(elementIsOwned())
              
                if let currentelement = self.handledElement
                {
                    let avatarIconView = titleCell.responsiblePersonAvatarIcon
                    
                    let responsibleIdInt = currentelement.responsible.integerValue
                    let creatorId = currentelement.creatorId.integerValue
                    
                    titleCell.responsiblePersonAvatarIcon?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)

                    if let user = DataSource.sharedInstance.user, currentUserIDInt = user.userId?.integerValue
                    {
                        if responsibleIdInt > 0 //show responsible`s avatar and name
                        {
                            if creatorId == responsibleIdInt
                            {
                                if creatorId == currentUserIDInt //user sees own element in which he is responsible
                                {
//                                    if let aName = user.nameAndLastNameSpacedString()
//                                    {
                                        titleCell.responsibleNameLabel?.text = "Your Own Task"
//                                    }
                                }
                                else //contact`s element in which this contact is responsible
                                {
                                    if let contacts = DataSource.sharedInstance.getContactsByIds(Set([responsibleIdInt])), aContact = contacts.first //as? Contact
                                    {
                                        if let contactName = aContact.nameAndLastNameSpacedString()
                                        {
                                            titleCell.responsibleNameLabel?.text = contactName
                                        }
                                    }
                                }
                            }
                            else //responsible for task is current user or another contact
                            {
                                if responsibleIdInt == currentUserIDInt //user sees not owned element in which he is responsible
                                {
                                    titleCell.responsibleNameLabel?.text = "Task for You"
                                }
                                else //user sees now owned element in which another contact in responsible
                                {
                                    if let contacts = DataSource.sharedInstance.getContactsByIds(Set([responsibleIdInt])), aContact = contacts.first //as? Contact
                                    {
                                        if let contactName = aContact.nameAndLastNameSpacedString()
                                        {
                                            titleCell.responsibleNameLabel?.text = contactName
                                        }
                                    }
                                }
                            }
                            
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak avatarIconView]() -> Void in
                                if let ownerAvatar = DataSource.sharedInstance.getAvatarForUserId(responsibleIdInt), imageView = avatarIconView
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        imageView.image = ownerAvatar
                                    })
                                }
                            })
                        }
                        else
                        {
                            //show current user`s data
                            if creatorId == currentUserIDInt //user sees own element
                            {
//                                if let aName = user.nameAndLastNameSpacedString()
//                                {
                                    titleCell.responsibleNameLabel?.text = "Your Own Element"
//                                }
                            }
                            else //contact`s data
                            {
                                if let contacts = DataSource.sharedInstance.getContactsByIds(Set([creatorId])), aContact = contacts.first //as? Contact
                                {
                                    if let contactName = aContact.nameAndLastNameSpacedString()
                                    {
                                        titleCell.responsibleNameLabel?.text = contactName
                                    }
                                }
                            }
                            //load avatar by element`s creator id
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak avatarIconView]() -> Void in
                                if let ownerAvatar = DataSource.sharedInstance.getAvatarForUserId(creatorId), weakAvatarIcon = avatarIconView
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        weakAvatarIcon.image = ownerAvatar
                                    })
                                }
                            })                            
                        }
                       
                    }
                   
                }
                
                self.titleCell = titleCell
                return titleCell
                
            case .Dates:
                let datesCell = collectionView.dequeueReusableCellWithReuseIdentifier("DateDetailsCell",
                                                                                forIndexPath: indexPath) as! SingleElementDateDetailsCell
                datesCell.displayMode = self.displayMode
                datesCell.handledElement = self.handledElement
                
                var owned = elementIsOwned()
                datesCell.setupActionButtons(owned)
               if !owned
               {
                if  let currentElement = self.handledElement, userIdInt = DataSource.sharedInstance.user?.userId?.integerValue, parentElements = DataSource.sharedInstance.getRootElementTreeForElement(currentElement)
                {
                    for anElement in parentElements
                    {
                        if anElement.creatorId.integerValue == userIdInt
                        {
                            if !owned
                            {
                                owned = true
                                datesCell.setupActionButtons(owned)
                            }
                            
                            break
                        }
                    }
                    
                }
                }
                
                
                return datesCell
            }
            
        case .Chat:
            let chatCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementChatPreviewCell",
                                                                                forIndexPath: indexPath) as! SingleElementLastMessagesCell
            chatCell.displayMode = self.displayMode
            if let messages = DataSource.sharedInstance.getChatPreviewMessagesForElementId(self.handledElement!.elementId!)
            {
                chatCell.messages = messages
            }
            chatCell.cellMessageTapDelegate = self
            chatCell.reloadTable()
            return chatCell
            
        case .Details:
            if let detailsCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementDetailsCell",
                                                                                forIndexPath: indexPath) as? SingleElementDetailsCell
            {
                detailsCell.textLabel.text = getElementDetails()
                detailsCell.displayMode = self.displayMode
                self.detailsCell = detailsCell
            
                return detailsCell
            }
            else
            {
                
                let detailsCell = SingleElementDetailsCell()
                detailsCell.textLabel.text = getElementDetails()
                detailsCell.displayMode = self.displayMode
                
                self.detailsCell = detailsCell
                
                return detailsCell
            }
        
            
        case .Attaches:
            
            let aCell:AnyObject = collectionView.dequeueReusableCellWithReuseIdentifier("AttachesHolderCell", forIndexPath: indexPath)
            if let attachesHolderCell = aCell as? SingleElementAttachesCollectionHolderCell,  _ = self.currentAttaches
            {
                attachesHolderCell.attachesCollectionView?.delegate = attachesHolderCell
                attachesHolderCell.delegate = self
                attachesHolderCell.attachesCollectionView?.dataSource = attachesHolderCell
                attachesHolderCell.attachesCollectionView?.reloadData()
                return attachesHolderCell
            }
            else
            {
                assert(false, "")
            }
            
        case .Subordinates:
            let subordinateCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementSubordinateCell", forIndexPath: indexPath) as! DashCell
           
            subordinateCell.displayMode = self.displayMode
            subordinateCell.cellType = .Other
            
            if let
                subordinatesStore = self.subordinatesByIndexPath,
                lvElement = subordinatesStore[indexPath]
            {
                subordinateCell.titleLabel?.text = lvElement.title as? String
                subordinateCell.descriptionLabel?.text = lvElement.details as? String
                subordinateCell.signalDetectorView?.hidden = true
                
                let signalFlag = lvElement.isSignal.boolValue
                subordinateCell.signalDetectorView?.hidden = !signalFlag
                
                subordinateCell.currentElementType = lvElement.typeId.integerValue // will set visibility for icons
                
                if let finishStateEnumValue = ElementFinishState(rawValue: lvElement.finishState.integerValue)
                {
                    switch finishStateEnumValue
                    {
                    case .Default:
                        //dashCell.taskIcon?.image = UIImage(named: "task-available-to-set")?.imageWithRenderingMode(.AlwaysTemplate)
                        subordinateCell.taskIcon?.image = nil
                        break
                    case .InProcess:
                        subordinateCell.taskIcon?.image = UIImage(named: "tile-task-pending")?.imageWithRenderingMode(.AlwaysTemplate)
                    case .FinishedBad:
                        subordinateCell.taskIcon?.image = UIImage(named: "tile-task-bad")?.imageWithRenderingMode(.AlwaysTemplate)
                    case .FinishedGood:
                        subordinateCell.taskIcon?.image = UIImage(named: "tile-task-good")?.imageWithRenderingMode(.AlwaysTemplate)
                    }
                }
                
            }
            return subordinateCell
        }
    }
    
    func elementIsOwned() -> Bool
    {
        if let element = self.handledElement
        {
            return element.isOwnedByCurrentUser()
        }
        return false
    }
    
    func indexPathForAttachesCell() -> NSIndexPath?
    {
        if let options = currentCellsOptions
        {
            let orderedOptions = options.orderedOptions
            var indexPath:NSIndexPath?
            for var i = 0; i < orderedOptions.count; i++
            {
                let currentCellType = orderedOptions[i]
                if currentCellType == ElementCellType.Attaches
                {
                    indexPath = NSIndexPath(forItem: i, inSection: 0)
                    break
                }
            }
            return indexPath
        }
        return nil
    }
    
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let
            subordinatesStore = self.subordinatesByIndexPath,
            lvElement = subordinatesStore[indexPath]
        {
            subordinateTapDelegate?.didTapOnElement(lvElement)
            return
        }
        
        if indexPath.item < 3
        {
            if let currentCettOptionsArray = currentCellsOptions?.orderedOptions
            {
                let cellType = currentCettOptionsArray[indexPath.item]
                
                switch cellType
                {
                    case .Title:
                            switch titleCellMode
                            {
                            case .Title:
                                titleCellMode = .Dates
                            case .Dates:
                                titleCellMode = .Title
                            }
                            
                            collectionView.reloadItemsAtIndexPaths([indexPath])
                    
                    case .Details:
                        break
                    case .Chat:
                        self.chatMessageWasTapped(nil)
                    default: break
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let aCell = cell as? SingleElementTitleCell
        {
            aCell.cleanShadow()
        }
    }
    
    
    //MARK: MessageTapDelegate
    func chatMessageWasTapped(message: Message?) {
        self.messageTapDelegate?.chatMessageWasTapped(message)
    }
    
    //MARK: External stuff
    func currentLastMessages() -> [Message]?
    {
        if let currentOptionsCellTypes = self.currentCellsOptions?.cellTypes
        {
            if currentOptionsCellTypes.contains(.Chat)
            {
                
            }
        }
        return nil
    }
    
    //MARK: - AttachCellDelegate
    func attachTappedAtIndexPath(indexPath:NSIndexPath)
    {
        if let foundAttach = attachAtIndexPath(indexPath)
        {
            self.attachTapDelegate?.attachedFileTapped(foundAttach)
        }
        else
        {
            print("\n ERROR! Tryed to tap on non existing attach file....\n")
        }
    }
    func attachesCount() -> Int
    {
        guard let lvAttaches = self.currentAttaches else
        {
            return 0
        }
        return lvAttaches.count
    }
    func titleForAttachmentAtIndexPath(indexPath:NSIndexPath) -> String?
    {
        guard let _ = self.currentAttaches else
        {
            return nil
        }
        
        guard let foundAttach = attachAtIndexPath(indexPath) else{
            return nil
        }
        
        return foundAttach.fileName
    }
    
    func imageForAttachmentAtIndexPath(indexPath:NSIndexPath) -> UIImage?
    {
        guard let foundAttach = attachAtIndexPath(indexPath) else {
            return nil
        }
        
        if let previewImageDataDict = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(foundAttach), imageData =  previewImageDataDict[foundAttach]
        {
            return UIImage(data:imageData)
        }
        return UIImage(named: "icon-No-Image")
    }
    
    private func attachAtIndexPath(indexPath:NSIndexPath) -> AttachFile?
    {
        if let foundAttach = self.currentAttaches?[indexPath.row]
        {
            return foundAttach
        }
        return nil
    }
    
    //external
    func deleteAttachNamed(name:String)
    {
        guard let attaches = self.currentAttaches else
        {
            return
        }
        
        var lvIndexPath:NSIndexPath?
        var currentItem = 0
        for anAttach in attaches
        {
            guard let fileName = anAttach.fileName else
            {
                currentItem += 1
                continue
            }
            if fileName == name
            {
                lvIndexPath = NSIndexPath(forItem: currentItem, inSection: 0)
                break
            }
            currentItem += 1
        }
        
        if let pathToRemove = lvIndexPath
        {
            self.currentAttaches?.removeAtIndex(pathToRemove.item)
            if let collectionView = self.handledCollectionView
            {
                collectionView.reloadSections(NSIndexSet(index:0))
                return
            }
            print(" ---- -- - - - - - -\n -_ --_ -")
        }
    }
}
