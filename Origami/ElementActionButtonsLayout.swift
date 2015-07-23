//
//  ElementActionButtonsLayout.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementActionButtonsLayout: UICollectionViewFlowLayout {
   
    private let actionButtonSideDimension = CGFloat(50.0) //change this to change buttons size
    private let interButtonSpace = CGFloat(10.0)

    convenience init?(buttonTypes:[ActionButtonCellType]?)
    {
        self.init()
        if buttonTypes == nil
        {
            return nil
        }
        if buttonTypes!.isEmpty
        {
            return nil
        }
        self.buttonTypes = buttonTypes
        self.itemSize = CGSizeMake(actionButtonSideDimension, actionButtonSideDimension)
        self.minimumInteritemSpacing = interButtonSpace
        self.minimumLineSpacing = interButtonSpace
        self.sectionInset = UIEdgeInsetsZero
    }
    
    private var buttonTypes:[ActionButtonCellType]?
    private var layoutAttributes:[NSIndexPath:UICollectionViewLayoutAttributes]?
    private var sizeOfContent:CGSize = CGSizeMake(280, 120) //this will change of course :-)
    override func collectionViewContentSize() -> CGSize {
        return sizeOfContent
    }
    
    override func invalidateLayout() {
        super.invalidateLayout()
        layoutAttributes?.removeAll(keepCapacity: true)
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        calculateLayoutAttributes()
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        if let oldBounds = self.collectionView?.bounds
        {
            if oldBounds.size != newBounds.size
            {
                return true
            }
            return false
        }
        return true
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]?
    {
        var currentAttributes = [UICollectionViewLayoutAttributes]()
        
        for (_,lvAttribute) in self.layoutAttributes!
        {
            if CGRectIntersectsRect(lvAttribute.frame, rect)
            {
                currentAttributes.append(lvAttribute)
            }
        }
        return currentAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        if let attributes = layoutAttributes, attribute = attributes[indexPath]
        {
            return attribute
        }
        return super.layoutAttributesForItemAtIndexPath(indexPath)
    }
    
    func calculateLayoutAttributes() // create attributes with frames in "chess board" order
    {
        if let buttons = buttonTypes
        {
            var screenWidth = UIScreen.mainScreen().bounds.size.width
            if let collection = self.collectionView
            {
                screenWidth = collection.bounds.size.width
            }
            
            if layoutAttributes == nil
            {
                layoutAttributes = [NSIndexPath : UICollectionViewLayoutAttributes]()
            }
            else
            {
                layoutAttributes!.removeAll(keepCapacity: true)
            }
            
            let buttonsCount = buttons.count
            
            var offsetX:CGFloat = self.minimumInteritemSpacing
            var offsetY:CGFloat = self.minimumLineSpacing
            var indexPathItem = 0
            for var i = 0; i < buttonsCount * 2; i++
            {
                var frame = CGRectMake(offsetX, offsetY , actionButtonSideDimension , actionButtonSideDimension)
                offsetX += actionButtonSideDimension  //+ self.minimumInteritemSpacing
                
                if screenWidth < CGRectGetMaxX(frame)
                {
                    println(" Counting second row for action buttons cell")
                    offsetX =  actionButtonSideDimension
                    offsetY += self.minimumLineSpacing + actionButtonSideDimension
                    frame.origin.x = offsetX
                    frame.origin.y = offsetY
                }
                
                
                if i & 1 == 0 //i % 2 == 0
                {
                    println("  button frame: \(frame)")
                    let indexPath = NSIndexPath(forItem: indexPathItem, inSection: 0)
                    var attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                    
                    layoutAttributes![indexPath] = attributes
                    
                    attributes.frame = frame
                    if indexPathItem == 7 //last frame, last layout attribute
                    {
                        self.sizeOfContent = CGSizeMake(CGRectGetMaxX(frame) + self.minimumInteritemSpacing, CGRectGetMaxY(frame) + self.minimumLineSpacing)
                        break
                    }
                    //else we proceed to iterate
                    indexPathItem++
                }
                
            }
        }
    }
}
