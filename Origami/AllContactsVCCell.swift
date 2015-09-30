//
//  AllContactsVCCellTableViewCell.swift
//  Origami
//
//  Created by CloudCraft on 18.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class AllContactsVCCell: UITableViewCell {

    @IBOutlet weak var nameLabel:UILabel?
    @IBOutlet weak var moodLabel:UILabel?
    @IBOutlet weak var selectionIndicator:UIImageView?
    @IBOutlet weak var avatarImageView:UIImageView?
    
    var contactIsMine:Bool = false {
        didSet{
            switch contactIsMine
            {   case contactIsMine == true:
                    selectionIndicator?.image = UIImage(named:"icon-checked")?.imageWithRenderingMode(.AlwaysTemplate)
                case contactIsMine == false:
                    selectionIndicator?.image = UIImage(named:"icon-unchecked")?.imageWithRenderingMode(.AlwaysTemplate)
                default:break
            }
        }
    }
    
    override func awakeFromNib()
    {
        if let imageView = self.avatarImageView
        {
            imageView.maskToCircle()
        }
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        avatarImageView?.tintColor = kDayCellBackgroundColor
        selectionIndicator?.tintColor = kDayCellBackgroundColor
    }
}
