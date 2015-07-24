//
//  SingleElementCollectionViewDataSource.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

struct ElementCellsOptions
{
    var cellTypes:Set<ElementCellType>
    
    init()
    {
       self.cellTypes = Set([.Title, .Buttons]) //default value
    }
    
    init(types:Set<ElementCellType>)
    {
        self.cellTypes = types
    }
    
    mutating func setTypes(types:Set<ElementCellType>)
    {
        self.cellTypes = types
    }
    
    mutating func addOptions(types:Set<ElementCellType>)
    {
        self.cellTypes.unionInPlace(types)
    }
    
    var countOptions:Int {
        return self.cellTypes.count
    }
    
    var orderedOptions:[ElementCellType] {
        
        var options = Array(cellTypes)
        options.sort { (option1, option2) -> Bool in
            return option1.rawValue < option2.rawValue
        }
        return options
    }
}

class SingleElementCollectionViewDataSource: NSObject, UICollectionViewDataSource
{
    var displayMode:DisplayMode = .Day
    
    var handledElement:Element? {
        didSet {
            // detect visible cells by checking options
            var options:[ElementCellType] = [ElementCellType]()
            if let title = getElementTitle()
            {
                println("\n appended Title")
                options.append(.Title)
            }
            if let chatMessages = getElementLastMessages()
            {
                println("\n appended CHAT")
                options.append(.Chat)
            }
            if let details = getElementDetails()
            {
                println("\n appended DETAILS")
                options.append(.Details)
            }
            if let attachesCollectionHandler = getElementAttachesHandler()
            {
                println("\n appended ATTACHES")
                self.attachesHandler = attachesCollectionHandler
                options.append(.Attaches)
            }
            
            println("\n appended BUTTONS")
            options.append(.Buttons) // buttons always visible
            
            if let subordinates = getElementSubordinates()
            {
                println("\n appended Subordinates")
                options.append(.Subordinates)
            }
            
            self.currentCellsOptions = ElementCellsOptions(types: Set(options))
            
            calculateAllCellTypes()
        }
    }
    
    var currentCellsOptions:ElementCellsOptions?
    var attachesHandler:ElementAttachedFilesCollectionHandler?
    //var cellTypesHolder:[ElementCellType]?
    var subordinatesByIndexPath:[NSIndexPath : Element]?

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
        
        self.handledElement = element!
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
        if let messages = DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: handledElement?.elementId, lastMessageId: nil)
        {
            return messages
        }
        return nil
    }
    
    func getElementAttachesHandler() -> ElementAttachedFilesCollectionHandler?
    {
        let attaches =  DataSource.sharedInstance.getAttachesForElementById(handledElement?.elementId)
        
        if attaches.isEmpty
        {
            return nil
        }
        
        return ElementAttachedFilesCollectionHandler(items: attaches)
    }
    
    func getElementSubordinates() -> [Element]?
    {
        let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(handledElement?.elementId)
        
        if subordinates.isEmpty
        {
            return nil
        }
        return subordinates
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
            var messages:Bool = options.cellTypes.contains(.Chat)
            var attaches:Bool = options.cellTypes.contains(.Attaches)
            var buttons = options.cellTypes.contains(.Buttons)
            
            
            var subordinatesInfo:[SubordinateItemLayoutWidth]?
            //prepare subordinate cells values
            if let subordinateStore = self.subordinatesByIndexPath
            {
                //get ordered array of indexPaths for subordinates
                var allValues = Array(subordinateStore)
                allValues.sort({ (item1, item2) -> Bool in
                    
                     return item1.0.item < item2.0.item  //item1 - (NSIndexPath, Element), we are interested in sorting by indexPath
                })
                
                //create array with subordinate layout characteristics
                var lvSubordinatesInfo = [SubordinateItemLayoutWidth]()
                for var i = 0; i < allValues.count; i++
                {
                    let value = allValues[i] //again tuple
                    let lvElement = value.1
                    if DataSource.sharedInstance.getSubordinateElementsForElement(lvElement.elementId).count > 0
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
            let targetStruct = ElementDetailsStruct(title: elementTitle!, details: elementDetails, messagesCell: messages, buttonsCell: buttons, attachesCell: attaches, subordinateItems: subordinatesInfo)
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
            if options.cellTypes.contains(.Buttons)
            {
                cellTypes.append(.Buttons)
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
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
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
            var titleCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementTitleCell", forIndexPath: indexPath) as! SingleElementTitleCell
            
            titleCell.displayMode = self.displayMode
            
            titleCell.labelTitle.text = getElementTitle()
            
            if let isFavourite = self.handledElement?.isFavourite?.boolValue
            {
                titleCell.favourite = isFavourite
            }
            return titleCell
            
        case .Chat:
            var chatCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementChatPreviewCell", forIndexPath: indexPath) as! SingleElementLastMessagesCell
            chatCell.displayMode = self.displayMode
            if let messages = DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: self.handledElement?.elementId, lastMessageId: 0)
            {
                chatCell.messages = messages
            }
            
            return chatCell
            
        case .Details:
            var detailsCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementDetailsCell", forIndexPath: indexPath) as! SingleElementDetailsCell
            detailsCell.textLabel.text = getElementDetails()
            detailsCell.displayMode = self.displayMode
            return detailsCell
            
        case .Attaches:
            var attachesHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementAttachesHolderCell", forIndexPath: indexPath) as! SingleElementAttachesCollectionHolderCell
            return attachesHolderCell
            
        case .Buttons:
            var buttonsHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementButtonsHolderCell", forIndexPath: indexPath) as! SingleElementButtonsCell
            if let actionButtonsDataSource = ElementActionButtonsDataSource(buttonModels: createActionButtonModels())
            {
                var buttonTypes = [ActionButtonCellType]()

                for model in actionButtonsDataSource.buttons!
                {
                    buttonTypes.append(model.type)
                }
                
                buttonsHolderCell.dataSource = actionButtonsDataSource
                buttonsHolderCell.buttonsLayout = ElementActionButtonsLayout(buttonTypes: buttonTypes)
            }
            return buttonsHolderCell
        case .Subordinates:
            var subordinateCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementSubordinateCell", forIndexPath: indexPath) as! DashCell
           
            subordinateCell.displayMode = self.displayMode
            subordinateCell.cellType = .Other
            
            if let
                subordinatesStore = self.subordinatesByIndexPath,
                lvElement = subordinatesStore[indexPath]
            {
                subordinateCell.titleLabel.text = lvElement.title as? String
                subordinateCell.descriptionLabel.text = lvElement.details as? String
                subordinateCell.signalDetectorView?.hidden = true
                if let signalFlag = lvElement.isSignal
                {
                    subordinateCell.signalDetectorView?.hidden = !signalFlag.boolValue
                }
            }
            return subordinateCell
        }
    }
    
    func createActionButtonModels() -> [ActionButtonModel]?
    {
        //check
        var elementIsOwned = false
        if DataSource.sharedInstance.user!.userId!.integerValue == handledElement!.creatorId!.integerValue
        {
            elementIsOwned = true
        }
        
        //try to add models
        var toReturn = [ActionButtonModel]()
        for var i = 1; i < 9; i++
        {
            var model = ActionButtonModel()
            if let buttonType = ActionButtonCellType(rawValue: i)
            {
                model.type = buttonType
            }
            model.enabled = elementIsOwned
            toReturn.append(model)
        }
        
        //return properly
        if !toReturn.isEmpty
        {
            return toReturn
        }
        return nil
        
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
