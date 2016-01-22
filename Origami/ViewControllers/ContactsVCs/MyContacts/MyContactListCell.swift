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
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode{
            case .Day:
                avatar.tintColor = kDayCellBackgroundColor
                nameLabel.textColor = kBlackColor
            case .Night:
                avatar.tintColor = kWhiteColor
                nameLabel?.textColor = kWhiteColor
            }
        }
    }
    
    override func awakeFromNib() {
        //avatar.image = UIImage(named: "icon-contacts")
        avatar.maskToCircle()
    }
    
    
//    @IBAction func favouriteButtonNapped(sender:UIButton?)
//    {
//        NSNotificationCenter.defaultCenter().postNotificationName(kContactFavouriteButtonTappedNotification, object: nil, userInfo: ["index":sender!.tag])
//    }

    
}
