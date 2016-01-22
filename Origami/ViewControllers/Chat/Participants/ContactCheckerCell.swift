//
//  ContactCheckerCell.swift
//  Origami
//
//  Created by CloudCraft on 30.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactCheckerCell: UITableViewCell {

    @IBOutlet weak var checkBox:UIImageView?
    @IBOutlet weak var nameLabel:UILabel?
    @IBOutlet weak var avatar:UIImageView?
    
    var cellTintColor = kDayCellBackgroundColor
    
    var displayMode:DisplayMode = .Day{
        didSet{
            if displayMode == .Day
            {
                nameLabel?.textColor = UIColor.blackColor()
                cellTintColor = kDayCellBackgroundColor
                avatar?.tintColor = kDayCellBackgroundColor
            }
            else
            {
                nameLabel?.textColor = UIColor.lightGrayColor()
                cellTintColor = kWhiteColor
                avatar?.tintColor = kWhiteColor
            }
            checkBox?.tintColor = cellTintColor
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.avatar?.maskToCircle()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setDisabled(disabled:Bool)
    {
        if disabled
        {
            checkBox?.tintColor = cellTintColor.colorWithAlphaComponent(0.5)
        }
        else
        {
            checkBox?.tintColor = cellTintColor
        }
    }

}
