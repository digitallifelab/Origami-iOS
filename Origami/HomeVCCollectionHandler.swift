//
//  HomeVCCollectionHandler.swift
//  Origami
//
//  Created by CloudCraft on 10.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class HomeVCCollectionHandler: NSObject, UICollectionViewDataSource {
   
    
    var signals:[Element]?
    var favorites:[Element]?
    var other:[Element]?
    var nightModeEnabled = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
    
    
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        var sectionsCountToReturn = 1
        if let fav = favorites
        {
            sectionsCountToReturn += (fav.count > 0) ? 1 : 0
        }
        if let others = other
        {
            let otherCount = (others.count > 0) ? 1 : 0
            sectionsCountToReturn += otherCount
        }
        //        println("---- -- -- NumberOfSections: \(sectionsCountToReturn)")
        return sectionsCountToReturn
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var toReturn:Int = 0
        switch section
        {
        case 0:
            if let existSignals = signals
            {
                toReturn = existSignals.count + 2 // "toggle bubbon" cell + "last messages" cell
            }
        case 1:
            
            if let fav = favorites
            {
                toReturn = fav.count
            }
            else if let others = other
            {
                toReturn = others.count
            }
        case 2:
            if let others = other
            {
                toReturn = others.count
            }
            
        default:
            break
        }
        return toReturn
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellType = cellTypeForIndexPath(indexPath)
        if cellType == .Messages
        {
            var messagesHolderCell = collectionView.dequeueReusableCellWithReuseIdentifier("LastMessagesHolderCollectionCell", forIndexPath: indexPath) as! DashboardMessagesCell
            messagesHolderCell.displayMode = (nightModeEnabled) ? .Night : .Day
            messagesHolderCell.getLastMessages()
            
            return messagesHolderCell
        }
        else
        {
            var dashCell:DashCell =  collectionView.dequeueReusableCellWithReuseIdentifier("DashCell", forIndexPath: indexPath) as! DashCell
            dashCell.displayMode = (nightModeEnabled) ? .Night : .Day
            dashCell.cellType = cellType
            if cellType == .SignalsToggleButton
            {
                dashCell.signalsCountLabel.text = "\(signals?.count ?? 0)"
                dashCell.layer.zPosition = 1000
            }
            else
            {
                if let existingElement = elementForIndexPath(indexPath)
                {
                    if let title = existingElement.title
                    {
                        dashCell.titleLabel.text = title.uppercaseString
                    }
                    if let lvDescription = existingElement.details as? String
                    {
                        dashCell.descriptionLabel.text = lvDescription
                    }
                    
                    let isAsignal = existingElement.isSignal.boolValue
                    
                    if isAsignal
                    {
                        dashCell.signalDetectorView?.hidden = false
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
                if favorites?.count > 0
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
            if let signalz = signals
            {
                if signalz.count > indexPath.row - 2 && indexPath.row > 0
                {
                    return signalz[(lvRow - 2)]
                }
            }
        case 1:
            if let fav = favorites
            {
                if fav.count > 0 && fav.count > lvRow
                {
                    return fav[lvRow]
                }
            }
            else if let others = other
            {
                if others.count > lvRow
                {
                    return others[lvRow]
                }
            }
        case 2:
            if let others = other
            {
                if others.count > lvRow
                {
                    return others[lvRow]
                }
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
            if favorites!.count > 0
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
    
}
