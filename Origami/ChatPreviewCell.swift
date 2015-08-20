//
//  ChatPreviewCell.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatPreviewCell: UITableViewCell {

    @IBOutlet var avatarView:UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var dateLabel:UILabel!
    
    var displayMode:DisplayMode = .Day {
        didSet{
            if displayMode == .Night
            {
                self.messageLabel.textColor = UIColor.whiteColor()
                self.nameLabel.textColor = UIColor.lightGrayColor()
            }
            else
            {
                self.messageLabel.textColor = UIColor.blackColor()
                self.nameLabel.textColor = kDayNavigationBarBackgroundColor
            }
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        avatarView.backgroundColor = UIColor.clearColor()
        //avatarView.image = UIImage(named: "icon-contacts")
        avatarView.maskToCircle()
        self.backgroundColor = UIColor.clearColor() //needed for ipad - ignores this setting in I.B.
        
    }

    
//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }

}
