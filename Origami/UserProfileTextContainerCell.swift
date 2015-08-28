//
//  UserProfileTextContainerCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileTextContainerCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel:UILabel?
    @IBOutlet weak var textLabel:UILabel?
    @IBOutlet weak var editButton:UIButton?
    
    var delegate:UserProfileAvatarCollectionCellDelegate?
    
    var cellType:ProfileTextCellType = .Email
        {
        didSet
        {
            if cellType == .Email
            {
                editButton?.hidden = true
            }
            else
            {
                editButton?.hidden = false
            }
        }
    }
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day:
                textLabel?.textColor = kBlackColor
                editButton?.tintColor = kDayCellBackgroundColor
                self.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.7)
            case .Night:
                textLabel?.textColor = kWhiteColor
                editButton?.tintColor = kWhiteColor
                self.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.7)
            }
        }
    }
    
    @IBAction func editButtonTapped(sender:UIButton?)
    {
        if cellType == .Email
        {return}
            
        delegate?.changeInfoPressed(cellType)
    }
}
