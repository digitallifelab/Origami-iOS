//
//  ChatTextInputView.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatTextInputView: UIView, UITextViewDelegate {

    
    @IBOutlet var textView:UITextView!
    @IBOutlet var sendButton:UIButton!
    @IBOutlet var attachButton:UIButton!
    var delegate:ChatInputViewDelegate?
    
    var displayMode:DisplayMode = .Day {
        didSet{
            
            switch displayMode{
                
                case .Day:
                    sendButton.tintColor = kDayNavigationBarBackgroundColor
                    attachButton.tintColor = kDayNavigationBarBackgroundColor
                    self.backgroundColor = kWhiteColor
                    textView.tintColor = kDayNavigationBarBackgroundColor
                    
                case .Night:
                    sendButton.tintColor = kWhiteColor
                    attachButton.tintColor = kWhiteColor
                    self.backgroundColor = UIColor.clearColor()
                    textView.tintColor = kBlackColor
            }
        }
    }
    
    let emptyAttributedText = NSAttributedString(string: "TapToType".localizedWithComment(""), attributes:[NSForegroundColorAttributeName:UIColor.lightGrayColor(), NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!] /*as [NSObject:AnyObject]*/)
    
    
    
    override func awakeFromNib() {
        self.sendButton.setImage(UIImage(named: "icon-send")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.attachButton.setImage(UIImage(named: "icon-attach")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
    
    //MARK: Actions
    @IBAction func sendButtonTapped(sender:UIButton)
    {
        self.delegate?.chatInputView(self, sendButtonTapped: sender)
    }
    
    @IBAction func attachButtonTapped(sender:UIButton)
    {
        self.delegate?.chatInputView(self, attachButtonTapped: sender)
    }
    
    func endTyping(clearText clear:Bool)
    {
        if clear
        {
            textView.attributedText = emptyAttributedText
            sendButton.enabled = false
        }
        
        textView.resignFirstResponder()
    }
    
    //MARK: UITextViewDelegate
    func textViewDidChange(textView: UITextView)
    {
        if let text = textView.text
        {
            if text.isEmpty
            {
                sendButton.enabled = false
            }
            else
            {
                sendButton.enabled = true
            }
            let lvTestSize = textView.sizeThatFits( CGSizeMake( textView.bounds.size.width, CGFloat.max))
            
            if textView.bounds.size.height != lvTestSize.height
            {
                self.delegate?.chatInputView(self, wantsToChangeToNewSize:lvTestSize)
            }
        }
        else
        {
            sendButton.enabled = false
        }
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        textView.attributedText = nil
        textView.textColor = UIColor.blackColor()
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        
        return true
    }

}
