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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let name = nameField.text, password = passwordField.text
        {
            if !name.characters.isEmpty && !password.characters.isEmpty
            {
                loginButtonPress(self.loginButton)
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
                    switch aUser.state{
                    case .Normal:
                         weakSelf.userDidLogin(aUser)
                    case .NeedToConfirm:
                        print("\n ! A User is not activated yet.-> MUST change passford.\n")
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
    
    func userDidLogin(user:User)
    {
        guard let loggedUserID = user.userId else
        {
            print("No User Id Found After Login ..............\n ...............")
            return
        }
        
        DataSource.sharedInstance.user = user
        NSUserDefaults.standardUserDefaults().setObject(nameField.text, forKey: loginNameKey)
        NSUserDefaults.standardUserDefaults().setObject(passwordField.text, forKey: passwordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        self.dismissViewControllerAnimated(true, completion: nil)
        NSOperationQueue().addOperationWithBlock { _ in
            
            let userName = user.userName
            if userName == ""
            {
                print("No User Email Found in Current User..........\n..........")
                return
            }
            
            DataSource.sharedInstance.getMyContacts() //returns nil if empty and starts downloadingcontacts from server
            if let lastMessageId = DataSource.sharedInstance.localDatadaseHandler?.getLatestMessageId()
            {
                DataSource.sharedInstance.syncLastMessages(lastMessageId, completion: { (finished, error) -> () in
                    if let _ = DataSource.sharedInstance.messagesLoader
                    {
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                    else
                    {
                        DataSource.sharedInstance.messagesLoader = MessagesLoader()
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                })
            }
            else
            {
                DataSource.sharedInstance.syncLastMessages(completion: { (finished, error) -> () in
                    if let _ = DataSource.sharedInstance.messagesLoader
                    {
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                    else
                    {
                        DataSource.sharedInstance.messagesLoader = MessagesLoader()
                        DataSource.sharedInstance.startRefreshingNewMessages()
                    }
                })
            }
            
            DataSource.sharedInstance.localDatadaseHandler?.preloadSavedAvatarPreviewsToDataSource { (imagesDict, error) -> () in
                if let imagesInfo = imagesDict
                {
                    DataSource.sharedInstance.userAvatarsHolder = imagesInfo
                    print(" __ Did read avatars from database into memory: ")
                    print(" avatars: \(imagesInfo.count)")
                }
            }
            
            let fileHandle = FileHandler()
            if let fileNames = fileHandle.getAllExistingAvatarsPreviewFileNames()
            {
                for userName in fileNames
                {
                    let fixedUserName = userName.stringByReplacingOccurrencesOfString(".jpg", withString: "")
                    if fixedUserName == userName
                    {
                        fileHandle.loadAvatarDataForLoginName(fixedUserName) { (fullImageData, fileError) -> () in
                            if let error = fileError
                            {
                                print("\n -> Could not find requested user avatar... : ")
                                print(error)
                            }
                            else if let fullData = fullImageData, fullImage = UIImage(data: fullData), reducedImage = fullImage.scaleToSizeKeepAspect(CGSizeMake(200.0, 200.0))
                            {
                                DataSource.sharedInstance.userAvatarsHolder[loggedUserID] = reducedImage // to ram
                                
                                // and to local database for next time launch readiness
                                if let reducedImageData = UIImageJPEGRepresentation(reducedImage, 1.0)
                                {
                                    DataSource.sharedInstance.localDatadaseHandler?.saveAvatarPreview(reducedImageData, forUserId: loggedUserID, fileName: fixedUserName)
                                }
                            }
                        }
                    }
                    else
                    {
                        if let foundPerson = DataSource.sharedInstance.localDatadaseHandler?.findPersonByUserName(fixedUserName) as? DBContact , userId = foundPerson.contactId?.integerValue
                        {
                            if let avatarPreviewData = DataSource.sharedInstance.localDatadaseHandler?.readAvatarPreviewForContactId(userId), previewImage = UIImage(data: avatarPreviewData)
                            {
                                DataSource.sharedInstance.userAvatarsHolder[userId] = previewImage
                            }
                            else
                            {
                                fileHandle.loadAvatarDataForLoginName(fixedUserName) { (fullImageData, fileError) -> () in
                                    if let error = fileError
                                    {
                                        print("\n -> Could not find requested user avatar... : ")
                                        print(error)
                                    }
                                    else if let fullData = fullImageData, fullImage = UIImage(data: fullData), reducedImage = fullImage.scaleToSizeKeepAspect(CGSizeMake(200.0, 200.0))
                                    {
                                        DataSource.sharedInstance.userAvatarsHolder[userId] = reducedImage // to ram
                                        
                                        // and to local database for next time launch readiness
                                        if let reducedImageData = UIImageJPEGRepresentation(reducedImage, 1.0)
                                        {
                                            DataSource.sharedInstance.localDatadaseHandler?.saveAvatarPreview(reducedImageData, forUserId: userId, fileName: fixedUserName)
                                        }
                                    }
                                }
                            }
                        }

                    }
                }
            }
        }
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
