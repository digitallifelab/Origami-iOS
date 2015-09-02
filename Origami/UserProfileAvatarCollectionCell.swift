//
//  UserProfileAvatarCollectionCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileAvatarCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarImageView:UIImageView?
    @IBOutlet weak var avatarButton:UIButton? // big button on top of imageview
    @IBOutlet weak var changeAvatarButton:UIButton?
    
    var delegate:UserProfileCollectionCellDelegate?
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode{
            case .Day:
                changeAvatarButton?.tintColor = kDayCellBackgroundColor
                avatarImageView?.tintColor = kDayCellBackgroundColor
                
            case .Night:
                changeAvatarButton?.tintColor = kWhiteColor
                avatarImageView?.tintColor = kWhiteColor
            }
        }
    }
    var editingEnabled = false {
        didSet{
            if editingEnabled
            {
                changeAvatarButton?.hidden = false
            }
            else
            {
                changeAvatarButton?.hidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView?.clipsToBounds = true
        avatarImageView?.layer.borderWidth = 0.0
        avatarButton?.layer.borderWidth = 0.0
    }
    
    @IBAction func avatarPressed(sender:UIButton)
    {
        //show full screen photo of user
        delegate?.showAvatarPressed()
    }
    
    @IBAction func changeAvatarPressed(sender:UIButton)
    {
        // show image picking view controller
        delegate?.changeAvatarPressed()
    }
    
}
