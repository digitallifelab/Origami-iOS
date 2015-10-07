//
//  ContactProfileAvatarCell.swift
//  Origami
//
//  Created by CloudCraft on 26.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactProfileAvatarCell: UITableViewCell {

    @IBOutlet weak var avatar:UIImageView?
    @IBOutlet weak var favIcon:UIImageView!
    
    var favourite = false{
        didSet{
            if favourite
            {
                favIcon?.hidden = false
            }
            else
            {
                favIcon?.hidden = true
            }
            self.setNeedsLayout()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        favIcon.image = UIImage(named: "icon-favourite")?.imageWithRenderingMode(.AlwaysTemplate)
        favIcon.tintColor = kDayCellBackgroundColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        favIcon.image = UIImage(named: "icon-favourite")?.imageWithRenderingMode(.AlwaysTemplate)
//        favIcon.tintColor = kDayCellBackgroundColor
        //favIcon.backgroundColor = kWhiteColor
        
        avatar?.maskToCircle()
    }
}
