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
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        avatarImageView?.maskToCircle()
    }
    

}
