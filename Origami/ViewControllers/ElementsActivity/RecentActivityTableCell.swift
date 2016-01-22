//
//  RecentActivityTableCell.swift
//  Origami
//
//  Created by CloudCraft on 10.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RecentActivityTableCell: UITableViewCell {

    @IBOutlet weak var dateLabel:UILabel?
    @IBOutlet weak var elementTitleLabel:UILabel?
    @IBOutlet weak var elementDetailsTextView:UITextView?
    @IBOutlet weak var elementCreatorAvatar:UIImageView?
    @IBOutlet weak var ideaIcon:UIImageView?
    @IBOutlet weak var taskIcon:UIImageView?
    @IBOutlet weak var decisionIcon:UIImageView?
    @IBOutlet weak var nameLabel:UILabel?
    
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
        self.elementCreatorAvatar?.tintColor = kWhiteColor
        elementCreatorAvatar?.maskToCircle()
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        elementTitleLabel?.textColor = aTextColor
        elementDetailsTextView?.textColor = aTextColor
    }
    
    override func prepareForReuse() {
        elementCreatorAvatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
    }

}
