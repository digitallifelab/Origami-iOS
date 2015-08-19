//
//  ContactCheckerCell.swift
//  Origami
//
//  Created by CloudCraft on 30.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactCheckerCell: UITableViewCell {

    @IBOutlet var checkBox:UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var avatar:UIImageView!
    
    var displayMode:DisplayMode = .Day{
        didSet{
            if displayMode == .Day
            {
                nameLabel.textColor = UIColor.blackColor()
                checkBox.tintColor = kDayCellBackgroundColor
            }
            else
            {
                nameLabel.textColor = UIColor.lightGrayColor()
                checkBox.tintColor = kWhiteColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
