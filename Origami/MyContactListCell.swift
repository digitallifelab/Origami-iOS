//
//  ContactListCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class MyContactListCell: UITableViewCell {

    
    @IBOutlet weak var avatar:UIImageView!
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var favouriteButton:UIButton!
    @IBOutlet weak var moodLabel:UILabel?
    
    override func awakeFromNib() {
        avatar.image = UIImage(named: "icon-contacts")
        avatar.maskToCircle()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        avatar?.tintColor = kDayCellBackgroundColor
    }
    
    @IBAction func favouriteButtonNapped(sender:UIButton?)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kContactFavouriteButtonTappedNotification, object: nil, userInfo: ["index":sender!.tag])
    }

    
}
