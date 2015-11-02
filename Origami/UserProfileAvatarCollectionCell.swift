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
    
    weak var delegate:UserProfileCollectionCellDelegate?
    
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

//        if #available(iOS 8.0, *)
//        {
//            if let avatarImageView = self.avatarImageView
//            {
//              
//            }
//        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //if #available( iOS 8.0, *)
       // {
            avatarImageView?.maskToCircle()
        //}
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
