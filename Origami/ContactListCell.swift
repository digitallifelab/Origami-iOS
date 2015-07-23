//
//  ContactListCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactListCell: UITableViewCell {

    
    @IBOutlet var avatar:UIImageView!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var favouriteButton:UIButton!
    
    var delegate:ButtonTapDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func favouriteButtonNapped(sender:UIButton?)
    {
        if sender != nil
        {
            delegate?.didTapOnButton(sender!)
        }
    }

}
