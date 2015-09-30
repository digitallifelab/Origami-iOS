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

        nameField.layer.cornerRadius = 5.0
        passwordField.layer.cornerRadius = 5.0
        
        nameField.delegate = self
        passwordField.delegate = self
        // Do any additional setup after loading the view.
        
        let userName = NSUserDefaults.standardUserDefaults().objectForKey(loginNameKey) as? String
        let password = NSUserDefaults.standardUserDefaults().objectForKey(passwordKey) as? String
        
        nameField.text = userName
        passwordField.text = password
        
        loginButton.setTitle("LoginButtonTitle".localizedWithComment(""), forState: .Normal)
        self.view.backgroundColor = kDayNavigationBarBackgroundColor
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let name = nameField.text, password = passwordField.text
        {
            if !name.characters.isEmpty && !password.characters.isEmpty
            {
                loginButtonPress(self.loginButton)
            }
        }
//        if nameField.text?.characters.isEmpty && /*!*/passwordField.text/*.isEmpty*/
//        {
//            loginButtonPress(self.loginButton)
//        }
    }
    
    @IBAction func loginButtonPress(sender:UIButton)
    {
        loginButton.enabled = false
        DataSource.sharedInstance.tryToGetUser {[weak self] (user, error) -> () in
            if let weakSelf = self
            {
                if let aUser = user
                {
                    weakSelf.userDidLogin(aUser)
                }
                else if let anError = error
                {
                    weakSelf.showAlertWithTitle("FailedToLogin:".localizedWithComment(""), message:anError.localizedDescription, cancelButtonTitle:"Close".localizedWithComment(""))
                }
                weakSelf.loginButton.enabled = true
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
            DataSource.sharedInstance.getMyContacts() //returns nil if empty and starts downloadingcontacts from server
        }
    }

//    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
//    {
//        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
//        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
//        alertController.addAction(closeAction)
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
    
    //MARK: UITextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        
        switch textField.tag
        {
        case 1:
            if passwordField.text?.characters.count > 0
            {
                textField.returnKeyType = UIReturnKeyType.Done
            }
            else
            {
                textField.returnKeyType = UIReturnKeyType.Next
            }
        case 2:
            if nameField.text?.characters.count > 0 //count(nameField.text) > 0
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
        
        if let name = nameField.text, password = passwordField.text
        {
            if name.characters.count > 0 && password.characters.count > 0
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
        }
        else
        {
            loginButton.enabled = false
        }
        return true
    }
    
    

}
