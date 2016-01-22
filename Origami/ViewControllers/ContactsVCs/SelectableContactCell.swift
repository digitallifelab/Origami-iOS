//
//  SelectableContactCell.swift
//  Origami
//
//  Created by CloudCraft on 11.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SelectableContactCell: UITableViewCell {

    @IBOutlet weak var avatarImageView:UIImageView?
    @IBOutlet weak var contactNameLabel:UILabel?
    @IBOutlet weak var selectionIndicator:UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionIndicator?.tintColor = kDayCellBackgroundColor
        selectionIndicator?.hidden = true
    }
    override func layoutSubviews()
    {
        super.layoutSubviews()
        avatarImageView?.maskToCircle()
    }
    
//    func setSelectedContact(selected:Bool)
//    {
//        self.selectionIndicator?.hidden = !selected
//    }
    override func setSelected(selected: Bool, animated: Bool) {
        //super.setSelected(selected, animated: animated)
        self.selectionIndicator?.hidden = !selected
        super.setSelected(selected, animated: animated)
    }

}
