//
//  SingleElementAttachesCollectionHolderCell.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementAttachesCollectionHolderCell: UICollectionViewCell {
    
    
    
    @IBOutlet var attachesCollectionView:UICollectionView!
    @IBOutlet var addAttachmentButton:UIButton!
    @IBAction func addAttachmentPressed(sender:UIButton)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kAddNewAttachFileTapped, object: nil)
    }
    
    
}
