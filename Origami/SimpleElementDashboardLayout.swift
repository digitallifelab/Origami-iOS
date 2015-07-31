//
//  SimpleElementDashboardLayout.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//



/*

This is default layout for element view - no subgrouping subordnate elements into groups as in Home Screen (no "All", "Favourites", "Signals")

*/

import UIKit

enum SubordinateItemLayoutWidth
{
    case Normal
    case Wide
}

struct ElementDetailsStruct
{
    var title:String
    var details:String?
    var messagesPreviewCell:Bool = false
    var buttonsCell:Bool = true
    var attachesCell:Bool = true
    var subordinates:[SubordinateItemLayoutWidth]?
    
    init(title:String, details:String?, messagesCell:Bool?, buttonsCell:Bool?, attachesCell:Bool?, subordinateItems:[SubordinateItemLayoutWidth]?)
    {
        self.title = title
        self.details = details
        if messagesCell != nil
        {
            self.messagesPreviewCell = messagesCell!
        }
        if buttonsCell != nil
        {
            self.buttonsCell = buttonsCell!
        }
        if attachesCell != nil
        {
            self.attachesCell = attachesCell!
        }
        if subordinateItems != nil
        {
            if !subordinateItems!.isEmpty
            {
                self.subordinates = subordinateItems
            }
        }
    }
}


class SimpleElementDashboardLayout: UICollectionViewFlowLayout {
   
    private var elementStruct:ElementDetailsStruct?
    private var cellLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    //private var headerLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    
    private var sizeOfContent:CGSize = CGSizeZero
    
    //failable initializer
    convenience init?(infoStruct:ElementDetailsStruct?)
    {
        self.init()
      
        if infoStruct == nil
        {
            return nil
        }
        self.elementStruct = infoStruct!
        self.minimumInteritemSpacing = HomeCellHorizontalSpacing
        self.minimumLineSpacing = HomeCellVerticalSpacing
        
        self.itemSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
    }
    
    override init() {
        self.cellLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        //self.headerLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        super.init()
    }

    required init(coder aDecoder: NSCoder) {
        
        self.cellLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        //self.headerLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        super.init(coder: aDecoder)
    }
    
    override func collectionViewContentSize() -> CGSize {
        return sizeOfContent
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        cellLayoutAttributes.removeAll(keepCapacity: true)
        //headerLayoutAttributes.removeAll(keepCapacity: true)
    }
    
    override func prepareLayout() {
        if cellLayoutAttributes.isEmpty// || headerLayoutAttributes.isEmpty
        {
            performLayoutCalculating()
        }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes!
    {
        var superForIndexPath = super.layoutAttributesForItemAtIndexPath(indexPath)
        
        if let existingItemAttrs = cellLayoutAttributes[indexPath]
        {
            superForIndexPath = existingItemAttrs
        }
        
        return superForIndexPath
    }
    
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        
        var attributesToReturn = [UICollectionViewLayoutAttributes]()
        for ( _ , attribute ) in cellLayoutAttributes
        {
            if CGRectIntersection(rect, attribute.frame) != CGRectZero
            {
                attributesToReturn.append(attribute)
            }
        }
        if !attributesToReturn.isEmpty
        {
            return attributesToReturn
        }
        
        return nil
    }
    
//    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes!
//    {
//        if elementKind == UICollectionElementKindSectionHeader
//        {
//            if let headerAttrs = headerLayoutAttributes[indexPath]
//            {
//                return headerAttrs
//            }
//            else
//            {
//                let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
//                return superAttrs
//            }
//        }
//        else
//        {
//            let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
//            return superAttrs
//        }
//    }
    
    func performLayoutCalculating()
    {
        let currentScreenInfo = FrameCounter.getCurrentTraitCollection()
        
        var twoColumnDisplay = false
        let currentScreenWidth = UIScreen.mainScreen().bounds.size.width
        var itemMargin = self.minimumInteritemSpacing
        var itemWidth = currentScreenWidth //- itemMargin
        
        if currentScreenInfo.horizontalSizeClass == .Regular // ipads ans iphone6+ in landscape mode
        {
            if currentScreenWidth > 700
            {
                twoColumnDisplay = true
                itemMargin = self.minimumInteritemSpacing * 3
                itemWidth = currentScreenWidth / 2 - itemMargin
            }
        }
        
        let mainFrameWidth = currentScreenWidth// - self.minimumInteritemSpacing * 2
        let mainFrame = CGRectMake(0.0, 0, mainFrameWidth, 100)// the height is not important
        
        var offsetX = mainFrame.origin.x
        var offsetY = mainFrame.origin.y
        
        
        
        let titleFrame = CGRectMake(offsetX, offsetY, mainFrame.width, 150.0) //TODO: change height to proper value. 150 is test value
        let titleIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        var attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: titleIndexPath)
        attribute.frame = titleFrame
        cellLayoutAttributes[titleIndexPath] = attribute
        
        offsetX = CGRectGetMaxX(titleFrame)
        let checkOffset = checkCurrentCellOffset(offsetX, frame: mainFrame)
        if checkOffset < offsetX
        {
            offsetX = checkOffset
            offsetY += titleFrame.size.height // + 10
        }
        
        var itemIndex = 1 //because title in already stored in cellLayoutAttributes  fith indexpath 0-0
        
        if let privateStruct = elementStruct
        {
            if privateStruct.messagesPreviewCell
            {
                let messagesIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                
                if twoColumnDisplay
                {
                    offsetX += (itemWidth + self.minimumInteritemSpacing)
                }
                var messagesFrame = CGRectMake(offsetX, offsetY, itemWidth, 132.0) //TODO: change to proper height messages cell
                var messagesAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: messagesIndexPath)
                messagesAttribute.frame = messagesFrame
                cellLayoutAttributes[messagesIndexPath] = messagesAttribute
                itemIndex += 1
                
                offsetY += CGRectGetHeight(messagesFrame); println("moved down from MESSAGES cell")
                
                
                offsetX = checkCurrentCellOffset(offsetX, frame: mainFrame)
            }
            
            if let detailsString = privateStruct.details
            {
                if !detailsString.isEmpty
                {
                    offsetX = mainFrame.origin.x
                    let detailsIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                    var detailsFrame = CGRectMake(offsetX, offsetY, mainFrameWidth, 120.0) //TODO: calculate details height
                    if CGRectGetMaxX(detailsFrame) > mainFrameWidth
                    {
                        offsetY += detailsFrame.size.height
                        detailsFrame.origin = CGPointMake(offsetX, offsetY)
                    }
                    var detailsAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: detailsIndexPath)
                    detailsAttribute.frame = detailsFrame
                    cellLayoutAttributes[detailsIndexPath] = detailsAttribute
                    itemIndex += 1
                    
                    offsetY += CGRectGetHeight(detailsFrame); println("moved down from DETAILS cell")
                    
                    if twoColumnDisplay
                    {
                        offsetX += (itemWidth + self.minimumInteritemSpacing)
                    }
                    
                    offsetX = checkCurrentCellOffset(offsetX, frame: mainFrame)
                }
                else
                {
                    println("\n -> Will not calculate leyout for empty details collectiobView cell <- ")
                }
                
            }
            
            if privateStruct.attachesCell
            {
                // attaches will be wull screen width
                offsetX = mainFrame.origin.x
                let attachesFrame = CGRectMake(offsetX, offsetY, mainFrame.size.width, 80.0) //TODO: tweak attaches cell frame height properly
                let attachesIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                var attachesAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: attachesIndexPath)
                attachesAttribute.frame = attachesFrame
                cellLayoutAttributes[attachesIndexPath] = attachesAttribute
                itemIndex += 1
                
                offsetY += attachesFrame.size.height; println("Moved Down after ATTACHes cell")
            }
            
            if privateStruct.buttonsCell
            {
                let buttonsIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                var buttonsFrame = CGRectMake(offsetX, offsetY, mainFrameWidth, 110.0) //TODO: calculate or hardcode proper buttons cell width
                if CGRectGetMaxX(buttonsFrame) > mainFrameWidth
                {
                    offsetX = mainFrame.origin.x
                    buttonsFrame.origin.x = offsetX
                }
                var buttonsAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: buttonsIndexPath)
                buttonsAttribute.frame = buttonsFrame
                cellLayoutAttributes[buttonsIndexPath] = buttonsAttribute
                itemIndex += 1
                
                if twoColumnDisplay
                {
                    offsetX += (itemWidth + self.minimumInteritemSpacing)
                }
                let checkOffsetX = checkCurrentCellOffset(offsetX, frame: mainFrame)
                
                if checkOffsetX < offsetX
                {
                    offsetX = checkOffsetX
                    offsetY += CGRectGetHeight(buttonsFrame); println("moved down left after BUTTONS cell")
                }
            }
            
            if let subordinateData = privateStruct.subordinates
            {
                offsetX = self.minimumInteritemSpacing
                offsetY += self.minimumLineSpacing + HomeCellNormalDimension
                println("moved to left, and down for 10 points. ...  Starting to calculate subordinates..")
                
                let subordinatesCount = subordinateData.count
                
                for var i = 0; i < subordinatesCount; i++
                {
                    let currentSubordinateData = subordinateData[i]
                    
                    //check item width
                    var subordinateSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
                    if currentSubordinateData == .Wide
                    {
                        subordinateSize.width = HomeCellWideDimension
                    }
                    
                    // create and store frame
                    let subordinateIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                    let cellFrame = CGRectMake(offsetX, offsetY, subordinateSize.width, subordinateSize.height)
                    var subordinateAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: subordinateIndexPath)
                    subordinateAttribute.frame = cellFrame
                    cellLayoutAttributes[subordinateIndexPath] = subordinateAttribute
                    itemIndex += 1
                    
                    //create origin for next item
                    offsetX = CGRectGetMaxX(cellFrame) + self.minimumInteritemSpacing // move to right
                    
                    // detect if next frame with this offset will be still visible
                    let checkOffset = checkCurrentCellOffset(offsetX, frame: mainFrame)
                    if checkOffset < offsetX
                    {
                        offsetX = self.minimumInteritemSpacing
                        offsetY += (CGRectGetHeight(cellFrame) + self.minimumLineSpacing)
                        println("Movet to left ant down after SUBORDINATE  cell")
                    }
                }
                
                println("\n Finished calculating subordinates")
            }
            
        }
        
        
        // detect downmost frame
        
        var lastIndexPath:NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        for (indexpath, _) in cellLayoutAttributes
        {
            if indexpath.item > lastIndexPath.item
            {
                lastIndexPath = indexpath
            }
        }
        
        let lastAttribute = cellLayoutAttributes[lastIndexPath]
        
        self.sizeOfContent = CGSizeMake(CGRectGetMaxX(lastAttribute!.frame), CGRectGetMaxY(lastAttribute!.frame) + self.minimumLineSpacing * 2)
        println("self.collectionViewContentSize()  should return \(sizeOfContent)")
    }
    
    private func checkCurrentCellOffset(offset:CGFloat, frame:CGRect) -> CGFloat
    {
        var newOffset = offset
        if offset > frame.size.width / 2.0
        {
            newOffset = frame.origin.x
            println("\n -> Moved to Left...")
        }
        
        return newOffset
    }
    
}
