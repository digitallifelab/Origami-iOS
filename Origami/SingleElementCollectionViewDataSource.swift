//
//  SingleElementCollectionViewDataSource.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit
import CoreData

class SingleElementCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate,  MessageTapDelegate, AttachmentCellDelegate
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
    
    var subordinatesByIndexPath:[NSIndexPath : DBElement]?
    var taskUserAvatar:UIImage?
    
    let mainQueueContext:NSManagedObjectContext
    
    override init()
    {
        self.mainQueueContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        if let privateContext = DataSource.sharedInstance.localDatadaseHandler?.getPrivateContext()
        {
            self.mainQueueContext.parentContext = privateContext
        }
        super.init()
    }
    
    weak var handledCollectionView:UICollectionView?
    
    var handledElementId:NSManagedObjectID? {
        didSet{
            guard let anID = handledElementId else
            {
                self.handledElement = nil
                return
            }
            
            if let element = self.mainQueueContext.objectWithID(anID) as? DBElement
            {
                self.mainQueueContext.refreshObject(element, mergeChanges: true)
                self.handledElement = element
            }
        }
    }
    
    private var handledElement:DBElement? {
        didSet {
            // detect visible cells by checking options
            var options:[ElementCellType] = [ElementCellType]()
            if let _ = getElementTitle()
            {
                //print("\n appended Title")
                options.append(.Title)
            }
            
            if let messages = handledElement?.messages as? Set<DBMessageChat> where messages.count > 0
            {
                options.append(.Chat)
            }
            if let details = getElementDetails()
            {
                if !details.isEmpty
                {
                    options.append(.Details)
                }
            }
            
            defer
            {
                self.currentCellsOptions = ElementCellsOptions(types: Set(options))
                
                calculateAllCellTypes()
            }
            
            if let attachesSet = self.handledElement?.attaches where attachesSet.count > 0
            {
                options.append(.Attaches)
            }
            
            if let elementObjectID = self.handledElementId, let result = DataSource.sharedInstance.localDatadaseHandler?.countSubordinatesForElementByManagedObjectId(elementObjectID) where result > 0
            {
                options.append(.Subordinates)
            }
        }
    }
    
    func getElementTitle() -> String?
    {
        if let elementTitle = handledElement?.title //as? String
        {
            return elementTitle
        }
        return nil
    }
    
    func getElementDetails() -> String?
    {
        if let elementDetails = handledElement?.details // as? String
        {
            return elementDetails
        }
        
        return nil
    }
    
    func getElementSubordinates() -> [DBElement]?
    {
        guard let elementId = self.handledElement?.elementId?.integerValue else{
            return nil
        }
        
        do
        {
            guard let elementIDs = try DataSource.sharedInstance.localDatadaseHandler?.subordinateElementsForElementId(elementId, archived: (self.handledElement?.dateArchived != nil)) else
            {
                return nil
            }
            
            var elementsToReturn = [DBElement]()
            for anElementObjectId in elementIDs
            {
                if let element = self.mainQueueContext.objectWithID(anElementObjectId) as? DBElement
                {
                    elementsToReturn.append(element)
                }
            }
            return elementsToReturn
        }
        catch
        {
            return nil
        }
    }
    
    func elementIsTask() -> Bool
    {
        if let element = self.handledElement, elementTypeInt = element.type?.integerValue
        {
            let optionsCovnerter = ElementOptionsConverter()
            return optionsCovnerter.isOptionEnabled(.Task, forCurrentOptions: elementTypeInt)
        }
        return false
    }
    
    func getLayoutInfo() -> ElementDetailsStruct?
    {
        guard let options = self.currentCellsOptions, elementTitle = self.handledElement?.title else {
            return nil
        }
        
        //prepare easy values
        
        var elementDetails:String? = self.handledElement?.details //as? String
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
        
        
        var subordinatesInfo:[ElementItemLayoutWidth]?
        //prepare subordinate cells values
        if let subordinateStore = self.subordinatesByIndexPath
        {
            //get ordered array of indexPaths for subordinates
            var allValues = Array(subordinateStore)
            allValues.sortInPlace({ (item1, item2) -> Bool in
                
                 return item1.0.item < item2.0.item  //item1 - (NSIndexPath, Element), we are interested in sorting by indexPath
            })
            
            //create array with subordinate layout characteristics
            var lvSubordinatesInfo = [ElementItemLayoutWidth]()
            for var i = 0; i < allValues.count; i++
            {
                let value = allValues[i] //again tuple
                let lvElement = value.1
                
                if /*let elementId = lvElement.elementId?.integerValue,*/ let subordinatesCount = DataSource.sharedInstance.localDatadaseHandler?.countSubordinatesForElementByManagedObjectId(lvElement.objectID, includeArchived: (self.handledElement?.dateArchived != nil))
                {
                    if subordinatesCount > 0
                    {
                        lvSubordinatesInfo.append(ElementItemLayoutWidth.Wide)
                        continue
                    }
                    
                    lvSubordinatesInfo.append(ElementItemLayoutWidth.Normal)
                    continue
                }
            }
            if !lvSubordinatesInfo.isEmpty
            {
                subordinatesInfo = lvSubordinatesInfo
            }
        }
        
        //finally
        
        let targetStruct = ElementDetailsStruct(title: elementTitle,
                                                details: elementDetails,
                                                messagesCell: messages, /* buttonsCell: buttons,*/
                                                attachesCell: attaches,
                                                subordinateItems: subordinatesInfo)
    
        return targetStruct
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
                    var lvSubordinateIndexPaths = [NSIndexPath : DBElement]()
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
                if let isFavourite = self.handledElement?.isFavourite?.boolValue
                {
                    titleCell.favourite = isFavourite
                }
                
                let titleElement = Element()
                titleElement.typeId = handledElement!.type!.integerValue
                titleElement.finishState = handledElement!.finishState!.integerValue
                titleElement.title = handledElement?.title
                if let boolFav = handledElement?.isFavourite?.boolValue
                {
                    titleElement.isFavourite = boolFav
                }
                if let signalValue = handledElement?.isSignal?.boolValue
                {
                    titleElement.isSignal = signalValue
                }
                titleElement.responsible = handledElement!.responsibleId!.integerValue
                titleElement.creatorId = handledElement!.creatorId!.integerValue
                
                if let canBeEdited = self.handledElement?.canBeEditedByCurrentUser
                {
                    titleElement.canBeEdited = canBeEdited
                }
                
                titleCell.handledElement = titleElement
                titleCell.setupActionButtons(titleElement.canBeEdited)
                //let elementIsOwnedBool = elementIsOwned()
                //titleCell.setupActionButtons(elementIsOwnedBool)
                
              
              
                if let currentelement = self.handledElement
                {
                    let responsibleIdInt = currentelement.responsibleId!.integerValue
                    let creatorId = currentelement.creatorId!.integerValue
                    
                    titleCell.responsiblePersonAvatarIcon?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)

                    if let currentUserIDInt = DataSource.sharedInstance.user?.userId
                    {
                        if responsibleIdInt > 0 //show responsible`s avatar and name
                        {
                            if creatorId == responsibleIdInt
                            {
                                if creatorId == currentUserIDInt //user sees own element in which he is responsible
                                {
                                    titleCell.responsibleNameLabel?.text = "Your Own Task"
                                }
                                else //contact`s element in which this contact is responsible
                                {
                                    if let contactsTuple = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(creatorId)
                                    {
                                        if let currentUser = contactsTuple.memory
                                        {
                                            titleCell.responsibleNameLabel?.text = currentUser.initialsString()
                                        }
                                        else if let foundContact = contactsTuple.db
                                        {
                                            titleCell.responsibleNameLabel?.text = foundContact.initialsString()
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
                                    if let aContact = DataSource.sharedInstance.localDatadaseHandler?.readContactById(responsibleIdInt)
                                    {
                                        if let contactName = aContact.nameAndLastNameSpacedString()
                                        {
                                            titleCell.responsibleNameLabel?.text = contactName
                                        }
                                    }
                                }
                            }
                            
                            
                            if let ownerAvatar = DataSource.sharedInstance.getAvatarForUserId(responsibleIdInt)
                            {
                                 titleCell.responsiblePersonAvatarIcon?.image = ownerAvatar
                            }
                        }
                        else
                        {
                            //show current user`s data
                            if creatorId == currentUserIDInt //user sees own element
                            {
                                titleCell.responsibleNameLabel?.text = "Your_Own_Element".localizedWithComment("")
                            }
                            else //contact`s data
                            {
                                if let creatorTuple = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(creatorId)
                                {
                                    if let memoryUser = creatorTuple.memory
                                    {
                                        titleCell.responsibleNameLabel?.text = memoryUser.initialsString()
                                    }
                                    else if let aContact = creatorTuple.db
                                    {
                                        titleCell.responsibleNameLabel?.text = aContact.initialsString()
                                    }
                                }
                                else
                                {
                                    titleCell.responsibleNameLabel?.text = " _ "
                                }
                                
                            }
                            //load avatar by element`s creator id
                          
                            if let ownerAvatar = DataSource.sharedInstance.getAvatarForUserId(creatorId)
                            {
                                titleCell.responsiblePersonAvatarIcon?.image = ownerAvatar
                            }
                        }
                    }
                   
                }
                
                self.titleCell = titleCell
                return titleCell
                
            case .Dates:
                let datesCell = collectionView.dequeueReusableCellWithReuseIdentifier("DateDetailsCell",
                    forIndexPath: indexPath) as! SingleElementDateDetailsCell
                datesCell.displayMode = self.displayMode
                
                let detailsElement = Element()
                detailsElement.title = handledElement?.title
                
                var info = DateDetailsStruct()
                info.dateFinished = handledElement?.dateFinished
                info.dateChanged = handledElement?.dateChanged
                info.dateCreated = handledElement?.dateCreated
                info.dateArchived = handledElement?.dateArchived
                
                if let responsibleId = handledElement?.responsibleId?.integerValue, containerTuple = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(responsibleId)
                {
                    if let user = containerTuple.memory
                    {
                        info.responsibleName = user.nameAndLastNameSpacedString()
                    }
                    else if let contact = containerTuple.db
                    {
                        info.responsibleName = contact.nameAndLastNameSpacedString()
                    }
                }
                if let creatorId = handledElement?.creatorId?.integerValue, containerTuple = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(creatorId)
                {
                    if let user = containerTuple.memory
                    {
                        info.creatorName = user.nameAndLastNameSpacedString()
                    }
                    else if let contact = containerTuple.db
                    {
                        info.creatorName = contact.nameAndLastNameSpacedString()
                    }
                }
                
                datesCell.handledElementInfo = info
                
                var owned = elementIsOwned()
                datesCell.setupActionButtons(owned)
                
                if !owned
                {
                    if  let currentElement = self.handledElement, userIdInt = DataSource.sharedInstance.user?.userId, parentElements = DataSource.sharedInstance.localDatadaseHandler?.readRootElementTreeForElementManagedObjectId(currentElement.objectID)
                    {
                        for anElement in parentElements
                        {
                            if anElement.creatorId!.integerValue == userIdInt
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
            
            if let elementId = self.handledElement?.elementId?.integerValue
            {
                dispatch_async(getBackgroundQueue_CONCURRENT(), { () -> Void in
                    DataSource.sharedInstance.localDatadaseHandler?.readLastMessagesForElementById(elementId, fetchSize: 3, completion: {[weak chatCell] (foundDBmessages, error) -> () in
                        if let messages = foundDBmessages
                        {
                            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                if let cell = chatCell, weakSelf = self
                                {
                                    cell.messages = messages
                                    cell.cellMessageTapDelegate = weakSelf
                                    cell.reloadTable()
                                }
                            })
                        }
                    })
                })
                
            }
          
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
            if let attachesHolderCell = aCell as? SingleElementAttachesCollectionHolderCell//,  _ = self.currentAttaches
            {
                attachesHolderCell.attachesCollectionView?.delegate = attachesHolderCell
                attachesHolderCell.delegate = self
                attachesHolderCell.attachesCollectionView?.dataSource = attachesHolderCell
                attachesHolderCell.attachesCollectionView?.reloadData()
                return attachesHolderCell
            }
            else
            {
                //assert(false, "Requested attaches cell for current attaches, when no attaches present")
                return UICollectionViewCell()
            }
            
        case .Subordinates:
            let subordinateCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementSubordinateCell", forIndexPath: indexPath) as! DashCell
           
            subordinateCell.displayMode = self.displayMode
            subordinateCell.cellType = .Other
            
            if let
                subordinatesStore = self.subordinatesByIndexPath,
                lvElement = subordinatesStore[indexPath]
            {
                subordinateCell.titleLabel?.text = lvElement.title
                subordinateCell.descriptionLabel?.text = lvElement.details
                subordinateCell.signalDetectorView?.hidden = true
                
                if let signalFlag = lvElement.isSignal?.boolValue
                {
                    if let signalIcon = subordinateCell.signalDetectorView
                    {
                        signalIcon.hidden = !signalFlag
                    }
                    //subordinateCell.signalDetectorView?.hidden = !signalFlag
                }
                
                if let typeId = lvElement.type?.integerValue
                {
                    subordinateCell.currentElementType = typeId // lvElement.typeId // will set visibility for icons
                }
            
                
                if let finishState = lvElement.finishState?.integerValue, finishStateEnumValue = ElementFinishState(rawValue: finishState)
                {
                    switch finishStateEnumValue
                    {
                    case .Default:
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
            lvElement = subordinatesByIndexPath?[indexPath],
            elementId = lvElement.elementId?.integerValue
        {
            subordinateTapDelegate?.didTapOnElement(elementId)
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
    
//    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        if let aCell = cell as? SingleElementTitleCell
//        {
//            aCell.cleanShadow()
//        }
//    }
    
    
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
            let attach = AttachFile()
            attach.creatorID = foundAttach.creatorId!.integerValue
            attach.attachID = foundAttach.attachId!.integerValue
            attach.fileName = foundAttach.fileName
            
            self.attachTapDelegate?.attachedFileTapped(attach)
        }
        else
        {
            print("\n ERROR! Tryed to tap on non existing attach file....\n")
        }
    }
    
    func attachesCount() -> Int
    {
        guard let lvAttaches = self.handledElement?.attaches else
        {
            return 0
        }
        return lvAttaches.count
    }
    
    func titleForAttachmentAtIndexPath(indexPath:NSIndexPath) -> String?
    {
        guard let foundAttach = attachAtIndexPath(indexPath) else
        {
            return nil
        }
        
        return foundAttach.fileName
    }
    
    func imageForAttachmentAtIndexPath(indexPath:NSIndexPath) -> UIImage?
    {
        guard let foundAttach = attachAtIndexPath(indexPath) else {
            
            return nil
        }
        
        guard let imageData = foundAttach.preview?.imagePreviewData else
        {
            if let attachFileName = foundAttach.fileName, attachId = foundAttach.attachId?.integerValue
            {
                //first check if attach file preview exists on disc
                do{
                    let previewImageData = try DataSource.sharedInstance.getAttachPreviewForFileNamed(attachFileName)
                    do
                    {
                        try DataSource.sharedInstance.localDatadaseHandler?.saveImagePreview(previewImageData, forAttachById: attachId)
                        DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext(nil)
                        if let image = UIImage(data: previewImageData)
                        {
                            return image
                        }
                    }
                    catch
                    {
                        
                    }

                }
                catch let error
                {
                    
                    print("Full size file for attach does not exist. \n \(error) \n Will try to download it.  ")
                    // if not exists = start loading preview
                    let startedLoading = DataSource.sharedInstance.downloadAttachDataForAttachById(attachId) {[weak self] (data, error) -> () in
                        if let dataLoaded = data
                        {
                            do
                            {
                                try DataSource.sharedInstance.saveAttachFileData(dataLoaded, forAttachFileName: attachFileName)
                                print(" SingleElementCollectionDataSource imageForAttachmentAtIndexPath -> \(attachFileName) saved full size image data to disk")
                                do
                                {
                                    let previewImageData = try DataSource.sharedInstance.getAttachPreviewForFileNamed(attachFileName)
                                    do{
                                        try DataSource.sharedInstance.localDatadaseHandler?.saveImagePreview(previewImageData, forAttachById: attachId)
                                        DataSource.sharedInstance.localDatadaseHandler?.savePrivateContext(){ [weak self](saveError) in
                                            if let weakSelf = self
                                            {
                                                dispatch_async(dispatch_get_main_queue()){
                                                    weakSelf.handledCollectionView?.reloadData()
                                                }
                                            }
                                        }
                                    }
                                    catch let error
                                    {
                                        print("Could not save image preview to lodac database: \n")
                                        print(error)
                                    }
                                }
                                catch let error {
                                    print("Could NOT GET ATTACH PREVIEW for attachName: \(attachFileName): \n")
                                    print(error)
                                }
                            }
                            catch let saveError
                            {
                                print("did not save loaded attach file: \(saveError)")
                            }
                        }
                        else if let downloadError = error
                        {
                            if downloadError.code == -2003 /*not exist on server*/
                            {
                                guard let weakSelf = self else
                                {
                                    return
                                }
                                weakSelf.cleanAttachById(attachId)
                            }
                        }

                    }
                print("AttachFile Downloading full image did start: \(startedLoading)")
            }
                
                
            
            }
            return kNoImageIcon
        }
        
        return UIImage(data: imageData)
    }
    
    private func attachAtIndexPath(indexPath:NSIndexPath) -> DBAttach?
    {
        if let attaches = self.handledElement?.orderedAttaches() where attaches.count > indexPath.row
        {
            let foundAttach = attaches[indexPath.row]
            return foundAttach
        }
        return nil
    }
    
    
    private func cleanAttachById(attachId: Int)
    {
        guard let databaseHandler = DataSource.sharedInstance.localDatadaseHandler else
        {
            return
        }
        do
        {
            try databaseHandler.deleteAttachById(attachId)
            
            dispatch_async(dispatch_get_main_queue()){ [weak self] in
                if let weakSelf = self
                {
                    weakSelf.handledCollectionView?.reloadData()
                }
            }
        }
        catch let deletingError
        {
            print(" SingleElementCollectionViewDataSource -> cleanAttachById -> Error: ")
            print(deletingError)
            //reload collection view in attaches cell
            dispatch_async(dispatch_get_main_queue()){ [weak self] in
                if let weakSelf = self
                {
                    weakSelf.handledCollectionView?.reloadData()
                }
            }
            
        }
    }

   
}
