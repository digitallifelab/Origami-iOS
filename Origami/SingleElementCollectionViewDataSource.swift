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
            
        }
    }
    var currentCellsOptions:ElementCellsOptions?
    var attachesHandler:ElementAttachedFilesCollectionHandler?
    
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
        let messages = DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: handledElement?.elementId, lastMessageId: nil)
        
        if messages.isEmpty
        {
            return nil
        }
        
        return messages
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
    
    //MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let options = currentCellsOptions
        {
            let counter =  options.countOptions
            return counter
        }
        return 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let orderedOptions = currentCellsOptions?.orderedOptions
        {
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
            return titleCell
        case .Chat:
            var chatCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementChatPreviewCell", forIndexPath: indexPath) as! SingleElementLastMessagesCell
            return chatCell
        case .Details:
            var detailsCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementDetailsCell", forIndexPath: indexPath) as! SingleElementDetailsCell
            return detailsCell
        case .Attaches:
            var attachesHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementAttachesHolderCell", forIndexPath: indexPath) as! SingleElementAttachesCollectionHolderCell
            return attachesHolderCell
        case .Buttons:
            var buttonsHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementButtonsHolderCell", forIndexPath: indexPath) as! SingleElementButtonsCell
            return buttonsHolderCell
        case .Subordinates:
            var subordinateCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementSubordinateCell", forIndexPath: indexPath) as! DashCell
            return subordinateCell
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
