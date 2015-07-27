//
//  SIngleElementButtonsCell.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementButtonsCell: UICollectionViewCell, UICollectionViewDelegate {
    
    @IBOutlet var buttonsCollection:UICollectionView!
    
    var buttonsLayout:ElementActionButtonsLayout?
    var dataSource:UICollectionViewDataSource?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let dataSource = self.dataSource
        {
            buttonsCollection.dataSource = dataSource
            if let layout = buttonsLayout
            {
                buttonsCollection.setCollectionViewLayout(layout, animated: false)
            }
        }
        
        buttonsCollection.delegate = self
    }
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let datasource = dataSource as? ElementActionButtonsDataSource, buttons = datasource.buttons
        {
            let buttonStruct = buttons[indexPath.item]
            if buttonStruct.enabled
            {
                NSNotificationCenter.defaultCenter().postNotificationName(kElementActionButtonPressedNotification, object: self, userInfo: ["actionButtonIndex" : buttonStruct.type.rawValue])
            }
        }
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        
    }
}
