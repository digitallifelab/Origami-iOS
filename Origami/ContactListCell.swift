//
//  ContactListCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactListCell: UITableViewCell {

    
    @IBOutlet var avatar:UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var favouriteButton:UIButton!
    @IBOutlet var emailLabel:UILabel?
    @IBOutlet var phoneLabel:UILabel?
    
    
    @IBAction func favouriteButtonNapped(sender:UIButton?)
    {
        if let userName = emailLabel?.text
        {
            NSNotificationCenter.defaultCenter().postNotificationName(kContactFavouriteButtonTappedNotification, object: nil, userInfo: ["userName":userName])
        }
    }

}
