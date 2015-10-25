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
    var signals:[DBElement]?
    var favourites:[DBElement]?
    var other:[DBElement]?
    
    var elementSelectionDelegate:ElementSelectionDelegate?
  
    var isSignalsToggled = false
    private var nightModeEnabled = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
  
    convenience init(info:dashboardDBElementsInfoTuple)
    {
        self.init()
        self.signals = info.signals
        self.favourites = info.favourites
        self.other = info.other
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
            if let favourites = self.favourites
            {
                toReturn = favourites.count
            }
            else if let other = self.other
            {
                toReturn = other.count
            }
        case 2:
            if let other = self.other
            {
                toReturn = other.count
            }
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
            //print("row: \(indexPath.row) in section: \(indexPath.section) -> \(cellType)")
            let messagesHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("LastMessagesHolderCollectionCell", forIndexPath: indexPath) as! DashboardMessagesCell
            messagesHolderCell.displayMode = (nightModeEnabled) ? .Night : .Day
            messagesHolderCell.getLastMessages()
            return messagesHolderCell
        }
        else
        {
            //print("row: \(indexPath.row) in section: \(indexPath.section) -> \(cellType)")
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

                dashCell.titleLabel?.text = existingElement.title?.uppercaseString

                dashCell.descriptionLabel?.text = existingElement.details

                if let signalBool = existingElement.isSignal
                {
                    dashCell.signalDetectorView?.hidden = !signalBool.boolValue //existingElement.isSignal?.boolValue
                }
                    
                    if let elType = existingElement.type?.integerValue
                    {
                        dashCell.currentElementType = elType //existingElement.typeId //.integerValue // will set visibility for icons
                    }
                    
                    if let finishState = existingElement.finishState, let finishStateEnumValue = ElementFinishState(rawValue: finishState.integerValue)//.integerValue)
                    {
                        switch finishStateEnumValue
                        {
                        case .Default:
                            //dashCell.taskIcon?.image = UIImage(named: "task-available-to-set")?.imageWithRenderingMode(.AlwaysTemplate)
                            dashCell.taskIcon?.image = nil
                            break
                        case .InProcess:
                            dashCell.taskIcon?.image = UIImage(named: "tile-task-pending")?.imageWithRenderingMode(.AlwaysTemplate)
                        case .FinishedBad:
                            dashCell.taskIcon?.image = UIImage(named: "tile-task-bad")?.imageWithRenderingMode(.AlwaysTemplate)
                        case .FinishedGood:
                            dashCell.taskIcon?.image = UIImage(named: "tile-task-good")?.imageWithRenderingMode(.AlwaysTemplate)
                        }
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
    
    
    
    func elementForIndexPath(indexPath:NSIndexPath) -> DBElement?
    {
        let lvRow = indexPath.row
        switch indexPath.section
        {
            case 0:
                if lvRow == 0
                {
                    return nil
                }
                if let signals = self.signals
                {
                    if indexPath.row > 0
                    {
                        let foundSignalElement = signals[(indexPath.row - 1)]
                        
                        return foundSignalElement
                        
                    }
                }
            case 1:
                if let favCount = favourites?.count
                {
                    if favCount > 0 && favCount > lvRow
                    {
                        return favourites![lvRow]
                    }
                }
                else if let otherCount = other?.count
                {
                    if otherCount > 0
                    {
                        return other![lvRow]
                    }
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
        case 0:
            if indexPath.row == 0
            {
                return .SignalsToggleButton
            }
            else if indexPath.row == 1
            {
                if isSignalsToggled
                {
                    return .Signal
                }
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
            if let selectedElement = elementForIndexPath(indexPath), elementIdInt = selectedElement.elementId?.integerValue
            {
                //NSLog("\r Item selected: %ld : %ld", indexPath.section, indexPath.row)
                self.elementSelectionDelegate?.didTapOnElement(elementIdInt)
                return
            }
            assert(false, "Did not find tapped element");
          
        }
        else
        {
            //print("  - Toggle Signals Pressed\n")
            isSignalsToggled = !isSignalsToggled
            var newLayout:UICollectionViewFlowLayout?
            
            
            
            let infoForLayout:dashboardDBElementsInfoTuple = (signals: self.signals, favourites:self.favourites, other: self.other)
            let layoutStruct = HomeSignalsHiddenFlowLayout.prepareLayoutStructWithInfo(infoForLayout)
            
            if isSignalsToggled
            {
                newLayout = HomeSignalsVisibleFlowLayout(layoutInfoStruct: layoutStruct)
            }
            else
            {
                newLayout = HomeSignalsHiddenFlowLayout(layoutInfoStruct: layoutStruct)
            }
            
                   collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 1, inSection: 0)])
            collectionView.setCollectionViewLayout(newLayout!, animated: true)
//            
//            collectionView.performBatchUpdates({ () -> Void in
//              
//                }, completion: { (filished) -> Void in
//                    
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

