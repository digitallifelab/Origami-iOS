//
//  NewElementTextLabelCell.swift
//  Origami
//
//  Created by CloudCraft on 03.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class NewElementTextLabelCell: UITableViewCell {

    var isTitleCell:Bool = false{
            didSet{
                textContainerLabel.numberOfLines = (isTitleCell) ? 2 : 0
        }
    }
    
    var attributedText:NSAttributedString? = nil {
        didSet{
            textContainerLabel.attributedText = (attributedText != nil) ? attributedText : defaultAttributedText
        }
    }
    
    var defaultAttributedText:NSAttributedString = NSAttributedString(string:"add title", attributes: [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()])
    
    
    @IBOutlet var textContainerLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        textContainerLabel.attributedText = defaultAttributedText
        
    }

}
