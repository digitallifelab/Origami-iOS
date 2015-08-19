//
//  ContactListCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class MyContactListCell: UITableViewCell {

    
    @IBOutlet var avatar:UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var favouriteButton:UIButton!
    @IBOutlet var moodLabel:UILabel?
    //@IBOutlet var emailLabel:UILabel?
    //@IBOutlet var phoneLabel:UILabel?
    
    override func awakeFromNib() {
        avatar.image = UIImage(named: "icon-contacts")
    }
    @IBAction func favouriteButtonNapped(sender:UIButton?)
    {
//        if let userName = emailLabel?.text
//        {
            NSNotificationCenter.defaultCenter().postNotificationName(kContactFavouriteButtonTappedNotification, object: nil, userInfo: ["index":sender!.tag])
//        }
    }

}
