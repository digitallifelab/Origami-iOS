//
//  LoginVC.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class LoginVC: UIViewController , UITextFieldDelegate
{
    @IBOutlet var nameField:UITextField!
    @IBOutlet var passwordField:UITextField!
    @IBOutlet var loginButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameField.delegate = self
        passwordField.delegate = self
        // Do any additional setup after loading the view.
        
        var userName = NSUserDefaults.standardUserDefaults().objectForKey(loginNameKey) as? String
        var password = NSUserDefaults.standardUserDefaults().objectForKey(passwordKey) as? String
        
        nameField.text = userName
        passwordField.text = password
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonPress(sender:UIButton)
    {
        DataSource.sharedInstance.tryToGetUser {[weak self] (user, error) -> () in
            if let weakSelf = self
            {
                if let aUser = user
                {
                    weakSelf.userDidLogin(aUser)
                }
                else if let anError = error, let localizedDescription = error?.localizedDescription
                {
                    weakSelf.showAlertWithTitle("FailedToLogin:".localizedWithComment(""), message:localizedDescription, cancelButtonTitle:"Close".localizedWithComment(""))
                }
            }
            
            
        }// User(info: dict)
        
        
    }
    
    func userDidLogin(user:User)
    {
        DataSource.sharedInstance.user = user
        NSUserDefaults.standardUserDefaults().setObject(nameField.text, forKey: loginNameKey)
        NSUserDefaults.standardUserDefaults().setObject(passwordField.text, forKey: passwordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        self.dismissViewControllerAnimated(true, completion: nil)
        NSOperationQueue().addOperationWithBlock { () -> Void in
            DataSource.sharedInstance.getAllContacts()
        }
    }

    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        alertController.addAction(closeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        switch textField.tag
        {
        case 1:
            if count(passwordField.text) > 0
            {
                textField.returnKeyType = UIReturnKeyType.Done
            }
            else
            {
                textField.returnKeyType = UIReturnKeyType.Next
            }
        case 2:
            if count(nameField.text) > 0
            {
                textField.returnKeyType = UIReturnKeyType.Done
            }
            else
            {
                textField.returnKeyType = UIReturnKeyType.Next
            }
        default:
            textField.returnKeyType = .Default
            
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        if count(nameField.text) > 0 && count(passwordField.text) > 0
        {
            loginButton.enabled = true
            if textField.returnKeyType == .Done // autologin user
            {
                loginButton.enabled = false
                NSUserDefaults.standardUserDefaults().setObject(nameField.text, forKey: loginNameKey)
                NSUserDefaults.standardUserDefaults().setObject(passwordField.text, forKey: passwordKey)
                
                loginButtonPress(loginButton)
            }
        }
        else
        {
            loginButton.enabled = false
        }
        return true
    }
    
    

}
