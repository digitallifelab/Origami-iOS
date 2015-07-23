//
//  UserProfileTextContainerCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileTextContainerCell: UICollectionViewCell {
    
    @IBOutlet var textLabel:UILabel!
    @IBOutlet var editButton:UIButton!
    
    var cellType:ProfileTextCellType = .Email{
        didSet{
            if cellType == .Email
            {
                editButton.hidden = true
            }
            else
            {
                editButton.hidden = false
            }
        }
    }
    
    @IBAction func editButtonTapped(sender:UIButton)
    {
        
    }
}
