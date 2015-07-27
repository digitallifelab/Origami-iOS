//
//  ElementActionButtonCell.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementActionButtonCell: UICollectionViewCell {
    
    var buttonType:ActionButtonType = .Add
    
    @IBOutlet var imageView:UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.maskToCircle()
    }
    
    
    
}
