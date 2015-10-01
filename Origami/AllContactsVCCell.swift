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
            print("current mine = \(self.contactIsMine)")
            if contactIsMine{
                selectionIndicator?.image = UIImage(named:"icon-checked")?.imageWithRenderingMode(.AlwaysTemplate)
            }
            else{
                selectionIndicator?.image = UIImage(named:"icon-unchecked")?.imageWithRenderingMode(.AlwaysTemplate)
            }
            
//            switch contactIsMine
//            {   case contactIsMine:// == true:
//                    selectionIndicator?.image = UIImage(named:"icon-checked")?.imageWithRenderingMode(.AlwaysTemplate)
//                
//                case !contactIsMine:// == false:
//                    selectionIndicator?.image = UIImage(named:"icon-unchecked")?.imageWithRenderingMode(.AlwaysTemplate)
//                
//                default:
//                    selectionIndicator?.image = UIImage(named:"icon-unchecked")?.imageWithRenderingMode(.AlwaysTemplate)
//            }
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
