//
//  SIngleElementButtonsCell.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementButtonsCell: UICollectionViewCell {
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
    }
}
