//
//  ElementSubordinatesCollectionHandler.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementSubordinatesCollectionHandler: CollectionHandler
{
     var dashElements:[Element] = [Element]()
        {
        didSet{
            
        }
    }
    
    var elementSelectionDelegate:ElementSelectionDelegate?
    
    var displayMode:DisplayMode = .Day
    
    override init()
    {
        super.init()
    }
    
    convenience init?(subordinates:[Element])
    {
        self.init()
        if  subordinates.isEmpty
        {
            return nil
        }
        self.dashElements = subordinates
    }
    
    //MARK: DataSource
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let dashCount = self.dashElements.count
        //print("Dash Elements Count = \(dashCount)")
        return dashCount
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let subordinateCell = collectionView.dequeueReusableCellWithReuseIdentifier("ElementDashCell", forIndexPath: indexPath) as! DashCell
        let element = elementForIndexPath(indexPath)
        subordinateCell.displayMode = self.displayMode
        subordinateCell.cellType = (element.isSignal.boolValue) ? .Signal : .Other
        subordinateCell.titleLabel?.text = element.title //as? String
        subordinateCell.descriptionLabel?.text = element.details //as? String
        //subordinateCell.layer.borderWidth = 1.0
        return subordinateCell
    }
    
    func elementForIndexPath(indexPath:NSIndexPath) -> Element
    {
        return dashElements[indexPath.row]
    }
    
    //Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        self.elementSelectionDelegate?.didTapOnElement(elementForIndexPath(indexPath))
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }
        
}
