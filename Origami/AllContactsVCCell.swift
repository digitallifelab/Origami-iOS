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
    //@IBOutlet weak var emailLabel:UILabel?
    //@IBOutlet weak var phoneNumber:UILabel?
    @IBOutlet weak var moodLabel:UILabel?
    @IBOutlet weak var selectionIndicator:UIImageView?
    @IBOutlet weak var avatarImageView:UIImageView?
    
    var contactIsMine:Bool = false {
        didSet{
            switch contactIsMine
            {   case true:
                    selectionIndicator?.image = UIImage(named:"icon-checked")
                case false:
                    selectionIndicator?.image = UIImage(named:"icon-unchecked")
                default:break
            }
        }
    }
    
    override func prepareForReuse() {
        avatarImageView?.image = nil
    }
    
    override func awakeFromNib() {
        if let imageView = self.avatarImageView
        {
            imageView.maskToCircle()
        }
    }
}
