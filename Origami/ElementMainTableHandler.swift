//
//  ElementMainTableHandler.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementMainTableHandler: NSObject, UITableViewDelegate, UITableViewDataSource, ButtonTapDelegate, ElementTextEditingDelegate
{
    var handledElement:Element?
    
    var elementTapDelegate:ElementSelectionDelegate?
    var elementTextViewEditingDelegate:ElementTextEditingDelegate?
    var buttonTapDelegate:ButtonTapDelegate?
    var displayMode:DisplayMode = .Day
    var handledTableView:UITableView = UITableView()
        {
        didSet{
            descriptionFullSize = preCalculateDescriptionTextViewFullTextSize(false)
            descriptionFullSize.height += 40
            //descriprionLessHeight = /*(UIScreen.mainScreen().traitCollection.horizontalSizeClass == .Regular) ? 60.0 : */ 100.0
            titleRowHeight = max(preCalculateDescriptionTextViewFullTextSize(true).height, 50)
        }
    }
    
    var lastMessagesTableHandler:ElementChatPreviewTableHandler?
    var subordinateElementsCollectionHandler:ElementSubordinatesCollectionHandler?
    private var privateAttachesHandler: ElementAttachedFilesCollectionHandler?
    
    var attachesCollectionHandler:ElementAttachedFilesCollectionHandler?
        {
        get
        {
            return privateAttachesHandler
        }
        set(newHandler)
        {
            privateAttachesHandler = newHandler
        }
    }
    
    var sectionTitles:[String] = [String]()
    var moreOrLessButonTitle:String = "More"
    var showDescriptionMore:Bool = false
    private var isElementEditing = false
    var elementIsOwned:Bool = false
    var descriptionFullSize:CGSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width - 10.0, 100.0)
    // /__Height of rows that change height__/
    var descriptionLessHeight:CGFloat = 100.0
    
    var titleRowHeight:CGFloat = 50.0
    var messagesRowHeight:CGFloat = 100.0
    var descriptionRowHeight:CGFloat = 50.0
    var attachesRowHeight:CGFloat = 100.0
    var subordinatesRowHeight:CGFloat = 0
    var currentNumberOfRowsInAttachesSection = 0
    // /_____________________________________/
    private let datesArrowDownImage = UIImage(named:"icon-more")
    private let datesArrowUpImage = UIImage(named:"icon-less")
    
    convenience init(element:Element)
    {
        self.init()
        self.handledElement = element
        if let creatorOfElement = element.creatorId
        {
            self.elementIsOwned = (element.creatorId!.integerValue == DataSource.sharedInstance.user!.userId!.integerValue)
        }
        
        if let layout = ElementSubordinatesSimpleLayout(elements: DataSource.sharedInstance.getSubordinateElementsForElement(self.handledElement!.elementId))
        {
            layout.countContentSizeWithoutCollectionView()
            
            self.subordinatesRowHeight = layout.collectionViewContentSize().height + 10
        }
        
    }
    
    func preCalculateDescriptionTextViewFullTextSize(forTitle:Bool) -> CGSize {
        if forTitle
        {
            if let titleFont = UIFont(name: "Segoe UI", size: 24.0)
            {
                let toReturn = FrameCounter.calculateFrameForTextViewWithFont(titleFont, text: handledElement!.title! as String, targetWidth: handledTableView.bounds.size.width)
                return toReturn
            }
            return CGSizeZero
        }
        else
        {
            let lvTextView = UITextView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width - 20.0, 100.0))
            lvTextView.font = UIFont(name: "Segoe UI", size: 14.0)
            
            let toReturn = FrameCounter.calculateFrameForTextViewWithFont(lvTextView.font, text: handledElement!.details! as String, targetWidth: handledTableView.bounds.size.width)
            if toReturn.height < descriptionLessHeight
            {
                descriptionLessHeight = toReturn.height + 10
            }
            return toReturn
        }
    }
    
    
    func reloadChatMessagesSection()
    {
        if let chatContainerCell = handledTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection:1)) as? ElementDashboardChatPreviewCell
        {
            handledTableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: .None)
        }
        else
        {
            handledTableView.insertSections(NSIndexSet(index: 1), withRowAnimation: .None)
        }
    }
    
    func reloadSubordinateElementsCell()
    {
        self.subordinateElementsCollectionHandler = nil
        self.handledTableView.reloadData()
    }
    
    func displayAttachesTableCellIfNeeded ()
    {
        var attachmentsSectionIndex:Int? = sectionIndexForAttachmentsHolderCell()
        
        if attachmentsSectionIndex != nil
        {
            if attachesCollectionHandler!.attachedItems.count > 0 //THE "IfNeeded" PART
            {
                handledTableView.reloadSections(NSIndexSet(index: attachmentsSectionIndex!), withRowAnimation: .None)
            }

        }
        else
        {
            handledTableView.reloadData() //reloads to add new section with attached files cell after VC`s loading attaches.
        }
        
    }
    
//    func getBreadcrumbsTitles() -> [String]
//    {
//        if self.handledElement != nil
//        {
//            return DataSource.sharedInstance.getRootElementTitlesFor(handledElement!)
//        }
//        return [String]()
//    }
    
    func getLastChatMessages() ->[Message]?
    {
        if self.handledElement != nil
        {
            let lvMessages = DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: handledElement!.elementId!, lastMessageId: nil)
            println("Last chat messages count: \(lvMessages!.count)")
            return lvMessages
        }
        return nil
    }
    
    
    func getDatesDetails() -> [String:String]
    {
        var toReturn = [String:String]()
        if self.handledElement != nil
        {
            if let dateCreated = self.handledElement!.createDate as? String
            {
                toReturn["created"] = dateCreated
            }
            if let dateModified = self.handledElement!.changeDate as? String
            {
                toReturn["modified"] = dateModified
            }
            if let dateArchived = self.handledElement!.archiveDate as? String
            {
                toReturn["archived"] = dateArchived
            }
            if let dateFinished = self.handledElement!.finishDate, stringDateFinished = dateFinished.timeDateString() as? String
            {
                toReturn["finished"] = stringDateFinished
            }
        }
        return toReturn
    }
    
    func getElementTitle() -> String?
    {
        return self.handledElement?.title as? String
    }
    
    func getElementDescription() -> String?
    {
        return self.handledElement?.details as? String
    }
    
    func getMessagePreviewHandler() -> ElementChatPreviewTableHandler?
    {
        return ElementChatPreviewTableHandler(messages: getLastChatMessages())
    }
    
    func getAttachFilesHandler() -> ElementAttachedFilesCollectionHandler?
    {
        if self.attachesCollectionHandler != nil
        {
            return self.attachesCollectionHandler!
        }
        
        if self.handledElement != nil
        {
            let attaches = DataSource.sharedInstance.getAttachesForElementById(handledElement?.elementId)
            if let attachesCollectionHandler = ElementAttachedFilesCollectionHandler(items: attaches)
            {
                return attachesCollectionHandler
            }
            else if isElementEditing
            {
                return ElementAttachedFilesCollectionHandler() // if there is no attached files, but user fants to add an attach file - we have to return some empty collection handler to properly display tableview`s header
            }
        }
        
        return nil
    }
    
    func getSubordinatesCollectionHandler() -> ElementSubordinatesCollectionHandler?
    {
        if self.handledElement != nil
        {
            let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(self.handledElement!.elementId!)
            
            return ElementSubordinatesCollectionHandler(subordinates: subordinates)
        }
        return nil
    }
    
    func countNumberOfSections() -> Int
    {
        var numberOfSections:Int = 0 // buttons cell, dates cell for dates tableview
        sectionTitles.removeAll(keepCapacity: true)
        
        if let title = getElementTitle()
        {
            sectionTitles.append(ElementTableCellType.TitleCell.rawValue)
            numberOfSections += 1
        }
        
        if lastMessagesTableHandler != nil //no need to get last chat messages again (in future will reload  chat preview table when new messages appear)
        {
            sectionTitles.append(ElementTableCellType.ChatTableCell.rawValue)
            numberOfSections += 1
        }
        //logic moved to ElementDashboardVC ViewController - to observe messages loading finished if no messages currently available
//        else
//        {
//            let lastMessages = getLastChatMessages()
//            if let messagesHandler = ElementChatPreviewTableHandler(messages: lastMessages) // will fail  if lastMessages.isEmpty == true
//            {
//                lastMessagesTableHandler = messagesHandler
//                sectionTitles.append(ElementTableCellType.ChatTableCell.rawValue)
//                toReturn += 1
//            }
//        }
        
        
        if let description = getElementDescription()
        {
            sectionTitles.append(ElementTableCellType.DescriptionCell.rawValue)
            numberOfSections += 1
        }
        
//        if attachesCollectionHandler != nil // no need to get attaches again from DataSource
//        {
//            sectionTitles.append(ElementTableCellType.AttachesHolderCell.rawValue)
//            toReturn += 1
//        }
//        else
//        {
        if let attachesHandler = getAttachFilesHandler()
        {
            attachesCollectionHandler = attachesHandler
            sectionTitles.append(ElementTableCellType.AttachesHolderCell.rawValue)
            numberOfSections += 1
        }
    
        sectionTitles.append(moreOrLessButonTitle) // section header will contain button to display or hide dates - creation, changed, ended..
        numberOfSections += 1
        
        sectionTitles.append(ElementTableCellType.ActionButtonsCell.rawValue) //cell will display buttons to start editing element, changing IsSignal, adding new element...
        numberOfSections += 1
        
        if subordinateElementsCollectionHandler != nil // no need to reload all subordinate elements again (for now. In future will reload, when notification from server will be recieved)
        {
            sectionTitles.append(ElementTableCellType.SubordinatesHolderCell.rawValue)
            numberOfSections += 1
        }
        else
        {
            if let subordinatesHandler = getSubordinatesCollectionHandler()
            {
                subordinateElementsCollectionHandler = subordinatesHandler
                sectionTitles.append(ElementTableCellType.SubordinatesHolderCell.rawValue)
                numberOfSections += 1
            }
        }
       
        
        //println("Titles for Element table: \(sectionTitles)")
        
        return numberOfSections
    }
    
    func sectionIndexForAttachmentsHolderCell() -> Int?
    {
        var sectionIndex:Int? = nil
        let sectionsCount = sectionTitles.count
        
        for var i = 0; i < sectionsCount; i++ //detect attaches collection view holder cell`s indexPath
        {
            let sectionTitle = sectionTitles[i]
            if sectionTitle == ElementTableCellType.AttachesHolderCell.rawValue
            {
                sectionIndex = i
                break
            }
        }
        
        return sectionIndex
    }
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return countNumberOfSections()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var numberOfRows:Int = 0
        if let targetSectionTitle = self.tableView(tableView, titleForHeaderInSection: section)
        {
            switch targetSectionTitle
            {
            case ElementTableCellType.TitleCell.rawValue:
                numberOfRows = 1
            case ElementTableCellType.ChatTableCell.rawValue:
                numberOfRows = 1 // Cell holds tableview inside it
            case ElementTableCellType.DescriptionCell.rawValue:
                numberOfRows = 1
            case ElementTableCellType.AttachesHolderCell.rawValue:
                numberOfRows = (attachesCollectionHandler!.attachedItems.count > 0) ? 1 : 0
                currentNumberOfRowsInAttachesSection = numberOfRows
            case ElementTableCellType.DatesCellMore.rawValue:
                numberOfRows = 0
            case ElementTableCellType.DatesCellLess.rawValue:
                var dateCellsCount = 0
                if self.handledElement!.createDate != nil
                {
                    numberOfRows += 1
                }
                if self.handledElement!.changeDate != nil
                {
                    numberOfRows += 1
                }
                if self.handledElement!.finishDate != nil
                {
                    numberOfRows += 1
                }
               
            case ElementTableCellType.ActionButtonsCell.rawValue:
                numberOfRows = 1
            case ElementTableCellType.SubordinatesHolderCell.rawValue:
                numberOfRows = 1
            default:
                break
            }
        }
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var toReturnCell:UITableViewCell = UITableViewCell()
        
        switch indexPath.section
        {
            case 0:
                toReturnCell = returnElementTitleCellForIndexPath(indexPath, titleText: getElementTitle(), tableView: tableView)
            case 1:
                if self.lastMessagesTableHandler != nil // second row - chat
                {
                    toReturnCell = returnElementChatPreviewCellCellForIndexPath(indexPath, chatDataSource: self.lastMessagesTableHandler!, tableView: tableView)
                }
                else if let description = getElementDescription() //second row - description
                {
                    toReturnCell = returnElementDescriptionCellForIndexPath(indexPath, tableView: tableView, descriptionText: description)
                }
                else if self.attachesCollectionHandler != nil //second row - attaches
                {
                    toReturnCell = returnElementAttachesCellForIndexPath(indexPath, tableView: tableView, attachesSource: self.attachesCollectionHandler!)
                }
                else //second row - dates
                {
                    let datesCell = returnElementDatesCellForIndexPath(indexPath, tableView: tableView)
                    
                    toReturnCell = datesCell
                }
            case 2:
                if self.lastMessagesTableHandler != nil  //this means second cell shows chat messages
                {
                    if let lvDescription = getElementDescription()
                    {
                        toReturnCell = returnElementDescriptionCellForIndexPath(indexPath, tableView: tableView, descriptionText: lvDescription)
                    }
                    else  if self.attachesCollectionHandler != nil
                    {
                        toReturnCell = returnElementAttachesCellForIndexPath(indexPath, tableView: tableView, attachesSource: self.attachesCollectionHandler!)
                    }
                    else
                    {
                        let lvCell = returnElementDatesCellForIndexPath(indexPath, tableView: tableView) as ElementDashboardDatesCell
                        //configureDateCellForRow(indexPath.row, cell: &lvCell)
                        toReturnCell = lvCell
                    }
                }
                else if let description = getElementDescription() //this means second cell shows element description
                {
                    if self.attachesCollectionHandler != nil
                    {
                        toReturnCell = returnElementAttachesCellForIndexPath(indexPath, tableView: tableView, attachesSource: self.attachesCollectionHandler!)
                    }
                    else if self.lastMessagesTableHandler != nil
                    {
                        toReturnCell = returnElementButtonsCellForIndexPath(indexPath, tableView: tableView, element: self.handledElement!)
                    }
                    else
                    {
                        let lvCell = returnElementDatesCellForIndexPath(indexPath, tableView: tableView) as ElementDashboardDatesCell
                        toReturnCell = lvCell
                    }
                }
            case 3: //this means that at least chat messages cell or descripion cell is displayed
                if self.lastMessagesTableHandler != nil
                {
                    if self.attachesCollectionHandler != nil
                    {
                        let lvCell = returnElementAttachesCellForIndexPath(indexPath, tableView: tableView, attachesSource: self.attachesCollectionHandler!)
                        toReturnCell = lvCell
                    }
                    else
                    {
                        let lvCell = returnElementDatesCellForIndexPath(indexPath, tableView: tableView) as ElementDashboardDatesCell
                        toReturnCell = lvCell
                    }
                }
                else if self.attachesCollectionHandler != nil
                {
                    
                    toReturnCell =  returnElementDatesCellForIndexPath(indexPath, tableView: tableView) as ElementDashboardDatesCell//returnElementAttachesCellForIndexPath(indexPath, tableView: tableView, attachesSource: self.attachesCollectionHandler!)
                }
                else if self.lastMessagesTableHandler != nil
                {
                    let lvCell = returnElementDatesCellForIndexPath(indexPath, tableView: tableView) as ElementDashboardDatesCell
                    //configureDateCellForRow(indexPath.row, cell: &lvCell)
                    toReturnCell = lvCell
                }
                else
                {
                    toReturnCell = returnElementButtonsCellForIndexPath(indexPath, tableView: tableView, element: self.handledElement!)
                }
            case 4:
                var checker:Int = 0
                if self.lastMessagesTableHandler != nil
                {
                    checker += 1
                }
                if self.attachesCollectionHandler != nil
                {
                    checker += 1
                }
                if getElementDescription() != nil
                {
                    checker += 1
                }
                if checker < 2
                {
                    toReturnCell = returnElementSubordinatesCellForIndexPath(indexPath, tableView: tableView, subordinatesSource: self.subordinateElementsCollectionHandler!)
                }
                else if checker == 2
                {
                    toReturnCell = returnElementButtonsCellForIndexPath(indexPath, tableView: tableView, element: self.handledElement!)
                }
                else
                {
                    let lvCell = returnElementDatesCellForIndexPath(indexPath, tableView: tableView) as ElementDashboardDatesCell
                    //configureDateCellForRow(indexPath.row, cell: &lvCell)
                    toReturnCell = lvCell
                }
            case 5:
                if self.lastMessagesTableHandler != nil && getElementDescription() != nil && self.attachesCollectionHandler != nil
                {
                    toReturnCell = returnElementButtonsCellForIndexPath(indexPath, tableView: tableView, element: self.handledElement!)
                }
                else if self.subordinateElementsCollectionHandler != nil
                {
                    toReturnCell = returnElementSubordinatesCellForIndexPath(indexPath, tableView: tableView, subordinatesSource: self.subordinateElementsCollectionHandler!)
                }
            case 6:
                if self.subordinateElementsCollectionHandler != nil
                {
                    toReturnCell = returnElementSubordinatesCellForIndexPath(indexPath, tableView: tableView, subordinatesSource: self.subordinateElementsCollectionHandler!)
                }
            default:
                toReturnCell = UITableViewCell(style: .Value1, reuseIdentifier: "EmptyCellIdentifier")
            
        }
        
        return toReturnCell
    }
    
    private func returnElementTitleCellForIndexPath(indexPath:NSIndexPath, titleText:String?, tableView:UITableView) -> ElementDashboardTextViewCell
    {
        let titleCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath:indexPath) as! ElementDashboardTextViewCell
        titleCell.textView.hidden = false
        titleCell.displayMode = self.displayMode
        if titleText != nil
        {
            titleCell.textView.attributedText = makeAttributedTextFor(titleText!)
        }
        else
        {
            titleCell.textView.text = getElementTitle()
        }
        titleCell.showsMoreButton = false
        titleCell.isTitleCell = true
        titleCell.lessTextLabel.hidden = true
        titleCell.shouldEditTextView = self.isElementEditing
        titleCell.editingDelegate = self//(self.isElementEditing) ? self : nil
        
        titleCell.favouriteIcon.tintColor = (self.handledElement!.isFavourite!.boolValue) ? kDaySignalColor : UIColor.whiteColor()
        
        return titleCell
    }
    
    private func returnElementDescriptionCellForIndexPath(indexPath:NSIndexPath, tableView:UITableView, descriptionText:String ) -> ElementDashboardTextViewCell
    {
        let descriptionCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! ElementDashboardTextViewCell
        descriptionCell.textView.attributedText = nil
        descriptionCell.displayMode = self.displayMode
        descriptionCell.textView.text = descriptionText
        descriptionCell.textView.font = UIFont(name: "Segoe UI", size: 14.0)
        //let targetHeight = self.tableView(handledTableView, heightForRowAtIndexPath: indexPath)
        descriptionCell.showsMoreButton = true
        descriptionCell.lessTextLabel.text = descriptionText
        descriptionCell.lessTextLabel.hidden = showDescriptionMore
        descriptionCell.textView.hidden = !showDescriptionMore
        //title
        let moreButtonTitle = (!showDescriptionMore) ? ElementTableCellType.DatesCellMore.rawValue : ElementTableCellType.DatesCellLess.rawValue
        descriptionCell.moreButton.setTitle(moreButtonTitle, forState: UIControlState.Normal)
        
        descriptionCell.moreDescriptionDelegate = self
        //descriptionCell.moreButton.setTitle(ElementTableCellType.DatesCellMore.rawValue, forState: UIControlState.Normal)
        descriptionCell.isTitleCell = false
        descriptionCell.shouldEditTextView = self.isElementEditing
        descriptionCell.editingDelegate = (self.isElementEditing) ? self : nil
        return descriptionCell
    }
    
    private func returnElementChatPreviewCellCellForIndexPath(indexPath:NSIndexPath, chatDataSource:ElementChatPreviewTableHandler , tableView:UITableView) -> ElementDashboardChatPreviewCell
    {
        let chatTableHolderCell = tableView.dequeueReusableCellWithIdentifier("ChatPreviewHolderCell", forIndexPath: indexPath) as! ElementDashboardChatPreviewCell
        chatTableHolderCell.chatPreviewTable.estimatedRowHeight = 50.0
        chatTableHolderCell.chatPreviewTable.rowHeight = UITableViewAutomaticDimension
        chatDataSource.displayMode = self.displayMode
        chatTableHolderCell.chatDataSource = chatDataSource
        
        return chatTableHolderCell
    }
    
    private func returnElementAttachesCellForIndexPath(indexPath:NSIndexPath, tableView:UITableView, attachesSource:ElementAttachedFilesCollectionHandler) -> ElementDashboardAttachmentCell
    {
        let attachesHandleCell = tableView.dequeueReusableCellWithIdentifier("AttachmentsCell", forIndexPath: indexPath) as! ElementDashboardAttachmentCell
        attachesHandleCell.selectionStyle = .None
        attachesHandleCell.collectionView.collectionViewLayout.invalidateLayout()
        attachesHandleCell.collectionHandler = attachesSource
        attachesHandleCell.collectionView.collectionViewLayout = AttachesCollectionViewLayout(filesCount: attachesSource.attachedItems.count)
        attachesHandleCell.collectionHandler!.collectionView = attachesHandleCell.collectionView
        attachesHandleCell.collectionView.scrollEnabled = true
        
        //attachesHandleCell.collectionView.collectionViewLayout.invalidateLayout()
    
        return attachesHandleCell
    }
    
    private func returnElementDatesCellForIndexPath(indexPath:NSIndexPath, tableView:UITableView) -> ElementDashboardDatesCell
    {
        var datesCell = tableView.dequeueReusableCellWithIdentifier("DatesTableHolderCell", forIndexPath: indexPath) as! ElementDashboardDatesCell
        datesCell.displayMode = self.displayMode
        configureDateCellForRow(indexPath.row, cell: &datesCell)
        
        return datesCell
    }
    
    private func returnElementSubordinatesCellForIndexPath(indexPath:NSIndexPath, tableView:UITableView, subordinatesSource:ElementSubordinatesCollectionHandler) -> ElementDashboardCollectionViewCell
    {
        subordinatesSource.displayMode = self.displayMode
        let subordinatesHandleCell = tableView.dequeueReusableCellWithIdentifier("ElementCollectionCell", forIndexPath: indexPath) as! ElementDashboardCollectionViewCell
        subordinatesSource.elementSelectionDelegate = elementTapDelegate // to detect tapping on subordinate element in collection view
        
        subordinatesHandleCell.collectionHandler = subordinatesSource
        //assign custom layout subclass
        if let lvLayout = ElementSubordinatesSimpleLayout(elements: subordinatesSource.dashElements)
        {
            subordinatesHandleCell.collectionView.collectionViewLayout = lvLayout
        }
        
        subordinatesHandleCell.collectionView.scrollEnabled = false
        
        return subordinatesHandleCell
    }
    
    private func returnElementButtonsCellForIndexPath(indexPath:NSIndexPath, tableView:UITableView, element:Element) -> ElementDashboardActionButtonsCell
    {
        let buttonsCell = tableView.dequeueReusableCellWithIdentifier("ActionButtonsCell", forIndexPath: indexPath) as! ElementDashboardActionButtonsCell
        buttonsCell.elementIsOwned = self.elementIsOwned
        buttonsCell.actionButtonDelegate =  self  // buttons have tags starting from 1
        var isElementSignal:Bool = (element.isSignal!.boolValue) ? true : false
        buttonsCell.signalButton?.backgroundColor = (isElementSignal) ? kDaySignalColor : UIColor.lightGrayColor()

        
        return buttonsCell
    }
    
    private func makeAttributedTextFor(elementTitle:String) -> NSAttributedString
    {
        let titleFont = UIFont(name: "Segoe UI", size: 23.0)
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        let validSpacing:CGFloat =  10//min(6, max(14,titleFont!.lineHeight / 4))
        paragraphStyle.lineSpacing = validSpacing
        paragraphStyle.maximumLineHeight = 20.0
        paragraphStyle.paragraphSpacingBefore = 5.0
        
        let textColor:UIColor = (self.displayMode == .Day) ? UIColor.blackColor() : UIColor.whiteColor()
        
        let attributes = NSDictionary(
            objectsAndKeys:textColor,
            NSForegroundColorAttributeName,
            titleFont!,
            NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName)//,
            //NSParagraphStyleAttributeName, paragraphStyle)
            as [NSObject:AnyObject]
   
        let attributedString = NSAttributedString(string: elementTitle , attributes:attributes)
        return attributedString
//        var mutableAttributed = NSMutableAttributedString(attributedString: attributedString)
//        
//       
//        
//        mutableAttributed.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableAttributed.length))
//        
//        return mutableAttributed
    }
    
    private func configureDateCellForRow(row:Int, inout cell:ElementDashboardDatesCell)
    {
        switch row
        {
            case 0:
                cell.titleLabel.text = "Created".localizedWithComment("")
                cell.dateLael.text = handledElement!.createDate?.dateFromServerDateString()?.timeDateString() as String? ?? nil
            case 1:
                cell.titleLabel.text = "Changed".localizedWithComment("")
                cell.dateLael.text = handledElement!.changeDate?.dateFromServerDateString()?.timeDateString() as String? ?? nil
            case 2:
                cell.titleLabel.text = "Finished".localizedWithComment("")
                cell.dateLael.text = handledElement!.finishDate?.timeDateString() as String? ?? nil
            default:
            break
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        let horizontalSizeClass = UIScreen.mainScreen().traitCollection.horizontalSizeClass
        if let sectionTitle = self.tableView(tableView, titleForHeaderInSection: indexPath.section)
        {
            switch sectionTitle
            {
                case ElementTableCellType.TitleCell.rawValue:
                    titleRowHeight = max(preCalculateDescriptionTextViewFullTextSize(true).height , 50)
                    return titleRowHeight
                case ElementTableCellType.ChatTableCell.rawValue:
                    switch lastMessagesTableHandler!.messageObjects.count
                    {
                    case 1:
                        return 52.0
                    case 2:
                        return 102.0
                    case 3:
                        return
                            153.0
                    default:
                        return 150.0
                    }
                case ElementTableCellType.DescriptionCell.rawValue:
//                    if horizontalSizeClass == UIUserInterfaceSizeClass.Regular
//                    {
//                        return (showDescriptionMore) ? (descriptionFullSize.height + 40.0) : descriptionLessHeight + 10.0
//                    }
//                    else
//                    {
                        return (showDescriptionMore) ? descriptionFullSize.height : descriptionLessHeight
//                    }
                
                case ElementTableCellType.AttachesHolderCell.rawValue:
                    return 90.0
                case ElementTableCellType.DatesCellLess.rawValue:
                    return 44.0
                case ElementTableCellType.ActionButtonsCell.rawValue:
                    if horizontalSizeClass == UIUserInterfaceSizeClass.Regular
                    {
                        return 75.0
                    }
                    else
                    {
                        return 105.0
                    }
                case ElementTableCellType.SubordinatesHolderCell.rawValue:
                    
                    if subordinatesRowHeight > 10
                    {
                        return subordinatesRowHeight
                    }
                    
                    let lvHeight = CGRectGetMaxY(FrameCounter.countFrameForElements(subordinateElementsCollectionHandler!.dashElements, forRectWidth: tableView.bounds.size.width).last!) + 15.0
                    return lvHeight
                
                default: break
            }
        }
        
        var returnHeight:CGFloat = 50.0
      
        return returnHeight
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if let titleForHeader = self.tableView(tableView, titleForHeaderInSection: section)
        {
            switch titleForHeader
            {
                case ElementTableCellType.DatesCellMore.rawValue:
                    fallthrough
                case ElementTableCellType.DatesCellLess.rawValue:
                    return 44.0
                case ElementTableCellType.AttachesHolderCell.rawValue:
                    if  isElementEditing {
                        return 44.0
                    }
                    else{
                        return 0.0
                    }
                default:
                    break
            }
        }
        
        return 0.0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section < sectionTitles.count
        {
            let title = sectionTitles[section]
            return title
        }
        return nil
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if let sectionTitle = self.tableView(tableView, titleForHeaderInSection: section)
        {
            switch sectionTitle
            {
                case ElementTableCellType.DatesCellLess.rawValue:
                    let mainBundle = NSBundle.mainBundle()
                    let headerFrame = CGRectMake(0, 0, tableView.bounds.size.width, 44.0)
                    let datesView = MoreButtonHolderView(frame: headerFrame)
                    datesView.button.setTitle(sectionTitle, forState: UIControlState.Normal)
                    datesView.button.setImage(datesArrowUpImage, forState: UIControlState.Normal)
                    datesView.buttonTapDelegate = self
                    return datesView
                case ElementTableCellType.DatesCellMore.rawValue:
                    let mainBundle = NSBundle.mainBundle()
                    let headerFrame = CGRectMake(0, 0, tableView.bounds.size.width, 44.0)
                    let datesView = MoreButtonHolderView(frame: headerFrame)
                    datesView.button.setTitle(sectionTitle, forState: UIControlState.Normal)
                    datesView.buttonTapDelegate = self
                    return datesView
                case ElementTableCellType.AttachesHolderCell.rawValue:
                    //let mainBudle = NSBundle.mainBundle()
                    let headerFrame = CGRectMake(0, 0, tableView.bounds.size.width, 44.0)
                    let addAttachesHeader = AttachesTableHeaderView(frame: headerFrame)
                    addAttachesHeader.titleLabel.text = "Localized Add_Attaches Header Title".localizedWithComment("")
                    addAttachesHeader.addButton.tag = ActionButtonType.AddAttachment.rawValue
                    addAttachesHeader.buttonTapDelegate = self
                    return addAttachesHeader
                default:
                    return nil
            }
           
        }
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        let row = indexPath.row
        
        if row > 0 && row < 4
        {
            if let attachCell = cell as? ElementDashboardAttachmentCell
            {
                if attachCell.collectionHandler is ElementAttachedFilesCollectionHandler
                {
                   attachCell.collectionView.reloadSections(NSIndexSet(index: 0))
                }
            }
        }
        
        if indexPath.row > 3
        {
            if let subordinatesCell = cell as? ElementDashboardCollectionViewCell
            {
                let currentHeight = self.tableView(tableView, heightForRowAtIndexPath: indexPath)
                
                var contentHeight = subordinatesCell.collectionView.collectionViewLayout.collectionViewContentSize().height
                if contentHeight <= 0
                {
                    return
                }
                
                let collectionFrameHeight = subordinatesCell.collectionView.bounds.size.height
                
                let cellContentBoundsHeight = subordinatesCell.contentView.bounds.height
                
                let collectionPositionDifference = cellContentBoundsHeight - collectionFrameHeight
                
                contentHeight += collectionPositionDifference
                
                if contentHeight > currentHeight
                {
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }
            }
        }
        
    }
    
    //MARK: ButtonsTapDelegate
    func didTapOnButton(button: UIButton) // show or hide dates for element
    {
        if button.tag > 0
        {
            if let buttonTypeEnumValue = ActionButtonType(rawValue: button.tag)
            {
                
                switch buttonTypeEnumValue
                {
                case .Edit:
                    if !elementIsOwned
                    {
                        return
                    }
                    toggleElementEditing()
                case .Add:
                    self.buttonTapDelegate?.didTapOnButton(button)
                case .Delete:
                    if !elementIsOwned
                    {
                        return
                    }
                    self.buttonTapDelegate?.didTapOnButton(button)
                case .Archive:
                    println("Archive tapped")
                case .ToggleSignal:
                    if !elementIsOwned
                    {
                        return
                    }
                    changeSignalPropertyOfCurrentElementBy(button)
                case .ToggleCheckmark:
                    println(" - Checkmark tapped")
                case .ToggleDone:
                    println(" - Done tapped")
                case .ToggleIdea:
                    println(" - Idea tapped")
                case .ToggleTask:
                    println(" - Task tapped")
                case .AddAttachment:
                    self.buttonTapDelegate?.didTapOnButton(button)
                }
            }
            return
        }
        ///–––––––––––––––––––––––––––––––––––––––––––––––––––––////
        if let buttonSuperView = button.superview?.superview
        {
            if buttonSuperView is MoreButtonHolderView
            {
                if button.titleLabel?.text == ElementTableCellType.DatesCellLess.rawValue
                {
                    let lvSectionTitles = NSArray(array: self.sectionTitles)
                    let indexOfTitle = lvSectionTitles.indexOfObject(ElementTableCellType.DatesCellLess.rawValue)
                    if indexOfTitle != NSNotFound
                    {
                        moreOrLessButonTitle = ElementTableCellType.DatesCellMore.rawValue
                        
                        handledTableView.reloadSections(NSIndexSet(index: indexOfTitle), withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                }
                else if button.titleLabel?.text == ElementTableCellType.DatesCellMore.rawValue
                {
                    let lvSectionTitles = NSArray(array: self.sectionTitles)
                    let indexOfTitle = lvSectionTitles.indexOfObject(ElementTableCellType.DatesCellMore.rawValue)
                    if indexOfTitle != NSNotFound
                    {
                        moreOrLessButonTitle = ElementTableCellType.DatesCellLess.rawValue
                       
                        let indexSet = NSIndexSet(index: indexOfTitle)
                        handledTableView.reloadSections(indexSet, withRowAnimation: UITableViewRowAnimation.Fade)
                    }
                }
                else
                {
                    assert(false, "Unknown button was tried to be handled.")
                }
            }
            else
            {
                println("show or hide description text button pressed.")
                
                for lvCell in handledTableView.visibleCells()
                {
                    if lvCell is ElementDashboardTextViewCell
                    {
                        let targetCell = lvCell as! ElementDashboardTextViewCell
                        if targetCell.showsMoreButton
                        {
                            println("Show More DETAILS tapped")
                            //get indexPath of this cell
                            if let indexPath = handledTableView.indexPathForCell(lvCell as! UITableViewCell)
                            {
                                showDescriptionMore = !showDescriptionMore
                                handledTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: ElementTextEditingDelegate
    func titleCellwantsToChangeElementIsFavourite(cell: ElementDashboardTextViewCell) {
        let currentElementCopy = createCopyOfCurrentElement()// Element(info: self.handledElement!.toDictionary() as! [String:AnyObject])

        let newFavourite = !currentElementCopy.isFavourite!.boolValue
        currentElementCopy.isFavourite = NSNumber(bool: newFavourite)
        DataSource.sharedInstance.updateElement(currentElementCopy, isFavourite: newFavourite) { [weak self] (edited) -> () in
           
            if self != nil
            {
                if edited
                {
                    self!.handledElement!.isFavourite = NSNumber(bool: newFavourite)
                    self!.handledTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
                }
                else
                {
                    // do Nothing
                }
            }
        }
//        DataSource.sharedInstance.editElement(currentElementCopy) /*trailing closure*/{ [weak self] (edited) -> () in
//            if self != nil
//            {
//                if edited
//                {
//                    self!.handledElement!.isFavourite = NSNumber(bool: newFavourite)
//                    self!.handledTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Fade)
//                }
//                else
//                {
//                    // do Nothing
//                }
//            }
//        }
     
    }

    func titleCellEditTitleTapped(cell: ElementDashboardTextViewCell) {
        if elementIsOwned && self.elementTextViewEditingDelegate != nil
        {
            self.elementTextViewEditingDelegate!.titleCellEditTitleTapped(cell)
        }
    }
    
    func descriptionCellEditDescriptionTapped(cell: ElementDashboardTextViewCell) {
        if elementIsOwned && self.elementTextViewEditingDelegate != nil
        {
            self.elementTextViewEditingDelegate!.descriptionCellEditDescriptionTapped(cell)
        }
    }
    
    //MARK: Editing Mode
    private func createCopyOfCurrentElement() -> Element
    {
        return Element(info: self.handledElement!.toDictionary())
    }
    
    func toggleElementEditing()
    {
        //println("Edit tapped")
        isElementEditing = !isElementEditing
        
        var lvPaths = [NSIndexPath]()
        for var i = 0; i < 4; i++
        {
            let lvPath = NSIndexPath(forRow: 0, inSection: i)
            lvPaths.append(lvPath)
        }
        
        if let lvAttachesHandler = self.attachesCollectionHandler
        {
            
            if attachesCollectionHandler!.attachedItems.isEmpty
            {
                if let sectionForAttaches = sectionIndexForAttachmentsHolderCell() //after user tried and cancelled adding the first attachment and pressed Edit Button - to quit editing element - delete the Attachments section
                {
                    let attachesIndexSet = NSIndexSet(index: sectionForAttaches)
                    attachesCollectionHandler = nil
                    self.handledTableView.deleteSections(attachesIndexSet, withRowAnimation: .Fade)
                }
            }
            else
            {
                self.handledTableView.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, 4)), withRowAnimation: .Fade)
            }
        }
        else
        {
           self.handledTableView.reloadData() 
        }
    }
    
    //MARK: updating Element in datasource and server
    func changeSignalPropertyOfCurrentElementBy(button:UIButton) {
    
        println("Signal tapped")
        
        var currentlySignal = self.handledElement!.isSignal!.boolValue
        currentlySignal = !currentlySignal
        
        let elementCopy = createCopyOfCurrentElement()
        elementCopy.isSignal = NSNumber(bool: currentlySignal)
        
        DataSource.sharedInstance.editElement(elementCopy, completionClosure: { [weak self, button](edited) -> () in
            if edited {
                if self != nil{
                    self!.handledElement!.isSignal = NSNumber(bool: currentlySignal)
//                    if button != nil {
                        //button.tintColor = (self!.handledElement!.isSignal!.boolValue) ? UIColor.whiteColor() : kDaySignalColor
                    var changeToRed = (self!.handledElement!.isSignal!.boolValue) ? true : false
                        button.backgroundColor =  (changeToRed) ? kDaySignalColor : UIColor.lightGrayColor()
//                    }
                }
                
            }
            else {
               //TODO: show error to user
            }
        })
    }
    
    
    
    
}
