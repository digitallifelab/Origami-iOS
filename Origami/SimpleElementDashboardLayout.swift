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
    var datesCell:Bool = true
    var subordinates:[SubordinateItemLayoutWidth]?
    
    init(title:String, details:String?, messagesCell:Bool?, buttonsCell:Bool?, datesCell:Bool?, subordinateItems:[SubordinateItemLayoutWidth]?)
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
        if datesCell != nil
        {
            self.datesCell = datesCell!
        }
        if subordinateItems != nil
        {
            self.subordinates = subordinateItems
        }
    }
}


class SimpleElementDashboardLayout: UICollectionViewFlowLayout {
   
    private var elementStruct:ElementDetailsStruct?
    private var cellLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    //private var headerLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    
    private var sizeOfContent:CGSize = CGSizeMake(0, 0)
    
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
        var itemMargin = self.minimumInteritemSpacing * 2
        var itemWidth = currentScreenWidth - itemMargin
        
        if currentScreenInfo.horizontalSizeClass == .Regular // ipads ans iphone6+ in landscape mode
        {
            if currentScreenWidth > 700
            {
                twoColumnDisplay = true
                itemMargin = self.minimumInteritemSpacing * 3
                itemWidth = currentScreenWidth - itemMargin
            }
        }
        
        let mainFrameWidth = currentScreenWidth - self.minimumInteritemSpacing * 2
        let mainFrame = CGRectMake(self.minimumInteritemSpacing, self.minimumLineSpacing, mainFrameWidth, 100)// the height is not important
        
        var offsetX = mainFrame.origin.x
        var offsetY = mainFrame.origin.y
        
        
        
        let titleFrame = CGRectMake(offsetX, offsetY, mainFrame.width, 150.0) //TODO: change height to proper value. 150 is test value
        let titleIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        var attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: titleIndexPath)
        attribute.frame = titleFrame
        cellLayoutAttributes[titleIndexPath] = attribute
        
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
                var messagesFrame = CGRectMake(offsetX, offsetY, itemWidth, 150) //TODO: change to proper height messages cell
                var messagesAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: messagesIndexPath)
                messagesAttribute.frame = messagesFrame
                cellLayoutAttributes[messagesIndexPath] = messagesAttribute
                itemIndex += 1
                
                offsetY += self.minimumLineSpacing + CGRectGetWidth(messagesFrame)
                
                if offsetX > mainFrame.size.width / 2.0
                {
                    offsetX = mainFrame.origin.x
                }
            }
            
            if let detailsString = privateStruct.details
            {
                let detailsIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                let detailsFrame = CGRectMake(offsetX, offsetY, itemWidth, 150.0) //TODO: calculate details height
                
            }
        }
    
    }
    
}
