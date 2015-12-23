//
//  LoginVC.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

protocol LoginViewControllerDelegate:class{
    func loginViewControllerShouldInformUserToCheckEmail(viewController:LoginVC) -> Bool
}

class LoginVC: UIViewController , UITextFieldDelegate
{
    @IBOutlet var nameField:UITextField!
    @IBOutlet var passwordField:UITextField!
    @IBOutlet var loginButton:UIButton!
    @IBOutlet var registrationButton:UIButton!
    
    var alertInfoToShowAfterAppearance:[String:String]?
    weak var delegate:LoginViewControllerDelegate?
    
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
        registrationButton.setTitle("RegistrationScreenTitle".localizedWithComment(""), forState: .Normal)
        
        self.view.backgroundColor = kDayNavigationBarBackgroundColor
        
        let leftViewName = UIView(frame: CGRectMake(0, 0, 16, 10))
        nameField.leftViewMode = .Always
        nameField.leftView = leftViewName
        let leftViewPass = UIView(frame: CGRectMake(0, 0, 16, 10))
        passwordField.leftViewMode = .Always
        passwordField.leftView = leftViewPass
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        #if SHEVCHENKO
            self.registrationButton.hidden = true
        #endif
        if let delegate = self.delegate, font = UIFont(name: "SegoeUI", size: 20.0)
        {
            if delegate.loginViewControllerShouldInformUserToCheckEmail(self)
            {
                let attributes = [NSFontAttributeName:font, NSForegroundColorAttributeName:UIColor.brownColor().colorWithAlphaComponent(0.7)]
                passwordField.attributedPlaceholder = NSAttributedString(string: "tempPassword".localizedWithComment(""), attributes: attributes)
                alertInfoToShowAfterAppearance = ["title":"attention".localizedWithComment(""),"message":"checkEmailForRegistrationPassword".localizedWithComment("")]
            }
        }
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let alertInfo = alertInfoToShowAfterAppearance, title = alertInfo["title"], message = alertInfo["message"]
        {
            loginButton.enabled = false
            showAlertWithTitle(title, message: message, cancelButtonTitle: "Ok")
            DataSource.sharedInstance.stopRefreshingNewMessages()
            alertInfoToShowAfterAppearance?.removeAll()
        }
        else
        {
            if let name = nameField.text, password = passwordField.text
            {
                if !name.characters.isEmpty && !password.characters.isEmpty
                {
                    loginButtonPress(self.loginButton)
                }
            }
        }
    
    }
    
    @IBAction func loginButtonPress(sender:UIButton)
    {
        loginButton.enabled = false
        DataSource.sharedInstance.tryToGetUser {[weak self] (user, error) -> () in
            if let weakSelf = self
            {
                if let aUser = user
                {
                    switch aUser.state
                    {
                    case .Normal:
                         weakSelf.userDidLogin(aUser)
                    case .NeedToConfirm:
                        print("\n ! A User is not activated yet.-> MUST change passford.\n")
                        DataSource.sharedInstance.user = user
                        weakSelf.dismissViewControllerAnimated(true, completion: nil)
                    case .Blocked: 
                         weakSelf.showAlertWithTitle("FailedToLogin:".localizedWithComment(""), message:"YouAreBlocked".localizedWithComment(""), cancelButtonTitle:"Close".localizedWithComment(""))
                    default:
                        weakSelf.showAlertWithTitle("FailedToLogin", message: "Unknown User Type", cancelButtonTitle: "Close".localizedWithComment(""))
                    }
                }
                else if let anError = error
                {
                    weakSelf.showAlertWithTitle("FailedToLogin:".localizedWithComment(""), message:anError.localizedDescription, cancelButtonTitle:"Close".localizedWithComment(""))
                }
                weakSelf.loginButton.enabled = true
            }
        }
    }
    
    #if !SHEVCHENKO
    @IBAction func registrationButtonPress(sender:UIButton)
    {
        if let authManagerVC = self.presentingViewController as? AuthorizationManagerViewController
        {
            sender.enabled = false
            
            authManagerVC.presentRegistrationViewController(self)
        }
    }
    #endif
    func userDidLogin(user:User)
    {
        guard let _ = user.userId else
        {
            print("No User Id Found After Login ..............\n ...............")
            return
        }
        
        guard user.userName.characters.count > 0 else
        {
            print("No User Email Found in Current User..........\n..........")
            return
        }
        
        DataSource.sharedInstance.user = user
        NSUserDefaults.standardUserDefaults().setObject(nameField.text, forKey: loginNameKey)
        NSUserDefaults.standardUserDefaults().setObject(passwordField.text, forKey: passwordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
     
        
            
        let contactsOperation = NSBlockOperation() { _ in
            
            do{
                 try DataSource.sharedInstance.getMyContacts() //returns nil if empty and starts downloadingcontacts from server
                
                DataSource.sharedInstance.downloadMyContactsFromServer({ (didSaveToLocalDatabase, error) -> () in
                    
                })
            }
            catch{
                
                let waiterGroup = dispatch_group_create()
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 30.0))
                dispatch_group_enter(waiterGroup)
                
                DataSource.sharedInstance.downloadMyContactsFromServer { (didSaveToLocalDatabase, error) -> () in
                    dispatch_group_leave(waiterGroup)
                }
                
                dispatch_group_wait(waiterGroup, timeout)
            }
        }
        
        
        let avatarsPreviewFromDatabaseOperation = NSBlockOperation() { _ in
            
            DataSource.sharedInstance.localDatadaseHandler?.preloadSavedAvatarPreviewsToDataSource { (imagesDict, error) -> () in
                if let imagesInfo = imagesDict
                {
                    DataSource.sharedInstance.userAvatarsHolder = imagesInfo
                    print(" __ Did read avatars from database into memory: ")
                    print(" avatars: \(imagesInfo.count)")
                }
            }
        }
        
        
        
        let messagesSyncOperation = NSBlockOperation() { _ in
            
            if let lastMessageId = DataSource.sharedInstance.localDatadaseHandler?.getLatestMessageId() where lastMessageId > 0
            {
                DataSource.sharedInstance.syncLastMessages(lastMessageId) { (finished, error) -> () in
                    if let _ = DataSource.sharedInstance.messagesLoader
                    {
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                    else
                    {
                        DataSource.sharedInstance.messagesLoader = MessagesLoader()
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                }
            }
            else
            {
               DataSource.sharedInstance.loadAllMessagesFromServer() { _ in
                    if let _ = DataSource.sharedInstance.messagesLoader
                    {
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                    else
                    {
                        DataSource.sharedInstance.messagesLoader = MessagesLoader()
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
               }
            }
        }
        
        messagesSyncOperation.addDependency(contactsOperation)
        avatarsPreviewFromDatabaseOperation.addDependency(contactsOperation)
        
        if #available(iOS 8.0, *) {
            
            let qosPriority = NSQualityOfService.Utility
            
            avatarsPreviewFromDatabaseOperation.qualityOfService = qosPriority
            messagesSyncOperation.qualityOfService = qosPriority
        }
        else
        {
            let queuePriority = NSOperationQueuePriority.Low
            
            avatarsPreviewFromDatabaseOperation.queuePriority = queuePriority
            messagesSyncOperation.queuePriority = queuePriority
        }
        
    
        DataSource.sharedInstance.operationQueue.suspended = true
        DataSource.sharedInstance.operationQueue.addOperations([contactsOperation, avatarsPreviewFromDatabaseOperation, messagesSyncOperation], waitUntilFinished: false)
    
       self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
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
