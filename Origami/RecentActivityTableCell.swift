//
//  RecentActivityTableCell.swift
//  Origami
//
//  Created by CloudCraft on 10.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RecentActivityTableCell: UITableViewCell {

    @IBOutlet weak var elementTitleLabel:UILabel?
    @IBOutlet weak var elementDetailsTextView:UITextView?
    
    var aTextColor = kWhiteColor
    
    var displayMode:DisplayMode = .Day
        {
        didSet{
            switch self.displayMode
            {
            case .Day:
                self.backgroundColor = kDayCellBackgroundColor
            case .Night:
                self.backgroundColor = kBlackColor
            }
            //self.setNeedsDisplay()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        elementTitleLabel?.textColor = aTextColor
        elementDetailsTextView?.textColor = aTextColor
    }

}
