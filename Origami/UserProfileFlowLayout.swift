//
//  UserProfileFlowLayout.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileFlowLayout: UICollectionViewFlowLayout {
    
    lazy var itemsToCalculate:Int = 0
    lazy var layoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes] =  [NSIndexPath : UICollectionViewLayoutAttributes]()
    
    private lazy var sizeOfContent:CGSize = CGSizeMake(640, 960)
    
    private var cellSize:CGSize = CGSizeMake(150.0, 100.0)
    override var itemSize:CGSize {
        get{
            return cellSize
        }
        set(newSize){
            cellSize = newSize
            self.invalidateLayout()
        }
    }
    
    private var itemSpacing:CGFloat = 10.0
    override var minimumInteritemSpacing:CGFloat {
    
        get{
            return itemSpacing
        }
        set(newSpacing){
            itemSpacing = newSpacing
            invalidateLayout()
        }
    }
    
    private var lineSpacing:CGFloat = 10.0
    override var minimumLineSpacing:CGFloat{
        get{
            return lineSpacing
        }
        set(newLineSpacing){
            lineSpacing = newLineSpacing
            invalidateLayout()
        }
    }
    
    
    override func invalidateLayout() {
        cellSize = CGSizeMake(320, 70.0)
        layoutAttributes.removeAll(keepCapacity: true)
        super.invalidateLayout()
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        
        if layoutAttributes.isEmpty
        {
            configureAttributes()
        }
    }
    
    override func collectionViewContentSize() -> CGSize {
        return sizeOfContent
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if let oldBounds = self.collectionView?.bounds
        {
            if !CGSizeEqualToSize(oldBounds.size , newBounds.size)
            {
                return true
            }
        }
        return false
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if let superAttributes = super.layoutAttributesForElementsInRect(rect)
        {
            if layoutAttributes.isEmpty
            {
                return superAttributes
            }
            else
            {
                var lvAttributesArray = [UICollectionViewLayoutAttributes]()
                
                for lvAttribute in layoutAttributes.values
                {
                    if CGRectIntersectsRect(rect, lvAttribute.frame)
                    {
                        lvAttributesArray.append(lvAttribute)
                    }
                }
                
                if lvAttributesArray.isEmpty
                {
                    return superAttributes
                }
                else
                {
                    return lvAttributesArray
                }
            }
        }
        
        return nil
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        if let existingAttribute = layoutAttributes[indexPath]
        {
            return existingAttribute
        }
        else
        {
            let superAttribute = super.layoutAttributesForItemAtIndexPath(indexPath)
            return superAttribute
        }
    }
    
    
    convenience init?(numberOfItems:Int)
    {
        self.init()
        itemsToCalculate = numberOfItems
        if self.itemsToCalculate <= 0
        {
            return nil
        }
    }
    
    
    func configureAttributes()
    {
        if let _ = self.collectionView
        {
            //prepare start values
            var contentWidth = UIScreen.mainScreen().bounds.size.width
            if FrameCounter.isLowerThanIOSVersion("8.0")
            {
                //let currentIdiom = FrameCounter.getCurrentInterfaceIdiom()
             
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
                    currentHeight = UIScreen.mainScreen().bounds.size.width
                    contentWidth = currentWidth
                }
            }
            
            cellSize.width = contentWidth //- minimumInteritemSpacing * 2
            
            var offsetY = minimumLineSpacing
            var offsetX:CGFloat = 0.0
            
            //calculate frames for cells
            
            for var i = 0; i < itemsToCalculate; i++
            {
                let indexPath = NSIndexPath(forItem: i, inSection: 0)
                let layoutAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                
                let cellWidth:CGFloat = self.itemSize.width
                
                if (offsetX + cellWidth) > contentWidth
                {
                    offsetX = 0.0
                    offsetY += self.minimumLineSpacing + self.itemSize.height
                }
                
                let frameForCell = CGRectMake(offsetX, offsetY, cellWidth, (i == 0) ?  self.itemSize.height * 3 : self.itemSize.height)
                layoutAttribute.frame = frameForCell
                
                layoutAttributes[indexPath] = layoutAttribute //store in a dictionary)
                
                offsetX += minimumInteritemSpacing + cellWidth
                if i == 0
                {
                    offsetY += self.itemSize.height * 2
                }
            }
            
            
            //get contentSize
            var frame:CGRect = CGRectZero
            for lvAttribute in layoutAttributes.values
            {
                if CGRectGetMaxY(lvAttribute.frame) > CGRectGetMaxY(frame)
                {
                    frame = lvAttribute.frame
                }
            }
            let newSize = CGSizeMake(contentWidth, CGRectGetMaxY(frame))
            sizeOfContent = newSize
        }
    }
   
}
