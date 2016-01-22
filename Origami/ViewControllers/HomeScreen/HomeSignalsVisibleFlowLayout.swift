//
//  CustomLayout.swift
//  Origami
//
//  Created by CloudCraft on 15.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

class HomeSignalsVisibleFlowLayout:UICollectionViewFlowLayout
{
    var cellAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]?
    var headerAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]?
    
    //override contentSize function
    private var sizeOfContent = CGSizeZero
    override func collectionViewContentSize() -> CGSize
    {
        return sizeOfContent
    }
    //override minimumInteritemSpacing property
    private var minimumItemSpasing:CGFloat = HomeCellVerticalSpacing
    override var minimumInteritemSpacing:CGFloat
        {
        get{
            return minimumItemSpasing
        }
        set(newSpace){
            minimumItemSpasing = newSpace
            self.invalidateLayout()
        }
    }
    
    //override minimumLineSpasing property
    private var minimumLineSpace:CGFloat = HomeCellVerticalSpacing
    override var minimumLineSpacing:CGFloat
        {
        get{
            return minimumLineSpace
        }
        set(newLineSpace)
        {
            minimumLineSpace = newLineSpace
            self.invalidateLayout()
        }
        
    }
    
//    var privSignals:Int = 0
//    var privFavourites:[Element]?
//    var privOther:[Element]?
//    init(signals:Int, favourites:[Element]?, other:[Element]?)
//    {
//        super.init()
//        
//        self.scrollDirection = .Vertical
////        self.minimumLineSpacing = 5.0
////        self.minimumInteritemSpacing = 5.0
//        self.itemSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
//        self.headerReferenceSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, 30.0)
//        self.privSignals = signals
//        self.privFavourites = favourites
//        self.privOther = other
//        
//        //print(" ------- Visible Layout initialized with \(self.privSignals) signals")
//    }
    
    private var layoutInfoStruct:HomeLayoutStruct?
    
    convenience init(layoutInfoStruct:HomeLayoutStruct)
    {
        self.init()
        self.scrollDirection = .Vertical
        self.headerReferenceSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, 30.0)
        self.itemSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
        self.layoutInfoStruct = layoutInfoStruct
    }
    
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//    }
    
    override func invalidateLayout()
    {
        self.cellAttributes?.removeAll(keepCapacity: true)
        self.headerAttributes?.removeAll(keepCapacity: true)
        
        super.invalidateLayout()
    }
    
    override func prepareLayout()
    {
        super.prepareLayout()
        configureAttributes()
        
    }
    //MARK: Override methods
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {

        if let oldBounds = self.collectionView?.bounds
        {
            if oldBounds.size.width != newBounds.size.width //when device is rotated
            {
                return true
            }
        }
        return false
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        var superForIndexPath = super.layoutAttributesForItemAtIndexPath(indexPath)
        if let existingItemAttrs =  cellAttributes?[indexPath]
        {
            superForIndexPath = existingItemAttrs
        }
        else
        {
            //print("Cell attributes is null.  Returning super attributes.")
        }
        return superForIndexPath
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        if elementKind == UICollectionElementKindSectionHeader
        {
            if let headerAttrs = headerAttributes?[indexPath]
            {
                return headerAttrs
            }
//            else
//            {
////                //print("returning SUPER HEADER attributes for indexPath: \(indexPath)")
////                if let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath){
////                    if !superAttrs.isEmpty {
////                        return superAttrs
////                    }
////                }
//            }
        }
        else
        {
            //print("returning SUPER FOOTER attributes for indexPath: \(indexPath)")
            if let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath){
                return superAttrs
            }
        }
        return nil
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        if let superAttrs = super.layoutAttributesForElementsInRect(rect)
        {
            var existingAttrs = [UICollectionViewLayoutAttributes]()
            
            for attr in superAttrs
            {
                let currentElementCategory = attr.representedElementCategory.rawValue
                
                switch currentElementCategory
                {
                case UICollectionElementCategory.Cell.rawValue:
                    if let existingItemAttr = cellAttributes?[attr.indexPath]
                    {
                        existingAttrs.append(existingItemAttr)
                    }
                case UICollectionElementCategory.SupplementaryView.rawValue:
                    if attr.representedElementKind == UICollectionElementKindSectionHeader
                    {
                        if let existingHeader = headerAttributes?[attr.indexPath]
                        {
                            existingAttrs.append(existingHeader)
                        }
                    }
                case UICollectionElementCategory.DecorationView.rawValue:
                    break
                default:
                    break
                }
                
            }
            
            let filtered = existingAttrs.filter({ (attributeToCheck) -> Bool in
                if rect.intersects(attributeToCheck.frame)
                {
                    return true
                }
                return false
            })
            
            if filtered.isEmpty
            {
                //print(" returning >>>SUPER<<<< attributes fo rect: \(rect),  \n \(superAttrs)")
                return superAttrs
            }
            
            return filtered
            
        }
        
        return nil
    }

    //MARK: ------
    
    func clearAllElements()
    {
        self.layoutInfoStruct = nil
    }
    
    func configureAttributes()
    {
        let viewWidth = UIScreen.mainScreen().bounds.size.width - 10.0

        var headerSize = self.headerReferenceSize
        if headerSize.height < 30.0
        {
            headerSize.height = 30.0
        }
        
        var offsetX:CGFloat = self.minimumInteritemSpacing
        var offsetY:CGFloat = self.minimumLineSpacing
        
        if let _ = self.collectionView?.dataSource
        {
            if cellAttributes == nil
            {
                cellAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
            }
            if headerAttributes == nil
            {
                headerAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
            }
            
            var countOfSections = 0
            
            var countOfSignals = 0
            var countOfFavourites = 0
            var countOfOther = 0
            if let signalsInfo = layoutInfoStruct?.signals
            {
                countOfSignals = signalsInfo.count
                if countOfSignals > 0
                {
                    countOfSections += 1
                }
            }
            if let favs = layoutInfoStruct?.favourites
            {
                countOfFavourites = favs.count
                if countOfFavourites > 0
                {
                    countOfSections += 1
                }
            }
            if let other = layoutInfoStruct?.other
            {
                countOfOther = other.count
                if countOfOther > 0
                {
                    countOfSections += 1
                }
            }
            
            
            for var section = 0; section < countOfSections; section++
            {
                offsetX = self.minimumInteritemSpacing
                //create frame for header of section
                let indexPathForSection = NSIndexPath(forItem: 0, inSection: section)
                let sectionHeaderAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withIndexPath: indexPathForSection)
                let headerFrame = CGRectMake(0.0, offsetY, self.headerReferenceSize.width, self.headerReferenceSize.height)
                sectionHeaderAttributes.frame = headerFrame
                
                headerAttributes![indexPathForSection] = sectionHeaderAttributes
                
                //move down
                offsetY += sectionHeaderAttributes.frame.size.height + self.minimumLineSpacing
                
                //create attributes for element cells
                var numberOfItemsInSection = 0
                switch section
                {
                case 0:
                    numberOfItemsInSection = max(countOfSignals + 1, 1)
                case 1:
                    if countOfSections == 2
                    {
                       numberOfItemsInSection = countOfOther
                    }
                    else if countOfSections == 3
                    {
                        numberOfItemsInSection = countOfFavourites
                    }
                case 2:
                    numberOfItemsInSection = countOfOther
                default:
                    numberOfItemsInSection = 0
                }
                
                for var currentItem = 0; currentItem < numberOfItemsInSection; currentItem++
                {
//                    print("section: \(section)")
//                    print("cell: \(currentItem)")
                    
                    let indexPathForItem = NSIndexPath(forItem: currentItem, inSection: section)
                    
                    let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPathForItem)
                    
                    var elementWidth = self.itemSize.width
                    
                    if section > 0 //we need to detect different widths wor Home screen cells
                    {
                        if countOfSections < 3
                        {
                            if let currentElementWidth = layoutInfoStruct?.other?[currentItem]
                            {
                                if currentElementWidth == .Wide{
                                    elementWidth = HomeCellWideDimension
                                }
                            }
                        }
                        else
                        {
                            if let currentElementSize = (section == 1) ? layoutInfoStruct?.favourites?[currentItem] : layoutInfoStruct?.other?[currentItem]
                            {
                                if currentElementSize == .Wide{
                                    elementWidth = HomeCellWideDimension
                                }
                            }
                        }
                    }
                    
                    if (elementWidth + offsetX + self.minimumInteritemSpacing) > viewWidth //move to next row if we cannot place two elements together
                    {
                        offsetX = self.minimumInteritemSpacing
                        offsetY += self.itemSize.height + self.minimumLineSpacing
                    }
                    
                    if indexPathForItem.section == 0
                    {
                        if indexPathForItem.item == 0
                        {
                            itemAttributes.zIndex = 1000
                            let itemFrame = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                            itemAttributes.frame = itemFrame
                            
                            cellAttributes![indexPathForItem] = itemAttributes
                            offsetX += elementWidth + self.minimumInteritemSpacing
                        }
//                        else if indexPathForItem.item == 1 //MessagesHolderCell
//                        {
//                            let itemFrame = CGRectMake(viewWidth - elementWidth * 2 , offsetY, elementWidth * 2, self.itemSize.height)
//                            itemAttributes.frame = CGRectOffset(itemFrame, itemFrame.size.width * 2, 0)
//                            
//                            cellAttributes![indexPathForItem] = itemAttributes
//                        }
                        else
                        {
                            let itemFrame = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                            itemAttributes.frame = itemFrame
                            itemAttributes.hidden = false
                                cellAttributes![indexPathForItem] = itemAttributes
                            
                            offsetX += elementWidth + self.minimumInteritemSpacing
                        }
                    }
                    else
                    {
                        let itemFrame = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                        itemAttributes.frame = itemFrame

                        cellAttributes![indexPathForItem] = itemAttributes

                        offsetX += elementWidth + self.minimumInteritemSpacing
                    }
                }
                //move down
                let height = self.itemSize.height
                offsetY += (height + self.minimumLineSpacing)
            }
            
            var bottom:CGFloat = 0
            for (_,attribute) in self.cellAttributes!
            {
                let lvBottom:CGFloat = CGRectGetMaxY(attribute.frame)
                if lvBottom > bottom
                {
                    bottom = lvBottom
                }
            }
            
            self.sizeOfContent = CGSizeMake(viewWidth, bottom)
        }
        //debug
//        if let cellAtts = self.cellAttributes
//        {
//            for (indexPath, aCellAttribute) in cellAtts
//            {
//                print("indexPath-> setion: \(indexPath.section), item: \(indexPath.item)")
//                print("frame: \(aCellAttribute.frame)")
//            }
//        }
        
      
    }
    
    // fixing collection view jump up when switching to this Layout
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint
    {
        if let collectionView = self.collectionView
        {
            let currentContentOffset = collectionView.contentOffset
            if currentContentOffset.y < proposedContentOffset.y
            {
                return currentContentOffset
            }
        }
        return proposedContentOffset
    }
}

