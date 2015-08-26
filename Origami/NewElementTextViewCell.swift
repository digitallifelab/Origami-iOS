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
    
    @IBOutlet weak var textViewToBottomConstraint: NSLayoutConstraint!
    var attributedText:NSAttributedString? = nil {
        didSet{
            textView.attributedText = (attributedText != nil) ? attributedText : defaultAttributedText
//            if count(textView.attributedText.string) > 0
//            {
//                textView.sizeToFit()
//            }
            var textViewSize :CGSize = textView.contentSize
            println("ContenttSize: \(textViewSize)")
        }
    }
    
    var defaultAttributedText:NSAttributedString = NSAttributedString(string:"add title", attributes: [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()])
    
    var isTitleCell:Bool = false {
        didSet{
            if isTitleCell
            {
                self.backgroundColor = UIColor.whiteColor()//kDayCellBackgroundColor
                titleLabel.text = "Title".localizedWithComment("")
                defaultAttributedText = NSAttributedString(string:"add title", attributes: [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()])
                
                textViewToBottomConstraint.constant = 5.0
            }
            else
            {
                self.backgroundColor = UIColor.whiteColor()
                titleLabel.text = "Description".localizedWithComment("")
                defaultAttributedText = NSAttributedString(string:"add description", attributes: [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()])
                
                textViewToBottomConstraint.constant = 24.0
            }
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textView.layer.cornerRadius = 5.0
        textView.layer.borderWidth = 1.0
        textView.layer.borderColor = UIColor.lightGrayColor().CGColor
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
        println("test size: \(lvTestSize)")
        if textView.bounds.size.height != lvTestSize.height
        {
            NSNotificationCenter.defaultCenter().postNotificationName("UpdateTextiewCell", object: nil)
        }
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        textView.textColor = UIColor.blackColor()
        return true
    }
}
