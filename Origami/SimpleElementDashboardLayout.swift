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
    private var headerLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    
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
        self.headerLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        super.init()
    }

    required init(coder aDecoder: NSCoder) {
        
        self.cellLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        self.headerLayoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        super.init(coder: aDecoder)
    }
    
    override func collectionViewContentSize() -> CGSize {
        return sizeOfContent
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        cellLayoutAttributes.removeAll(keepCapacity: true)
        headerLayoutAttributes.removeAll(keepCapacity: true)
    }
    
    override func prepareLayout() {
        if cellLayoutAttributes.isEmpty || headerLayoutAttributes.isEmpty
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
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes!
    {
        if elementKind == UICollectionElementKindSectionHeader
        {
            if let headerAttrs = headerLayoutAttributes[indexPath]
            {
                return headerAttrs
            }
            else
            {
                let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
                return superAttrs
            }
        }
        else
        {
            let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
            return superAttrs
        }
    }
    
    func performLayoutCalculating()
    {
        
    }
    
}
