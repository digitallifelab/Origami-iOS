//
//  CustomLayout.swift
//  Origami
//
//  Created by CloudCraft on 15.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit




///------------------------------------------///
///--                                     ---///
///------------------------------------------///
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
    
    var privSignals:Int = 0
    var privFavourites:[Element]?
    var privOther:[Element]?
    init(signals:Int, favourites:[Element]?, other:[Element]?)
    {
        super.init()
        
        self.scrollDirection = .Vertical
//        self.minimumLineSpacing = 5.0
//        self.minimumInteritemSpacing = 5.0
        self.itemSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
        self.headerReferenceSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, 30.0)
        self.privSignals = signals
        self.privFavourites = favourites
        self.privOther = other
        
        //self.configureAttributes()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
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
            if oldBounds != newBounds
            {
                cellAttributes?.removeAll(keepCapacity: false)
                headerAttributes?.removeAll(keepCapacity: false)
                cellAttributes = nil
                headerAttributes = nil
                
                return true
            }
        }
        return false
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes!
    {
        var superForIndexPath = super.layoutAttributesForItemAtIndexPath(indexPath)
        if let existingItemAttrs =  cellAttributes?[indexPath]
        {
            superForIndexPath = existingItemAttrs
        }
        else
        {
            //println("Cell attributes is null.  Returning super attributes.")
        }
        return superForIndexPath
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes!
    {
        if elementKind == UICollectionElementKindSectionHeader
        {
            if let headerAttrs = headerAttributes?[indexPath]
            {
                return headerAttrs
            }
            else
            {
                //println("returning SUPER HEADER attributes for indexPath: \(indexPath)")
                let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
                return superAttrs
            }
        }
        else
        {
            //println("returning SUPER FOOTER attributes for indexPath: \(indexPath)")
            let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
            return superAttrs
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]?
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
                    if let existingItemAttr = self.cellAttributes?[attr.indexPath]
                    {
                        existingAttrs.append(existingItemAttr)
                    }
                case UICollectionElementCategory.SupplementaryView.rawValue:
                    if attr.representedElementKind == UICollectionElementKindSectionHeader
                    {
                        if let existingHeader = self.headerAttributes?[attr.indexPath]
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
            
            existingAttrs.filter({ (attributeToCheck) -> Bool in
                if rect.intersects(attributeToCheck.frame)
                {
                    return true
                }
                return false
            })
            
            if existingAttrs.isEmpty
            {
                //println(" returning >>>SUPER<<<< attributes fo rect: \(rect),  \n \(superAttrs)")
                return superAttrs
            }
            
            //println(" returning <<<EXISTING>>> attributes fo rect: \(rect)")
//            for attr in existingAttrs
//            {
//                println("\n kind: \(attr.representedElementKind), frame: \(attr.frame)\n")
//            }
            return existingAttrs
            
        }
        
        return nil
    }

    //MARK: ------
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
        /* - fix top offset in iPhone 6,5,4- */
        let currentTraitCollection = FrameCounter.getCurrentTraitCollection()
        let currentTraitCollectionWidth = currentTraitCollection.horizontalSizeClass
        let currentTraitCollectionHeight = currentTraitCollection.verticalSizeClass
        if currentTraitCollectionWidth == .Compact && currentTraitCollectionHeight == .Compact
        {
            offsetY += 40.0
        }
        /*---*/
        
        if let collectionDataSource = self.collectionView?.dataSource
        {
            if cellAttributes == nil
            {
                cellAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
            }
            if headerAttributes == nil
            {
                headerAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
            }
            
            
            var countOfSections = 1
            if privFavourites!.count > 0
            {
                countOfSections += 1
            }
            if privOther!.count > 0
            {
                countOfSections += 1
            }
            
            for var section = 0; section < countOfSections; section++
            {
                offsetX = self.minimumInteritemSpacing
                //create frame for header of section
                let indexPathForSection = NSIndexPath(forItem: 0, inSection: section)
                var sectionHeaderAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withIndexPath: indexPathForSection)
                let headerFrame = CGRectMake(0.0, offsetY, self.headerReferenceSize.width, self.headerReferenceSize.height)
                sectionHeaderAttributes.frame = headerFrame
                
                self.headerAttributes![indexPathForSection] = sectionHeaderAttributes
                
                //move down
                offsetY += sectionHeaderAttributes.frame.size.height + self.minimumLineSpacing
                
                //create attributes for element cells
                var numberOfItemsInSection = 0
                switch section
                {
                case 0:
                    numberOfItemsInSection = max(privSignals + 1, 1)
                case 1:
                    if countOfSections == 2
                    {
                       numberOfItemsInSection = privOther?.count ?? 0
                    }
                    else if countOfSections == 3
                    {
                        numberOfItemsInSection = privFavourites?.count ?? 0
                    }
                case 2:
                    numberOfItemsInSection = privOther?.count ?? 0
                default:
                    numberOfItemsInSection = 0
                }
                
                for var currentItem = 0; currentItem < numberOfItemsInSection; currentItem++
                {
                    let indexPathForItem = NSIndexPath(forItem: currentItem, inSection: section)
                    
                    var itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPathForItem)
                    
                    var elementWidth = self.itemSize.width
                    
                    if section > 0 //we need to detect different widths wor Home screen cells
                    {
                        if countOfSections < 3
                        {
                            if let currentElement = privOther?[currentItem]
                            {
                                if !DataSource.sharedInstance.getSubordinateElementsForElement(currentElement.elementId).isEmpty
                                {
                                    elementWidth *= 2
                                }
                            }
                        }
                        else
                        {
                            if let currentElement = (section == 1) ? privFavourites?[currentItem] : privOther?[currentItem]
                            {
                                if !DataSource.sharedInstance.getSubordinateElementsForElement(currentElement.elementId).isEmpty
                                {
                                    elementWidth *= 2
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
                            
                            self.cellAttributes![indexPathForItem] = itemAttributes
                            offsetX += elementWidth + self.minimumInteritemSpacing
                        }
                        else if indexPathForItem.item == 1 //MessagesHolderCell
                        {
                            let maximumMessagesCellWidth = max(elementWidth * 2, viewWidth - elementWidth * 2 - minimumInteritemSpacing)
                            let messagesCellFrame = CGRectMake(viewWidth - maximumMessagesCellWidth + minimumInteritemSpacing, offsetY, maximumMessagesCellWidth, self.itemSize.height)
                            
                            let itemFrame = CGRectMake(viewWidth - elementWidth * 2 , offsetY, elementWidth * 2, self.itemSize.height)
                            itemAttributes.frame = CGRectOffset(itemFrame, itemFrame.size.width * 2, 0)
                            
                            self.cellAttributes![indexPathForItem] = itemAttributes
                        }
                        else
                        {
                            let itemFrame = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                            itemAttributes.frame = itemFrame
                            self.cellAttributes![indexPathForItem] = itemAttributes
                            
                            offsetX += elementWidth + self.minimumInteritemSpacing
                        }
                    }
                    else
                    {
                        let itemFrame = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                        itemAttributes.frame = itemFrame

                        self.cellAttributes![indexPathForItem] = itemAttributes

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

