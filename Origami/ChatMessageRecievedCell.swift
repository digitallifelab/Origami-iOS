//
//  ChatMessageRecievedCell.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatMessageRecievedCell: UITableViewCell {

    @IBOutlet var avatar:UIImageView!
    @IBOutlet var dateLabel:UILabel!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
