//
//  AuthorizationManagerViewController.swift
//  Origami
//
//  Created by Ivan Yavorin on 12/20/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

class AuthorizationManagerViewController: UIViewController, PasswordChangeDelegate, RegistrationViewControllerDelegate, LoginViewControllerDelegate {

    
    var shouldShowLoginVC = true
    private var isOneTimePasswordWarningEnabled = false
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        guard let user = DataSource.sharedInstance.user else //show Login screen after timeout
        {
            if shouldShowLoginVC
            {
                let timeOut = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
                dispatch_after(timeOut, dispatch_get_main_queue()){[weak self] in
                    
                    if let weakSelf = self
                    {
                        weakSelf.presentLoginViewController()
                    }
                }
            }
            return
        }
        
        switch user.state
        {
        case .Normal:
            //break
            switchWindowRootViewControllerToRootViewController() //start using the app
        case .Blocked:
            showAlertWithTitle("Warning".localizedWithComment(""), message: "BlockedUserMessage".localizedWithComment(""), cancelButtonTitle: "Close".localizedWithComment(""))
            return
        case .NeedToConfirm:
            presentChangePasswordVC() //user has to change password after registration
            return
        case .Undefined:
            showAlertWithTitle("Error".localizedWithComment(""), message: "UnknownError".localizedWithComment(""), cancelButtonTitle: "Close".localizedWithComment(""))
        }
    }
    

    func presentLoginViewController()
    {
        if let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as? LoginVC
        {
            if isOneTimePasswordWarningEnabled
            {
                loginVC.delegate = self
            }
            self.presentViewController(loginVC, animated: true, completion: nil)
        }
    }
    
    func presentRegistrationViewController(sender:AnyObject)
    {
        if let loginVC = self.presentedViewController
        {
            shouldShowLoginVC = false
            loginVC.dismissViewControllerAnimated(true, completion: {[unowned self] () -> Void in
                if let regVC = self.storyboard?.instantiateViewControllerWithIdentifier("RegistrationVC") as? RegistrationVC
                {
                    regVC.delegate = self
                    self.presentViewController(regVC, animated: true, completion: nil)
                }
            })
        }
        else
        {
            if let regVC = self.storyboard?.instantiateViewControllerWithIdentifier("RegistrationVC") as? RegistrationVC
            {
                shouldShowLoginVC = false
                regVC.delegate = self
                self.presentViewController(regVC, animated: true, completion: nil)
            }
        }
    }
    
    
    func presentChangePasswordVC()
    {
        if let passwordChangeVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChangePasswordVC") as? ChangePasswordViewController
        {
            shouldShowLoginVC = false
            passwordChangeVC.delegate = self
            
            self.presentViewController(passwordChangeVC, animated: true, completion: nil)
        }
    }
    
    //MARK: - PasswordChangeDelegate
    func userDidChangePassword(newPassword: String?, sender: ChangePasswordViewController) {
        
        shouldShowLoginVC = true
        isOneTimePasswordWarningEnabled = false
        guard let newPasswordString = newPassword else
        {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(passwordKey)
            return
        }
        
        DataSource.sharedInstance.user = nil
        NSUserDefaults.standardUserDefaults().setObject(newPasswordString, forKey: passwordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        sender.dismissViewControllerAnimated(true, completion:nil)
    }
    
    //MARK: - LoginViewControllerDelegate
    func loginViewControllerShouldInformUserToCheckEmail(viewController: LoginVC) -> Bool {
        return self.isOneTimePasswordWarningEnabled
    }
    
    //MARK: - RegistrationViewControllerDelegate
    func userDidRegister(user:User?, sender:AnyObject?)
    {
        shouldShowLoginVC = true
        
        DataSource.sharedInstance.user = nil
        if let userName = user?.userName
        {
            NSUserDefaults.standardUserDefaults().setObject(userName, forKey: loginNameKey)
            isOneTimePasswordWarningEnabled = true
        }
        else
        {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(loginNameKey)
        }
       
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if let registrationVC = self.presentedViewController
        {
            registrationVC.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    //MARK: - Switch to RootViewController with HomeVC and MenuVC
    func switchWindowRootViewControllerToRootViewController()
    {
        if let rootVC = self.storyboard?.instantiateViewControllerWithIdentifier("RootVC") as? RootViewController, delegate = UIApplication.sharedApplication().delegate as? AppDelegate, aWindow = delegate.window
        {
            aWindow.rootViewController = rootVC
        }
    }
}
