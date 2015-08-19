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
    
    let emptyAttributedText = NSAttributedString(string: "TapToType".localizedWithComment(""), attributes:[NSForegroundColorAttributeName:UIColor.lightGrayColor(), NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!] as [NSObject:AnyObject])
    
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
//            let attributes = [NSForegroundColorAttributeName:UIColor.lightGrayColor(), NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!] as [NSObject:AnyObject]
//            let attributedText = NSAttributedString(string: "TapToType".localizedWithComment(""), attributes:attributes)
            
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
            //let lvDesiredFrame = FrameCounter.calculateFrameForTextView(textView, text: text, targetWidth: textView.bounds.size.width)
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
