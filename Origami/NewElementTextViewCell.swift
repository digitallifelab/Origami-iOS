//
//  NewElementTextViewCell.swift
//  Origami
//
//  Created by CloudCraft on 29.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class NewElementTextViewCell: UITableViewCell , UITextViewDelegate {

    @IBOutlet var textView:UITextView!
    @IBOutlet var titleLabel:UILabel!
    
    var attributedText:NSAttributedString? = nil {
        didSet{
            textView.attributedText = (attributedText != nil) ? attributedText : defaultAttributedText
            textView.sizeToFit()
        }
    }
    
    var defaultAttributedText:NSAttributedString = NSAttributedString(string:"add title", attributes: [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()])
    
    var isTitleCell:Bool = false {
        didSet{
            if isTitleCell
            {
                self.backgroundColor = kDayCellBackgroundColor
                titleLabel.text = "Title"
            }
            else
            {
                self.backgroundColor = UIColor.whiteColor()
                titleLabel.text = "Description"
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func startEditingText()
    {
        self.textView.becomeFirstResponder()
    }
    
    func endEditingText()
    {
        self.textView.resignFirstResponder()
    }

    func textViewDidChange(textView: UITextView) {
        let lvTestSize = textView.sizeThatFits( CGSizeMake( textView.bounds.size.width, CGFloat.max))
        
        if textView.bounds.size.height != lvTestSize.height
        {
            NSNotificationCenter.defaultCenter().postNotificationName("UpdateTextiewCell", object: nil)
        }
    }
}
