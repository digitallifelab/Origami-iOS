//
//  HomeSignalsHiddenFlowLayout.swift
//  Origami
//
//  Created by CloudCraft on 09.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class HomeSignalsHiddenFlowLayout:UICollectionViewFlowLayout
{
    var cellAttributes:  [NSIndexPath : UICollectionViewLayoutAttributes]?
    var headerAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]?
    
    //override contentSize function
    private var sizeOfContent = CGSizeZero
    override func collectionViewContentSize() -> CGSize
    {
        return sizeOfContent
    }
    //override minimumInteritemSpacing property
    private var minimumItemSpasing:CGFloat = HomeCellHorizontalSpacing
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
    
    //override itemSize property
    private var sizeOfItem:CGSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
    override var itemSize:CGSize{
        get{
            return sizeOfItem
        }
        set(newSize){
            sizeOfItem = newSize
        }
    }
    
    var privSignals:Int = 0
    var privFavourites:[Element]?// = [Element]()
    var privOther:[Element]? //= [Element]()
    
    init(signals:Int, favourites:[Element]?, other:[Element]?)
    {
        super.init()
        self.scrollDirection = .Vertical
        //self.minimumLineSpacing = 5.0
        //self.minimumInteritemSpacing = 5.0
        self.itemSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
        self.headerReferenceSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, 30.0)
        self.privSignals = signals
        self.privFavourites = favourites
        self.privOther = other
        
        //println(" ------- Hidden Layout initialized with \(self.privSignals) signals")
        
        //self.configureAttributes()
    }
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func prepareLayout()
    {
        super.prepareLayout()
        configureAttributes()
    }
    
    override func invalidateLayout()
    {
        self.cellAttributes?.removeAll(keepCapacity: true)
        self.headerAttributes?.removeAll(keepCapacity: true)
        
        super.invalidateLayout()
    }
    
    func configureAttributes()
    {
        var viewWidth = UIScreen.mainScreen().bounds.size.width - 10.0
        
        
        if FrameCounter.isLowerThanIOSVersion("8.0")
        {
            let currentIdiom = FrameCounter.getCurrentInterfaceIdiom()
//            if currentIdiom == .Phone
//            {
                var currentWidth = UIScreen.mainScreen().bounds.size.width
                var currentHeight = UIScreen.mainScreen().bounds.size.height
                
                let currentDeviceOrentation = FrameCounter.getCurrentDeviceOrientation()
                switch currentDeviceOrentation
                {
                case UIInterfaceOrientation.Unknown:
                    break
                case UIInterfaceOrientation.Portrait:
                    fallthrough
                case UIInterfaceOrientation.PortraitUpsideDown:
                    break
                case UIInterfaceOrientation.LandscapeLeft:
                    fallthrough
                case UIInterfaceOrientation.LandscapeRight:
                    currentWidth = currentHeight
                    currentHeight = UIScreen.mainScreen().bounds.size.width - 10
                    viewWidth = currentWidth
                }
//            }
        }

        
        
        
        var headerSize = self.headerReferenceSize
        if headerSize.height < 30.0
        {
            headerSize.height = 30.0
        }
        
        var offsetX:CGFloat = self.minimumInteritemSpacing
        var offsetY:CGFloat = self.minimumLineSpacing
        
        /* - fix top offset in iPhone 6,5,4- */
        
        let comparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
        
        switch comparisonResult
        {
        case .OrderedSame, .OrderedDescending:
            let currentTraitCollection = FrameCounter.getCurrentTraitCollection()
            let currentTraitCollectionWidth = currentTraitCollection.horizontalSizeClass
            let currentTraitCollectionHeight = currentTraitCollection.verticalSizeClass
            if currentTraitCollectionWidth == .Compact && currentTraitCollectionHeight == .Compact
            {
                offsetY += 40.0
            }
        case .OrderedAscending:
            offsetY += 0.0
        }
        
        
     
       
        /*---------*/
        
        if cellAttributes == nil
        {
            cellAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        }
        if headerAttributes == nil
        {
            headerAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
        }
        
        var countOfSections = 0
        if privSignals > 0
        {
            countOfSections += 1
        }
        if let favs = privFavourites
        {
            if favs.count > 0
            {
                countOfSections += 1
            }
        }
        if let other = privOther
        {
            if other.count > 0
            {
                countOfSections += 1
            }
        }
        
        for var section = 0; section < countOfSections; section++
        {
            offsetX = self.minimumInteritemSpacing
            //create frame for header of section
            let indexPathForSection = NSIndexPath(forItem: 0, inSection: section)
            var sectionHeaderAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withIndexPath: indexPathForSection)
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
                
                if section == 0
                {
                    let itemFrame = CGRectMake(offsetX, offsetY, self.itemSize.width, self.itemSize.height)
                    
                    if currentItem == 0
                    {
                        itemAttributes.zIndex = 1000
                        itemAttributes.frame = itemFrame
                        cellAttributes![indexPathForItem] = itemAttributes
                    }
                    else if currentItem == 1 //MessagesHolderCell
                    {
                        itemAttributes.zIndex = 500
                        
                        var messagesCellFrame = CGRectOffset(itemFrame, itemFrame.size.width + self.minimumItemSpasing, 0)
                        messagesCellFrame.size.width = HomeCellWideDimension
                        while CGRectGetMaxX(messagesCellFrame) > viewWidth - 5
                        {
                            messagesCellFrame.size.width -= 5
                        }
                        
                        itemAttributes.frame = messagesCellFrame
                        cellAttributes![indexPathForItem] = itemAttributes
                    }
                    else
                    {
                        itemAttributes.zIndex = itemAttributes.indexPath.item
                        itemAttributes.frame = itemFrame
                        cellAttributes![indexPathForItem] = itemAttributes
                    }
                }
                else if section > 0
                {
                    if countOfSections < 3
                    {
                        if let currentElement = privOther?[currentItem]
                        {
                            if !DataSource.sharedInstance.getSubordinateElementsForElement(currentElement.elementId?.integerValue).isEmpty
                            {
                                elementWidth = HomeCellWideDimension
                            }
                        }
                    }
                    else
                    {
                        if let currentElement = (section == 1) ? privFavourites?[currentItem] : privOther?[currentItem]
                        {
                            if !DataSource.sharedInstance.getSubordinateElementsForElement(currentElement.elementId?.integerValue).isEmpty
                            {
                                elementWidth = HomeCellWideDimension
                            }
                        }
                    }
                    
                    if (elementWidth + offsetX + self.minimumInteritemSpacing) > viewWidth //move to next row if we cannot place two elements together
                    {
                        offsetX = self.minimumInteritemSpacing
                        offsetY += self.itemSize.height + self.minimumLineSpacing
                    }
                    
                    let itemFrame = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                    itemAttributes.frame = itemFrame
                    
                    cellAttributes![indexPathForItem] = itemAttributes
                    
                    offsetX += elementWidth + self.minimumInteritemSpacing
                }
            }
            //move down
            let height = self.itemSize.height + self.minimumLineSpacing
            offsetY += height
        }
        
        //ret bottomFrame
        var bottom:CGFloat = 0
        for (_,attribute) in self.cellAttributes!
        {
            let lvBottom:CGFloat = CGRectGetMaxY(attribute.frame)
            if lvBottom > bottom
            {
                bottom = lvBottom
            }
        }
        
        let contentSizeLocal = CGSizeMake(viewWidth, bottom)
        self.sizeOfContent = contentSizeLocal
        
    }
    
    override  func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if let oldBounds = self.collectionView?.bounds
        {
            if oldBounds.size.width != newBounds.size.width //when device is rotated
            {
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
//        else
//        {
//            //println("Cell attributes is null.  Returning super attributes.")
//        }
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
        //println("\(rect)")
        if let superAttrs = super.layoutAttributesForElementsInRect(rect)
        {
            var existingAttrs = [UICollectionViewLayoutAttributes]()
            
//            for attr in superAttrs
//            {
//                let currentElementCategory = attr.representedElementCategory.rawValue
//                
//                switch currentElementCategory
//                {
//                case UICollectionElementCategory.Cell.rawValue:
//                    if let existingItemAttr = cellAttributes?[attr.indexPath]
//                    {
//                        existingAttrs.append(existingItemAttr)
//                    }
//                case UICollectionElementCategory.SupplementaryView.rawValue:
//                    if attr.representedElementKind == UICollectionElementKindSectionHeader
//                    {
//                        if let existingHeader = headerAttributes?[attr.indexPath]
//                        {
//                            existingAttrs.append(existingHeader)
//                        }
//                    }
//                case UICollectionElementCategory.DecorationView.rawValue:
//                    break
//                default:
//                    break
//                }
//            }
            
            if let cellAttrs = cellAttributes
            {
                for (_ , cellAttr) in cellAttributes!
                {
                    if CGRectIntersectsRect(rect, cellAttr.frame)
                    {
                        existingAttrs.append(cellAttr)
                    }
                }
            }
            
            if let headerAttrs = headerAttributes
            {
                for (_, headerAttr) in headerAttributes!
                {
                    if CGRectIntersectsRect(rect, headerAttr.frame)
                    {
                        existingAttrs.append(headerAttr)
                    }
                }
            }
           
            
            if existingAttrs.isEmpty
            {
                //println(" returning >>>SUPER<<<< attributes fo rect: \(rect),  \n \(superAttrs)")
                return superAttrs
            }
            
            return existingAttrs
        }
        
        return nil
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