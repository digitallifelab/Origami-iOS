//
//  AttachesCollectionViewLayout.swift
//  Origami
//
//  Created by CloudCraft on 24.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class AttachesCollectionViewLayout: UICollectionViewFlowLayout {
    
    
    override var scrollDirection:UICollectionViewScrollDirection {
        get{
            return privScrolDirection
        }
        set(newDirection) {
            privScrolDirection = newDirection
        }
    }
    
    override var itemSize:CGSize {
        get{
            return privItemSize
        }
        set(newSize){
            privItemSize = newSize
        }
    }
    
    override var estimatedItemSize:CGSize {
        get{
            let superEstimatedSize = super.estimatedItemSize
            return privEstimatedItemSize
        }
        set(newSize){
            privEstimatedItemSize = newSize
        }
    }
    
    override var minimumInteritemSpacing:CGFloat {
        get{
            return privMinimumHorizontalSpacing
        }
        set(newSpacing){
            privMinimumHorizontalSpacing = newSpacing
        }
    }
    
    var attachesCount:Int = 0
    
    private var privEstimatedItemSize = CGSizeMake(90.0, 70.0)
    private var privScrolDirection:UICollectionViewScrollDirection = .Horizontal
    private var privInterItemSize = CGSizeMake(5.0, 5.0)
    private var privItemSize = CGSizeMake(90.0, 70.0)
    private var attributes:[UICollectionViewLayoutAttributes]?
    private var contentSize:CGSize = CGSizeMake(310.0, 80.0)
    private var privMinimumHorizontalSpacing:CGFloat = 5.0
    
    convenience init(filesCount:Int)
    {
        self.init()
        self.attachesCount = filesCount
        self.configureAttributes()
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        
        if let superAttributes = super.layoutAttributesForElementsInRect(rect) {
            
            
            if self.attributes != nil
            {
                return attributes
            }
            else
            {
                return superAttributes
            }
        }
        else
        {
            return nil
        }
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        if self.attributes != nil {
            
            for lvAttribute in self.attributes!
            {
                if lvAttribute.indexPath.item == indexPath.item
                {
                    return lvAttribute
                }
            }
            return super.layoutAttributesForItemAtIndexPath(indexPath)
        }
        else
        {
            return UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        }
    }
    
    override func prepareLayout() {
        
        super.prepareLayout()
        if self.attributes == nil
        {
            configureAttributes()
        }
    }
//    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
////        self.attributes = nil
//        return false
//    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }
    
    func configureAttributes()
    {
        var horizontalOffset:CGFloat = 0.0
        if attachesCount > 0
        {
            var lvAttributes:[UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
            
            for var i = 0; i < attachesCount; i++
            {
                var cellFrame = CGRectMake(horizontalOffset, 0, privItemSize.width, privItemSize.height)
                
                var attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: NSIndexPath(forItem: i, inSection: 0))
                attribute.frame = cellFrame
                
                horizontalOffset += cellFrame.size.width + privInterItemSize.width
                lvAttributes.append(attribute)
            }
            attributes = lvAttributes
        }
        else
        {
            println("\r - Warning!! No items in attached files to calculate layout for cells! - \r")
            attributes = nil
        }
        let lvContentSize = CGSizeMake(horizontalOffset, privItemSize.height + privInterItemSize.height)
        self.contentSize = lvContentSize
    }
}



