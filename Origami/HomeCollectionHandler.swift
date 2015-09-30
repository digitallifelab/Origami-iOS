//
//  TilesCollectionHandler.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

@objc class HomeCollectionHandler: NSObject, UICollectionViewDataSource, UICollectionViewDelegate // UICollectionViewDelegateFlowLayout
{
    var signals:[Element]?
    var favourites:[Element]?
    var other:[Element]?
    //private var realSignals = [Element]()
    
    var elementSelectionDelegate:ElementSelectionDelegate?
  
    var isSignalsToggled = false
    private var nightModeEnabled = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
  
    convenience init(signals:[Element]?, favourites:[Element]?, other:[Element]?)
    {
        self.init()
        self.favourites = favourites
        self.other = other
        self.signals = signals
        //print("---> HomeCollectionHandler -  Initialized with \(self.signals?.count) signals");
    }

    func deleteAllElements()
    {
        signals?.removeAll(keepCapacity: false)
        favourites?.removeAll(keepCapacity: false)
        other?.removeAll(keepCapacity: false)
    }
    //MARK: DataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        var sectionsCountToReturn = 1
        if favourites != nil
        {
            
            sectionsCountToReturn += (favourites!.count > 0) ? 1 : 0
        }
        if other != nil
        {
            let otherCount = (other!.count > 0) ? 1 : 0
            sectionsCountToReturn += otherCount
        }
//        print("---- -- -- NumberOfSections: \(sectionsCountToReturn)")
        return sectionsCountToReturn
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        var toReturn:Int = 0
        switch section
        {
        case 0:
            if let existSignals = self.signals
            {
                toReturn = existSignals.count + 2 // "toggle bubbon" cell + "last messages" cell
            }
        case 1:
            if favourites!.count > 0
            {
                toReturn = favourites!.count
            }
            else
            {
                toReturn = other!.count
            }
        case 2:
            toReturn = other!.count
        default:
            break
        }
        return toReturn
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cellType = cellTypeForIndexPath(indexPath)
        if cellType == .Messages
        {
            let messagesHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("LastMessagesHolderCollectionCell", forIndexPath: indexPath) as! DashboardMessagesCell
            messagesHolderCell.displayMode = (nightModeEnabled) ? .Night : .Day
            messagesHolderCell.getLastMessages()
            return messagesHolderCell
        }
        else
        {
            let dashCell:DashCell =  collectionView.dequeueReusableCellWithReuseIdentifier("DashCell", forIndexPath: indexPath) as! DashCell
            dashCell.displayMode = (nightModeEnabled) ? .Night : .Day
            dashCell.cellType = cellType
            if cellType == .SignalsToggleButton
            {
                dashCell.signalsCountLabel?.text = "\(signals?.count ?? 0)"
                dashCell.layer.zPosition = 1000
                dashCell.currentElementType = 0
            }
            else
            {
                if let existingElement = elementForIndexPath(indexPath)
                {
                    if let title = existingElement.title as? String
                    {
                        dashCell.titleLabel?.text = title.uppercaseString
                    }
                    if let lvDescription = existingElement.details as? String
                    {
                        dashCell.descriptionLabel?.text = lvDescription
                    }
                    
                     let isAsignal = existingElement.isSignal.boolValue
                    
                    if isAsignal
                    {
                        dashCell.signalDetectorView?.hidden = false
                       // dashCell.signalDetectorView?.backgroundColor = kDaySignalColor
                    }
                    else
                    {
                        dashCell.signalDetectorView?.hidden = true
                    }
                    
                    dashCell.currentElementType = existingElement.typeId.integerValue // will set visibility for icons
                }
            }
            
            return dashCell
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        switch kind
        {
            case UICollectionElementKindSectionHeader:
            
                let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "DashHeader", forIndexPath: indexPath) as! DashHeaderView // force casting to DashHEaderView
                switch indexPath.section
                {
                    case 0:
                    headerView.label.text = NSLocalizedString("Signals", comment: "") // "Signals".localizedWithComment("")
                    headerView.displayDividerLine(false)
                    case 1:
                        if favourites?.count > 0
                        {
                            headerView.label.text = "Favorite".localizedWithComment("")
                            //headerView.displayDividerLine(true)
                        }
                        else
                        {
                            fallthrough
                        }
                    case 2:
                    headerView.label.text = "All".localizedWithComment("")
                    //headerView.displayDividerLine(true)
                    default: break
                }
                headerView.displayMode = (nightModeEnabled) ? .Night : .Day
                return headerView
            
            default:
            assert(false, "Unexpected element kind. Only header view is expected.")
            
            
            return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "DashHeader", forIndexPath: indexPath) as! DashHeaderView
        }
    }
    
    
    
    func elementForIndexPath(indexPath:NSIndexPath) -> Element?
    {
        let lvRow = indexPath.row
        switch indexPath.section {
        case 0:
            if signals!.count > indexPath.row - 2 && indexPath.row > 0
            {
                return signals![(lvRow - 2)]
            }
        case 1:
            if favourites!.count > 0 && favourites!.count > lvRow
            {
                return favourites![lvRow]
            }
            else if other!.count > lvRow
            {
                return other![lvRow]
            }
        case 2:
            if other!.count > lvRow
            {
                return other![lvRow]
            }
        default:
            break
        }
        
        return nil
    }
    
    func indexpathForElementById(elementId:Int, shouldDelete:Bool) -> [NSIndexPath]?
    {
        var indexpaths = [NSIndexPath]()
        var section:Int = 0
        var item:Int?
        if let sig = self.signals
        {
            for var i = 0; i < sig.count; i++
            {
                let element = sig[i]
                
                if element.elementId!.integerValue == elementId
                {
                    item = i + 2
                    if shouldDelete
                    {
                        self.signals!.removeAtIndex(i)
                    }
                    break
                }
            }
            if item != nil
            {
                let signalIndexPath = NSIndexPath(forItem: item!, inSection: section)
                indexpaths.append(signalIndexPath)
                item = nil
            }
        }
        if let fav = self.favourites
        {
            section = 1
            for var i = 0; i < fav.count; i++
            {
                let element = fav[i]
                
                if element.elementId!.integerValue == elementId
                {
                    item = i
                    if shouldDelete
                    {
                        self.favourites!.removeAtIndex(i)
                    }
                    break
                }
            }
            if item != nil
            {
                let favIndexPath = NSIndexPath(forItem: item!, inSection: section)
                indexpaths.append(favIndexPath)
            }
            item = nil
        }
        if let other = self.other
        {
            if section == 1
            {
                section = 2
            }
            else
            {
                section = 1 // when no favourites
            }
            for var i = 0; i < other.count; i++
            {
                let element = other[i]
                
                if element.elementId!.integerValue == elementId
                {
                    item = i
                    if shouldDelete
                    {
                        self.other!.removeAtIndex(i)
                    }
                    break
                }
            }
            if item != nil
            {
                let otherIndexPath = NSIndexPath(forItem: item!, inSection: section)
                indexpaths.append(otherIndexPath)
            }
            item = nil
        }
        
        if !indexpaths.isEmpty
        {
            return indexpaths
        }
        
        return nil
    }
    
    func deleteElementById(elementId:Int)
    {
        //if let
    }
    
    func cellTypeForIndexPath(indexPath:NSIndexPath) -> DashCellType
    {
        switch indexPath.section {
        case 2:
            fallthrough //return .Other
        case 1:
            if favourites!.count > 0
            {
                return .Other
            }
            return .Other
        case 0:
            if indexPath.row == 0
            {
                return .SignalsToggleButton
            }
            else if indexPath.row == 1
            {
                return .Messages
            }
            else
            {
                return .Signal
            }
        default:
            return .Other
            
        }
    }
 
    //MARK: Delegate
    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
        if cellTypeForIndexPath(indexPath) != .SignalsToggleButton
        {
            if let selectedElement = elementForIndexPath(indexPath)
            {
                //NSLog("\r Item selected: %ld : %ld", indexPath.section, indexPath.row)
                self.elementSelectionDelegate?.didTapOnElement(selectedElement)
                return
            }
            assert(false, "Did not find tapped element");
          
        }
        else
        {
            //print("  - Toggle Signals Pressed\n")
            isSignalsToggled = !isSignalsToggled
            var newLayout:UICollectionViewFlowLayout?
            if isSignalsToggled
            {
                newLayout = HomeSignalsVisibleFlowLayout(signals: signals!.count + 1, favourites: favourites, other: other)
            }
            else
            {
                newLayout = HomeSignalsHiddenFlowLayout(signals: signals!.count + 1, favourites: favourites, other: other)
            }
             //collectionView.collectionViewLayout.invalidateLayout()
//            collectionView.performBatchUpdates({ () -> Void in
            
                collectionView.setCollectionViewLayout(newLayout!, animated: true)
//            }, completion: { (finished) -> Void in
//                
//            })
            
        }
       
    }
    
    func turnOffAllSignalsVisibleIfVisible()
    {
        if isSignalsToggled
        {
            isSignalsToggled = false
        }
    }
    
    func turnNightModeOn(turnedOn:Bool)
    {
        nightModeEnabled = turnedOn
    }
    
    //for outer info
    func countSignals() -> Int
    {
        if let array = self.signals
        {
            return array.count
        }
        return 0
    }
    
    func countFavourites() -> Int
    {
        if let favs = self.favourites
        {
            return favs.count
        }
        return 0
    }
    
    func countOther() -> Int
    {
        if let other = self.other
        {
            return other.count
        }
        return 0
    }
}

