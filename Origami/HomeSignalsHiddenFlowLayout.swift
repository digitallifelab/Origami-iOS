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
    
//    var privSignals:Int = 0
//    var privFavourites:[Element]?
//    var privOther:[Element]?
    
//    convenience init(signals:Int, favourites:[Element]?, other:[Element]?)
//    {
//        self.init()
//        
//        self.scrollDirection = .Vertical
//        self.headerReferenceSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, 30.0)
//        self.privSignals = signals
//        self.privFavourites = favourites
//        self.privOther = other
//    }
    private var layoutInfoStruct:HomeLayoutStruct?
    
    convenience init(layoutInfoStruct:HomeLayoutStruct)
    {
        self.init()
        self.scrollDirection = .Vertical
        self.headerReferenceSize = CGSizeMake(UIScreen.mainScreen().bounds.size.width, 30.0)
        self.layoutInfoStruct = layoutInfoStruct
    }
    
//    required init?(coder aDecoder: NSCoder)
//    {
//        super.init(coder: aDecoder)
//    }
    
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
    
    func clearAllElements()
    {
//        privSignals = 0
//        privOther?.removeAll(keepCapacity: false)
//        privFavourites?.removeAll(keepCapacity: false)
        
        layoutInfoStruct = nil
    }
    
    func configureAttributes()
    {
        var viewWidth = UIScreen.mainScreen().bounds.size.width - 10.0
        
        if #available (iOS 8.0, *)
        {
            
        }
        else
        {
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
        }
        
        
        var headerSize = self.headerReferenceSize
        if headerSize.height < 30.0
        {
            headerSize.height = 30.0
        }
        
        var offsetX:CGFloat = self.minimumInteritemSpacing
        var offsetY:CGFloat = self.minimumLineSpacing
        
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
            
            //print("header attributes: \(headerAttributes!.count)")
            
            //move down
            offsetY += sectionHeaderAttributes.frame.size.height + self.minimumLineSpacing
            
            //create attributes for element cells
            var numberOfItemsInSection = 0
            
            switch section
            {
            case 0:
                //TODO: debug and change datasource numberOfItemsInSection:   for returnin 2 cells only - signalButtonCell and HomeLastMesagesCell
                numberOfItemsInSection = max(countOfSignals + 1, 2) //TODO: 2
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
                let indexPathForItem = NSIndexPath(forItem: currentItem, inSection: section)
                
                let itemAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPathForItem)
                
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
                        itemAttributes.hidden = true
                        cellAttributes![indexPathForItem] = itemAttributes
                    }
                }
                else if section > 0
                {
                    if countOfSections < 3
                    {
                        if let currentElementSize = layoutInfoStruct?.other?[currentItem]
                        {
                            if currentElementSize == .Wide
                            {
                                elementWidth = HomeCellWideDimension
                            }
                        }
                    }
                    else
                    {
                        if let currentElementSize = (section == 1) ? layoutInfoStruct?.favourites?[currentItem] : layoutInfoStruct?.other?[currentItem]
                        {
                            if currentElementSize == .Wide
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
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        let superForIndexPath = super.layoutAttributesForItemAtIndexPath(indexPath)
        if let existingItemAttrs =  cellAttributes?[indexPath]
        {
            return  existingItemAttrs
        }

        return superForIndexPath
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        if elementKind == UICollectionElementKindSectionHeader
        {
            //print("Header requested index path: \(indexPath.section) - \(indexPath.item)")
            if let headerAttrs = headerAttributes?[indexPath]
            {
                return headerAttrs
            }
            else
            {
                //print("returning SUPER HEADER attributes for indexPath: \(indexPath)")
//                let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
//                return superAttrs
                return nil
            }
        }
        
        return nil
//        else
//        {
//            //print("returning SUPER FOOTER attributes for indexPath: \(indexPath)")
//            let superAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
//            return superAttrs
//        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        //print("\(rect)")
        /*if*/ //let superAttrs = super.layoutAttributesForElementsInRect(rect)
        //{
            var existingAttrs = [UICollectionViewLayoutAttributes]()
            
            if let cellAttrs = cellAttributes
            {
                for (_ , cellAttr) in cellAttrs
                {
                    if CGRectIntersectsRect(rect, cellAttr.frame)
                    {
                        existingAttrs.append(cellAttr)
                    }
                }
            }
            
            if let headerAttrs = headerAttributes
            {
                for (_, headerAttr) in headerAttrs
                {
                    if CGRectIntersectsRect(rect, headerAttr.frame)
                    {
                        existingAttrs.append(headerAttr)
                    }
                }
            }
           
            
            if existingAttrs.isEmpty
            {
                //print(" returning NIL instaed of >>>SUPER<<<< attributes fo rect: \(rect),  \n \(superAttrs)")
                return nil
            }
            
            return existingAttrs
        //}
        
        //return nil
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
    
    //MARK: - 
    class func prepareLayoutStructWithInfo(info:dashboardDBElementsInfoTuple) -> HomeLayoutStruct
    {
        print("--LAYOUT--")
        var signalsDimensionsArray = [ElementItemLayoutWidth]()
        var favouritesDimensionsArray = [ElementItemLayoutWidth]()
        var otherElementDimensionsArray = [ElementItemLayoutWidth]()
        
        if let signals = info.signals
        {
            //print("SIGNALS:")
            for aSignalBDelement in signals
            {
                //print("->")
                if let elementId = aSignalBDelement.elementId?.integerValue, let subordinatesQueryResult = DataSource.sharedInstance.localDatadaseHandler?.readSubordinateElementsForDBElementIdSync(elementId)
                {
                    if subordinatesQueryResult.count > 0
                    {
                        //print(" -> WIDE")
                        signalsDimensionsArray.append(ElementItemLayoutWidth.Wide)
                        continue
                    }
                    //print(" ->NORMAL")
                    signalsDimensionsArray.append(ElementItemLayoutWidth.Normal)
                    continue
                }
                print(" -> ERROR SIGNAL <- ")
            }
        }
        
        if let favs = info.favourites
        {
            //print("FAVOURITES:")
            for aFavBDelement in favs
            {
                //print("->")
                if let elementId = aFavBDelement.elementId?.integerValue, let subordinatesQueryResult = DataSource.sharedInstance.localDatadaseHandler?.readSubordinateElementsForDBElementIdSync(elementId)
                {
                    if subordinatesQueryResult.count > 0
                    {
                        //print(" -> WIDE")
                        favouritesDimensionsArray.append(ElementItemLayoutWidth.Wide)
                        continue
                    }
                    favouritesDimensionsArray.append(ElementItemLayoutWidth.Normal)
                    continue
                }
                print(" -> ERROR FAV <- ")
            }
        }
        
        if let other = info.other
        {
            //print("OTHER:")
            for anOtherBDelement in other
            {
                //print("->")
                if let elementId = anOtherBDelement.elementId?.integerValue, let subordinatesQueryResult = DataSource.sharedInstance.localDatadaseHandler?.readSubordinateElementsForDBElementIdSync(elementId)
                {
                    if subordinatesQueryResult.count > 0
                    {
                        //print(" ->WIDE")
                        otherElementDimensionsArray.append(ElementItemLayoutWidth.Wide)
                        continue
                    }
                    //print(" ->NORMAL")
                    otherElementDimensionsArray.append(ElementItemLayoutWidth.Normal)
                    continue
                }
                print(" -> ERROR OTHER <- ")
            }
        }
        
        let homeLayoutStruct = HomeLayoutStruct(signalsCount: signalsDimensionsArray.count, favourites: favouritesDimensionsArray, other: otherElementDimensionsArray)
        
        return homeLayoutStruct

    }
}