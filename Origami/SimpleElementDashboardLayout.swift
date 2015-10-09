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
    
    mutating func changeTo(newWidth:SubordinateItemLayoutWidth) -> SubordinateItemLayoutWidth
    {
        self = newWidth
        return self
    }
}

struct ElementDetailsStruct
{
    var title:String
    var details:String?
    var messagesPreviewCell:Bool = false
    //var buttonsCell:Bool = false
    var attachesCell:Bool = false
    var subordinates:[SubordinateItemLayoutWidth]?
    
    var hiddenDetailsText = true {
        didSet{
            print(" - > elementStruct details visibility toggled! -- Visible = \(self.hiddenDetailsText)")
        }
    }
    
    mutating func toggleDetailsHidden()
    {
        self.hiddenDetailsText = !self.hiddenDetailsText
    }
    
    init(title:String, details:String?, messagesCell:Bool?, /*buttonsCell:Bool?,*/ attachesCell:Bool?, subordinateItems:[SubordinateItemLayoutWidth]?)
    {
        self.title = title
        self.details = details
        if messagesCell != nil
        {
            self.messagesPreviewCell = messagesCell!
        }
        
        if attachesCell != nil
        {
            self.attachesCell = attachesCell!
        }
        if subordinateItems != nil
        {
            if !subordinateItems!.isEmpty
            {
                self.subordinates = subordinateItems
            }
        }
        
        //print(" -> SimpleElementDashboardLayout  struct description:\n title: \"\(self.title)\",\n details :\" \(self.details) \",\n messagesContained: \(self.messagesPreviewCell), \n attaches: \(self.attachesCell),\n subordinates:  \(self.subordinates) <- \n")
    }
}


class SimpleElementDashboardLayout: UICollectionViewFlowLayout {
   
    private var elementStruct:ElementDetailsStruct?
    private var cellLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    //private var headerLayoutAttributes:[NSIndexPath : UICollectionViewLayoutAttributes]
    
    private var sizeOfContent:CGSize = CGSizeZero
    
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

    required init?(coder aDecoder: NSCoder) {
        
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
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
    {
        var superForIndexPath = super.layoutAttributesForItemAtIndexPath(indexPath)
        
        if let existingItemAttrs = cellLayoutAttributes[indexPath]
        {
            print("existing: \(indexPath.item)")
            superForIndexPath = existingItemAttrs
        }
        
        return superForIndexPath
    }
    
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
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
    
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
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
    
    func setNewLayoutInfo(infoStruct:ElementDetailsStruct)
    {
        self.elementStruct = infoStruct
        self.invalidateLayout()
    }
    
    
    func performLayoutCalculating()
    {
        //let currentScreenInfo = FrameCounter.getCurrentTraitCollection()
        var currentScreenWidth = UIScreen.mainScreen().bounds.size.width
        //var itemMargin = self.minimumInteritemSpacing
        
        if FrameCounter.isLowerThanIOSVersion("8.0")
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
                currentHeight = UIScreen.mainScreen().bounds.size.width
                currentScreenWidth = currentWidth
            }
        }
        
        let mainFrameWidth = currentScreenWidth
        let mainFrame = CGRectMake(0.0, 0, mainFrameWidth, 100)// the height is not important
        
        var offsetX = mainFrame.origin.x
        var offsetY = mainFrame.origin.y
        var titleFrame = CGRectMake(offsetX, offsetY, mainFrame.width, 150.0)

        if let aDataSource = self.collectionView?.dataSource as? SingleElementCollectionViewDataSource
        {
            if aDataSource.titleCellMode == .Title
            {
                var size = CGSizeMake(mainFrame.width, 200.0)
                
                if let nsStringTitleText =  self.elementStruct?.title, font = UIFont(name: "SegoeUI", size: 30.0)
                {
                    var boundingSize = CGSizeMake(mainFrame.width - (50 + 16), CGFloat(FLT_MAX) )
                    
                        boundingSize.width -= (8 + 45 + 16)
                    
                    let textLabelSize = nsStringTitleText.boundingRectWithSize(boundingSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil).size
                    size.height =  ceil(textLabelSize.height) + 60 + 55
                }
                
                titleFrame.size = CGSizeMake(mainFrame.size.width, size.height )
                //print("-> Title Cell Size:\(titleFrame.size)")
            }
            else // .Dates
            {
                titleFrame.size = CGSizeMake(mainFrame.width, 140.0)
            }
        }
        
        let titleIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        let attribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: titleIndexPath)
        attribute.zIndex = 1000
        attribute.frame = titleFrame
        cellLayoutAttributes[titleIndexPath] = attribute
        
        offsetX = CGRectGetMaxX(titleFrame)
        let checkOffset = checkCurrentCellOffset(offsetX, frame: mainFrame)
        if checkOffset < offsetX
        {
            offsetX = checkOffset
            offsetY += titleFrame.size.height // + 10
        }
        
        var itemIndex = 1 //because title in already stored in cellLayoutAttributes first indexpath 0-0
        
        if let privateStruct = elementStruct
        {
            if privateStruct.messagesPreviewCell
            {
                let messagesIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)

                let messagesFrame = CGRectMake(offsetX, offsetY, mainFrame.size.width, 152.0)
                let messagesAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: messagesIndexPath)
                messagesAttribute.zIndex = 400
                messagesAttribute.frame = messagesFrame
                cellLayoutAttributes[messagesIndexPath] = messagesAttribute
                itemIndex += 1
                
                offsetY += CGRectGetHeight(messagesFrame); //print("moved down from MESSAGES cell")
                offsetX = checkCurrentCellOffset(offsetX, frame: mainFrame)
            }
            
            if let detailsString = privateStruct.details
            {
                if !detailsString.isEmpty
                {
                    offsetX = mainFrame.origin.x
                    let detailsIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                    var detailsFrame = CGRectMake(offsetX, offsetY, mainFrameWidth, 120.0)
                    if CGRectGetMaxX(detailsFrame) > mainFrameWidth
                    {
                        offsetY += detailsFrame.size.height
                        detailsFrame.origin = CGPointMake(offsetX, offsetY)
                    }
                    
                    if let aDataSource = self.collectionView?.dataSource as? SingleElementCollectionViewDataSource
                    {
                        if let detailsCellFromDataSource = aDataSource.detailsCell
                        {
                            var detailsSize = CGSizeMake(mainFrame.width, 200.0)
                            
                            let label = detailsCellFromDataSource.textLabel

                            let labelSize = label.sizeThatFits(CGSizeMake(mainFrame.width - (28 + 8), CGFloat(FLT_MAX) ))

                            detailsSize.height = labelSize.height + 2 + 2 + 32 //top and bottom constraints
                            //print("-> Details Cell Size: \(detailsSize)")
                            
                            if detailsSize.height < detailsFrame.size.height
                            {
                                detailsFrame.size.height = detailsSize.height
                            }
                            else
                            {
                                if !privateStruct.hiddenDetailsText
                                {
                                    detailsFrame.size = CGSizeMake(mainFrame.size.width, detailsSize.height)
                                }
                            }
                        }
                    }
                    
                    let detailsAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: detailsIndexPath)
                    detailsAttribute.zIndex = 200
                    detailsAttribute.frame = detailsFrame
                    cellLayoutAttributes[detailsIndexPath] = detailsAttribute
                    itemIndex += 1
                    
                    offsetY += CGRectGetHeight(detailsFrame); //print("moved down from DETAILS cell")
                    

                    offsetX = checkCurrentCellOffset(offsetX, frame: mainFrame)
                }
                else
                {
                    print("\n -> Will not calculate layout for empty details collectiobView cell <- ")
                }
            }
            
            if privateStruct.attachesCell
            {
                // attaches will be wull screen width
                offsetX = mainFrame.origin.x
                offsetY += self.minimumLineSpacing
                
                let attachesFrame = CGRectMake(offsetX, offsetY, mainFrame.size.width, 80.0)
                let attachesIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                let attachesAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: attachesIndexPath)
                attachesAttribute.frame = attachesFrame
                cellLayoutAttributes[attachesIndexPath] = attachesAttribute
                itemIndex += 1
                
                offsetY += attachesFrame.size.height;// print("Moved Down after ATTACHes cell")
                
                //print("\n-----------Layout for attach file collection holder cell-----------\n")
            }

            
            if let subordinateData = privateStruct.subordinates
            {
                offsetX = self.minimumInteritemSpacing
                offsetY += self.minimumLineSpacing //+ HomeCellNormalDimension
                
                let subordinatesCount = subordinateData.count
                
                for var i = 0; i < subordinatesCount; i++
                {
                    let currentSubordinateData = subordinateData[i]
                    
                    //check item width
                    var subordinateSize = CGSizeMake(HomeCellNormalDimension, HomeCellNormalDimension)
                    if currentSubordinateData == .Wide
                    {
                        subordinateSize.width = HomeCellWideDimension
                    }
                    
                    // create and store frame
                    let subordinateIndexPath = NSIndexPath(forItem: itemIndex, inSection: 0)
                    var cellFrame = CGRectMake(offsetX, offsetY, subordinateSize.width, subordinateSize.height)
                    let subordinateAttribute = UICollectionViewLayoutAttributes(forCellWithIndexPath: subordinateIndexPath)
                    
                    // detect if next frame with this offset will be still visible
                    if CGRectGetMaxX(cellFrame) > (mainFrame.size.width - self.minimumInteritemSpacing)
                    {
                        offsetX = self.minimumInteritemSpacing
                        offsetY += (CGRectGetHeight(cellFrame) + self.minimumLineSpacing)
                        cellFrame.origin.x = offsetX
                        cellFrame.origin.y = offsetY
                    }
                    
                    subordinateAttribute.frame = cellFrame
                    cellLayoutAttributes[subordinateIndexPath] = subordinateAttribute
                    itemIndex += 1
                    
                    //create origin for next item
                    offsetX = CGRectGetMaxX(cellFrame) + self.minimumInteritemSpacing // move to right
                }
                
                //print("\n Finished calculating subordinates")
            }
        }
        // detect downmost frame
        
        var lastIndexPath:NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        for (indexpath, _) in cellLayoutAttributes
        {
            if indexpath.item > lastIndexPath.item
            {
                lastIndexPath = indexpath
            }
        }
        
        let lastAttribute = cellLayoutAttributes[lastIndexPath]
        
        self.sizeOfContent = CGSizeMake(CGRectGetMaxX(lastAttribute!.frame), CGRectGetMaxY(lastAttribute!.frame) + self.minimumLineSpacing * 2)
        //print("self.collectionViewContentSize()  should return \(sizeOfContent)")
    }
    
    private func checkCurrentCellOffset(offset:CGFloat, frame:CGRect) -> CGFloat
    {
        var newOffset = offset
        if offset > frame.size.width / 2.0
        {
            newOffset = frame.origin.x
        }
        
        return newOffset
    }
    
    func toggleDetailsTextVisibility()
    {
        if let _ = self.elementStruct
        {
            self.elementStruct?.toggleDetailsHidden()
        }
    }
    //MARK: - moving, inserting, deleting items
//    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
//        print("filalForDisappearing: item: \(itemIndexPath.item) , section: \(itemIndexPath.section)")
//        if itemIndexPath.item == 1
//        {
//            if let attributes = cellLayoutAttributes[NSIndexPath(forItem: 2, inSection: 0)]
//            {
//                return attributes
//            }
//        }
//        return nil
//    }
//    
//    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
//                print("initialForAppearing: item: \(itemIndexPath.item) , section: \(itemIndexPath.section)")
//        
//        return self.cellLayoutAttributes[itemIndexPath]
//    }
}
