//
//  UserProfileAvatarCollectionCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileAvatarCollectionCell: UICollectionViewCell {
    
    @IBOutlet var avatar:UIButton! // big button will act as UIImageView
    @IBOutlet var changeAvatarButton:UIButton!
    
    var delegate:UserProfileAvatarCollectionCellDelegate?
    
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
