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
            let attributes = [NSForegroundColorAttributeName:UIColor.lightGrayColor(), NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!] as [NSObject:AnyObject]
            let attributedText = NSAttributedString(string: "Tap to start typing", attributes:attributes)
            
            textView.attributedText = attributedText
            
            
        }
        textView.resignFirstResponder()
    }
    //MARK: UITextViewDelegate
    func textViewDidChange(textView: UITextView)
    {
        if let text = textView.text
        {
            //let lvDesiredFrame = FrameCounter.calculateFrameForTextView(textView, text: text, targetWidth: textView.bounds.size.width)
            let lvTestSize = textView.sizeThatFits( CGSizeMake( textView.bounds.size.width, CGFloat.max))
            
            if textView.bounds.size.height != lvTestSize.height
            {
                self.delegate?.chatInputView(self, wantsToChangeToNewSize:lvTestSize)
            }
            
        }
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        
        return true
    }

}
