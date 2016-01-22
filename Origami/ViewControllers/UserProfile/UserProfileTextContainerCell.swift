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
    
    weak var delegate:UserProfileCollectionCellDelegate?
    
    var textView:UITextView?
    var passwordTextField:UITextField?
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
    
    var editingEnabled = false {
        didSet{
            if editingEnabled
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
            else
            {
                editButton?.hidden = true
            }
        }
    }
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day:
                textLabel?.textColor = kDayCellBackgroundColor
                editButton?.tintColor = kDayCellBackgroundColor
                //self.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.7)
            case .Night:
                textLabel?.textColor = kWhiteColor
                editButton?.tintColor = kWhiteColor
                //self.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.5)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textView?.removeFromSuperview()
        textView = nil
        
    }
    
    @IBAction func editButtonTapped(sender:UIButton?)
    {
        if cellType == .Email
        {return}
            
        delegate?.changeInfoPressed(cellType)
    }
    
    func enableTextView(initialText:String?)
    {
        if self.cellType == .Password
        {
            self.enableTextField()
            return
        }
        
        let textViewFrame = CGRectMake(textLabel!.frame.origin.x, textLabel!.frame.origin.y, self.bounds.size.width - 5, ceil(textLabel!.frame.size.height) )
        self.textView = UITextView(frame: textViewFrame)
        
        textView?.font = textLabel?.font ?? UIFont.systemFontOfSize(16.0)
        textView?.scrollEnabled = (self.cellType == .Mood) ? true : false
        textView?.backgroundColor = UIColor.whiteColor()
        textView?.layer.borderWidth = 1.0
        textView?.layer.cornerRadius = 3.0
        textView?.tintColor = kDayCellBackgroundColor
        textView?.textColor = (self.displayMode == .Day) ? kBlackColor : kWhiteColor
        textView?.tag = self.cellType.rawValue

        textView?.textContainerInset = UIEdgeInsetsZero;
        
        textView?.text = initialText
        
        if textView?.text == nil || textView?.text == ""
        {
            textView?.text = textLabel?.text
        }
        
        if cellType == .PhoneNumber
        {
            textView?.keyboardType = .PhonePad
        }
        
        self.addSubview(textView!)
        self.bringSubviewToFront(textView!)
        
    }
    
    func startEditingText()
    {
        if cellType == .Password
        {
            if let textField = self.passwordTextField
            {
                textField.layer.borderWidth = 1.0
                textField.layer.borderColor = kDayNavigationBarBackgroundColor.CGColor
                textField.becomeFirstResponder()
            }
            return
        }
        
        if let textView = self.textView
        {
            textView.becomeFirstResponder()
        }
    }
    
    func stopEditingText()
    {
        textView?.resignFirstResponder()
        textView?.removeFromSuperview()
        passwordTextField?.resignFirstResponder()
        passwordTextField?.removeFromSuperview()
    }
    
    //MARK: UITextField for editing password
    
    func enableTextField()
    {
        if let passwordFrame = self.textLabel?.frame
        {
            passwordTextField = UITextField(frame: passwordFrame)
        }
        
        if let passTextField = passwordTextField
        {
            passwordTextField?.tag = cellType.rawValue //.Password
            passTextField.secureTextEntry = true // make in textVIew. textField does not have any effect with passwords
            passTextField.keyboardType = UIKeyboardType.Default
            //passTextField.text = "password"
            passTextField.userInteractionEnabled = true
            passTextField.backgroundColor = kWhiteColor
            passTextField.returnKeyType = UIReturnKeyType.Send
            
            self.addSubview(passTextField)
            self.bringSubviewToFront(passTextField)
        }
    }
}
