//
//  ElementSubordinatesSimpleLayout.swift
//  Origami
//
//  Created by CloudCraft on 09.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class ElementSubordinatesSimpleLayout: UICollectionViewFlowLayout
{
    private var sizeOfContent:CGSize = CGSizeZero
    private var layoutAttributes:[UICollectionViewLayoutAttributes]?
    
    var collectionWidth:CGFloat?
    var countWithoutCollectionView = false
    var elementsToDisplay:[Element]?
    
    private var privateSectionInset  = UIEdgeInsetsMake(0, 5, 0, 5)
    override var sectionInset:UIEdgeInsets
        {
        get{
            return privateSectionInset
        }
        set(newInset){
            privateSectionInset = newInset
        }
    }
    
    convenience init?(elements:[Element]?)
    {
        self.init()
        if  elements == nil
        {
            return nil
        }
        if elements!.count < 1
        {
            return nil
        }
        self.minimumLineSpacing = HomeCellVerticalSpacing
        self.minimumInteritemSpacing = HomeCellHorizontalSpacing
        self.itemSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
        //self.headerReferenceSize = CGSizeMake(200.0, 30.0)
        self.elementsToDisplay = elements
        
        self.configureAttributes()
    }
    
    override func prepareLayout()
    {
        super.prepareLayout()
        if layoutAttributes == nil
        {
            configureAttributes()
        }
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        var currentAttributes = [UICollectionViewLayoutAttributes]()
        
        for lvAttribute in self.layoutAttributes!
        {
            if CGRectIntersectsRect(lvAttribute.frame, rect)
            {
                currentAttributes.append(lvAttribute)
            }
        }
        return currentAttributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        if let lvAttributeSuper = super.layoutAttributesForItemAtIndexPath(indexPath)
        {
            if layoutAttributes != nil
            {
                for lvAttribute in layoutAttributes!
                {
                    if lvAttribute.indexPath.compare(indexPath) == .OrderedSame && lvAttribute.representedElementKind != UICollectionElementKindSectionHeader
                    {
                        lvAttributeSuper.frame = lvAttribute.frame
                        break
                    }
                }
            }
            return lvAttributeSuper
        }
       
        return nil
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        if let superHeaderAttrs = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
        {
            
        }
        if self.layoutAttributes != nil
        {
            for lvAttribute in self.layoutAttributes!
            {
                if lvAttribute.representedElementKind == UICollectionElementKindSectionHeader && lvAttribute.indexPath.compare(indexPath) == .OrderedSame
                {
                    return lvAttribute
                }
            }
        }
        if let superAttributes = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath)
        {
              return superAttributes
        }
        
        return nil
    }
    
    override func collectionViewContentSize() ->CGSize
    {
        return sizeOfContent
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    private func configureAttributes()
    {
        if let collView = self.collectionView
        {
            self.configureAttributesForSimpleView()
        }
        else if countWithoutCollectionView
        {
            self.configureAttributesForSimpleView()
        }
    }
    
    private func configureAttributesForSimpleView()
    {
        if let lvElements = self.elementsToDisplay
        {
            layoutAttributes = [UICollectionViewLayoutAttributes]()
            
            collectionWidth = (countWithoutCollectionView) ? UIScreen.mainScreen().bounds.size.width - 20.0 : self.collectionView!.bounds.size.width
            
            
            
            let viewWidth = collectionWidth! - self.sectionInset.left - self.sectionInset.right//UIScreen.mainScreen().bounds.size.width - 10.0
            
            var offsetX:CGFloat = self.minimumInteritemSpacing
            var offsetY:CGFloat = self.minimumLineSpacing
            
            if !countWithoutCollectionView
            {
                if let collectionDataSourse = self.collectionView?.dataSource as? ElementSubordinatesCollectionHandler
                {
                    for var itemCount = 0; itemCount < lvElements.count; itemCount++
                    {
                        // create attributes boject with frames for cells and header views in between
                        let indexPath = NSIndexPath(forItem:itemCount , inSection: 0)
                        var attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                        
                        let element = collectionDataSourse.elementForIndexPath(attribute.indexPath)
                        var elementWidth:CGFloat = self.itemSize.width
                        let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(element.elementId!.integerValue , shouldIncludeArchived: false)
                        if !subordinates.isEmpty
                        {
                            elementWidth = HomeCellWideDimension
                        }
                        
                        if (elementWidth + offsetX) > viewWidth
                        {
                            offsetX = self.minimumInteritemSpacing
                            offsetY += self.minimumLineSpacing + self.itemSize.height
                        }
                        
                        let frameForElement = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                        attribute.frame = frameForElement
                        
                        layoutAttributes?.append(attribute)
                        
                        offsetX += (self.minimumInteritemSpacing + frameForElement.size.width)
                    }
                }
            }
            else
            {
                countWithoutCollectionView = false
                if let collectionDataSource = ElementSubordinatesCollectionHandler( subordinates: self.elementsToDisplay ?? [Element()])
                {
                    for var itemCount = 0; itemCount < lvElements.count; itemCount++
                    {
                        // create attributes boject with frames for cells and header views in between
                        let indexPath = NSIndexPath(forItem:itemCount , inSection: 0)
                        var attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                        
                        let element = collectionDataSource.elementForIndexPath(attribute.indexPath)
                        var elementWidth:CGFloat = self.itemSize.width
                        let subordinates = DataSource.sharedInstance.getSubordinateElementsForElement(element.elementId!.integerValue, shouldIncludeArchived: false)
                        if !subordinates.isEmpty
                        {
                            elementWidth = HomeCellWideDimension
                        }
                        
                        if (elementWidth + offsetX) > viewWidth
                        {
                            offsetX = self.minimumInteritemSpacing
                            offsetY += self.minimumLineSpacing + self.itemSize.height
                        }
                        
                        let frameForElement = CGRectMake(offsetX, offsetY, elementWidth, self.itemSize.height)
                        attribute.frame = frameForElement
                        
                        layoutAttributes?.append(attribute)
                        
                        offsetX += (self.minimumInteritemSpacing + frameForElement.size.width)
                    }
                }
            }
            
            self.sizeOfContent = CGSizeMake(viewWidth, CGRectGetMaxY(layoutAttributes!.last!.frame))
        }
    }
    
    private func getSortedElementsDictFromElementsArray(elements:[Element]) -> [String:[Element]]
    {
        var lvSignals = elements.filter({ (includeElement) -> Bool in  return includeElement.isSignal.boolValue == true })
        var lvFavourite = elements.filter( { (includeElement) -> Bool in return includeElement.isFavourite.boolValue == true})
        var otherSet = Set(elements).subtract( Set(lvSignals))
        var otherArray = Array(otherSet)
        
        ObjectsConverter.sortElementsByDate(&lvSignals)
        ObjectsConverter.sortElementsByDate(&lvFavourite)
        ObjectsConverter.sortElementsByDate(&otherArray)
        
        var dict = [String:[Element]]()
        if !lvSignals.isEmpty
        {
            dict["signals"] = lvSignals
        }
        if !lvFavourite.isEmpty
        {
            dict["favourite"] = lvFavourite
        }
        dict["other"] = otherArray
        return dict
    }
    
    func countContentSizeWithoutCollectionView()
    {
        countWithoutCollectionView = true
        self.configureAttributes()
    }
}
