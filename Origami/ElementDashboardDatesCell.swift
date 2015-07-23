//
//  ElementDashboardDetailsCell.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit



class ElementDashboardDatesCell: UITableViewCell //cell containc information about ELEMENT dateCreated, dateChanged, dateFinished
{
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var dateLael:UILabel!
    
    var displayMode:DisplayMode = .Day{
        didSet{
            if displayMode == .Night
            {
                dateLael.textColor = UIColor.whiteColor()
            }
            else
            {
                dateLael.textColor = UIColor.blackColor()
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clearColor()
    }

//    override func setSelected(selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//
//        // Configure the view for the selected state
//    }
    
    

}
