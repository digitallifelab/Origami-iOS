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
    private var realSignals = [Element]()
    
    var elementSelectionDelegate:ElementSelectionDelegate?
  
    var isSignalsToggled = false
    private var nightModeEnabled = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
  
    convenience init(signals:[Element], favourites:[Element], other:[Element])
    {
        self.init()
        self.favourites = favourites
        self.other = other
        realSignals += signals
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
//        println("---- -- -- NumberOfSections: \(sectionsCountToReturn)")
        return sectionsCountToReturn
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        var toReturn:Int = 0
        switch section
        {
        case 0:
            toReturn = realSignals.count + 2 // "toggle bubbon" cell + "last messages" cell
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
            var messagesHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("LastMessagesHolderCollectionCell", forIndexPath: indexPath) as! DashboardMessagesCell
            messagesHolderCell.displayMode = (nightModeEnabled) ? .Night : .Day
            return messagesHolderCell
        }
        else
        {
            var dashCell:DashCell =  collectionView.dequeueReusableCellWithReuseIdentifier("DashCell", forIndexPath: indexPath) as! DashCell
            dashCell.displayMode = (nightModeEnabled) ? .Night : .Day
            dashCell.cellType = cellType
            if cellType == .SignalsToggleButton
            {
                dashCell.signalsCountLabel.text = "\(realSignals.count)"
                dashCell.layer.zPosition = 1000
            }
            else
            {
                if let existingElement = elementForIndexPath(indexPath)
                {
                    if let title = existingElement.title as? String
                    {
                        dashCell.titleLabel.text = title.uppercaseString
                    }
                    if let lvDescription = existingElement.details as? String
                    {
                        dashCell.descriptionLabel.text = lvDescription
                    }
                    
                    if let isAsignal = existingElement.isSignal?.boolValue
                    {
                        if isAsignal
                        {
                            dashCell.signalDetectorView?.hidden = false
                           // dashCell.signalDetectorView?.backgroundColor = kDaySignalColor
                        }
                        else
                        {
                            dashCell.signalDetectorView?.hidden = true
                        }
                    }
                    else
                    {
                        dashCell.signalDetectorView?.hidden = true
                    }
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
                    headerView.label.text = "Signals".localizedWithComment("")
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
            if realSignals.count > indexPath.row - 2 && indexPath.row > 0
            {
                return realSignals[(lvRow - 2)]
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
    
    func cellTypeForIndexPath(indexPath:NSIndexPath) -> DashCellType
    {
        switch indexPath.section {
        case 2:
            fallthrough //return .Other
        case 1:
            if favourites!.count > 0
            {
//                if let element = elementForIndexPath(indexPath)
//                {
//                    if element.isSignal != nil && element.isSignal!.boolValue
//                    {
//                        return .Signal
//                    }
//                }
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
            println("\(self)  - Toggle Signals Pressed\n")
            isSignalsToggled = !isSignalsToggled
            var newLayout:UICollectionViewFlowLayout?
            if isSignalsToggled
            {
                newLayout = HomeSignalsVisibleFlowLayout(signals: realSignals.count + 1, favourites: favourites, other: other)
            }
            else
            {
                newLayout = HomeSignalsHiddenFlowLayout(signals: realSignals.count + 1, favourites: favourites, other: other)
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
    func countSignals()->Int
    {
        return realSignals.count
    }
}

