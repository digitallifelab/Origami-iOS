//
//  SingleCollectionHandler.swift
//  Origami
//
//  Created by CloudCraft on 16.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

@objc class SingleCollectionHandler: NSObject, UICollectionViewDataSource, UICollectionViewDelegate
{
    lazy var handledElements:[Element] = [Element]()
    var elementSelectionDelegate:ElementSelectionDelegate?
    var isForHandlingSignals = false
    var isSignalsToggled = false
    
    
    convenience init(elements:[Element])
    {
        self.init()
        self.handledElements = elements
    }
    
    //MARK: DataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1 //toReturnSections  // signals, favourites, other
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        var toReturn:Int = 0
        
        if isForHandlingSignals
        {
            if isSignalsToggled
            {
                toReturn = handledElements.count + 1
            }
            else
            {
                toReturn = 1
            }
        }
        else
        {
            toReturn = handledElements.count
        }
        
        return toReturn
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        var dashCell:DashCell =  collectionView.dequeueReusableCellWithReuseIdentifier("DashCell", forIndexPath: indexPath) as! DashCell
        
        if isForHandlingSignals
        {
            if indexPath.row == 0
            {
                dashCell.cellType = .SignalsToggleButton
                dashCell.signalsCountLabel.text = "\(handledElements.count)"
            }
            else
            {
                dashCell.cellType = .Signal
            }
        }
        else
        {
            dashCell.cellType = .Other
        }
        ////////////////////////////////////////////////////////////////
        if let existingElement = elementForIndexPath(indexPath)
        {
            if let title = existingElement.title as? String
            {
                dashCell.titleLabel.text = title
            }
            if let lvDescription = existingElement.details as? String
            {
                dashCell.descriptionLabel.text = lvDescription
            }
        }
        
        return dashCell
    }
    
    
    func elementForIndexPath(indexPath:NSIndexPath) -> Element?
    {
        if isForHandlingSignals
        {
            if isSignalsToggled
            {
                let targetRow = indexPath.row - 1
                if targetRow >= 0 && targetRow < handledElements.count
                {
                    return handledElements[targetRow]
                }
            }
        }
        else
        {
            if handledElements.count > indexPath.row
            {
                return handledElements[indexPath.row]
            }
        }
        
        return nil
    }
    
    
    
    //MARK: Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        
        if let selectedElement = elementForIndexPath(indexPath)
        {
            NSLog("\r Item selected: %ld : %ld", indexPath.section, indexPath.row)
            self.elementSelectionDelegate?.didTapOnElement(selectedElement)
        }
        else
        {
            println("\(self) - Toggle Signals Pressed")
            isSignalsToggled = !isSignalsToggled
            collectionView.reloadSections(NSIndexSet(index: 0))
        }
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
}

