//
//  UserProfileTextContainerCell.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileTextContainerCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel:UILabel?
    @IBOutlet weak var textLabel:UILabel?
    @IBOutlet weak var editButton:UIButton?
    
    var delegate:UserProfileAvatarCollectionCellDelegate?
    
    var textView:UITextView?
    
    var cellType:ProfileTextCellType = .Email
        {
        didSet
        {
            if cellType == .Email
            {
                editButton?.hidden = true
            }
            else
            {
                editButton?.hidden = false
            }
        }
    }
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day:
                textLabel?.textColor = kBlackColor
                editButton?.tintColor = kDayCellBackgroundColor
                self.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.7)
            case .Night:
                textLabel?.textColor = kWhiteColor
                editButton?.tintColor = kWhiteColor
                self.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.5)
            }
        }
    }
    
    @IBAction func editButtonTapped(sender:UIButton?)
    {
        if cellType == .Email
        {return}
            
        delegate?.changeInfoPressed(cellType)
    }
    
    func enableTextView(initialText:String?)
    {
        let textViewFrame = CGRectMake(textLabel!.frame.origin.x, textLabel!.frame.origin.y, self.bounds.size.width - 5, ceil(textLabel!.frame.size.height) )
        self.textView = UITextView(frame: textViewFrame)
        
        textView?.font = textLabel?.font ?? UIFont.systemFontOfSize(16.0)
        textView?.scrollEnabled = (self.cellType == .Mood) ? true : false
        textView?.backgroundColor = UIColor.whiteColor()
        textView?.layer.borderWidth = 2.0
        textView?.tintColor = kDayCellBackgroundColor
        textView?.textColor = (self.displayMode == .Day) ? kBlackColor : kWhiteColor
        textView?.tag = self.cellType.rawValue

        textView?.textContainerInset = UIEdgeInsetsZero;
        
        textView?.text = initialText
        if textView?.text == nil || textView?.text == ""
        {
            textView?.text = textLabel?.text
        }
        if self.cellType == .Password
        {
            textView?.secureTextEntry = true // make in textVIew. textField does not have any effect with passwords
            textView?.keyboardType = UIKeyboardType.Default
            textView?.userInteractionEnabled = false
        }
        else if cellType == .PhoneNumber
        {
            textView?.keyboardType = .PhonePad
        }
        self.addSubview(textView!)
        self.bringSubviewToFront(textView!)
        
    }
    
    func startEditingText()
    {
        if let textView = self.textView
        {
            textView.becomeFirstResponder()
        }
    }
    
    func stopEditingText()
    {
        //textView?.resignFirstResponder()
        textView?.removeFromSuperview()
        textView = nil
    }
}
