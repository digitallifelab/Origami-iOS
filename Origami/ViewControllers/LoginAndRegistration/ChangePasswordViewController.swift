//
//  ChangePasswordViewController.swift
//  Origami
//
//  Created by CloudCraft on 11.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

protocol PasswordChangeDelegate: class
{
    func userDidChangePassword(newPassword:String?, sender:ChangePasswordViewController)
}

class ChangePasswordViewController: UIViewController, UITextFieldDelegate
{
    @IBOutlet weak var passwordField:UITextField!
    @IBOutlet weak var confirmField:UITextField!
    @IBOutlet weak var centerView:UIView!
    lazy var topConstraint:NSLayoutConstraint = NSLayoutConstraint(item: self.centerView, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 150.0)
    
    
    weak var delegate:PasswordChangeDelegate?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let leftViewFrame = CGRectMake(0, 0, 10.0, 10.0)
        let passLeftView = UIView(frame: leftViewFrame)
        let confirmLeftView = UIView(frame: leftViewFrame)
        
        passwordField.leftViewMode = .Always
        passwordField.leftView = passLeftView
        confirmField.leftViewMode = .Always
        confirmField.leftView = confirmLeftView
        
        passwordField.tag = 1
        confirmField.tag = 2
        
        passwordField.layer.cornerRadius = 6.0
        confirmField.layer.cornerRadius = 6.0
        
        self.view.backgroundColor = kDayNavigationBarBackgroundColor
    }

    
    func textFieldDidBeginEditing(textField: UITextField) {
        let currentScreenHeight = UIScreen.mainScreen().bounds.size.height
        if currentScreenHeight < 500
        {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.view.addConstraint(self.topConstraint)
            })
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if let text = textField.text where text.characters.count > 3
        {
            switch textField.tag
            {
            case 1:
                return true
            case 2:
                return true
            default:
                break
            }
        }
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.view.removeConstraint(self.topConstraint)
            }) { (finished) -> Void in
                
        }
        
        
        guard let lvUser = DataSource.sharedInstance.user else
        {
            return
        }
        
        if let text1 = passwordField.text, text2 = confirmField.text where text1.characters.count > 0 && text2.characters.count > 0
        {
            if  text1 == text2 && text1.characters.count > 3
            {
                // send password change request to server
                //let oldPassword = lvUser.password
                lvUser.password = text1
                DataSource.sharedInstance.editUserInfo({[weak self] (success, error) -> () in
                    if success
                    {
                        if let weakSelf = self
                        {
                            dispatch_async(dispatch_get_main_queue()){
                                weakSelf.delegate?.userDidChangePassword(text1, sender: weakSelf)
                            }
                        }
                    }
                    else
                    {
                        if let weakSelf = self
                        {
                            dispatch_async(dispatch_get_main_queue()){
                                weakSelf.delegate?.userDidChangePassword(nil, sender: weakSelf)
                            }
                        }
                    }
                    })
            }
            else
            {
                showAlertWithTitle("Password Error".localizedWithComment(""), message: "Note: Password has to be longer than 3 characters", cancelButtonTitle: "Close".localizedWithComment(""))
            }
            
        }
        
    
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        textField.text = ""
        return true
    }
    
    
    
}
