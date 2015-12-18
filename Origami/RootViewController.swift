//
//  RootViewController.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UIGestureRecognizerDelegate, PasswordChangeDelegate {
    
    
    var dataRefresher:DataRefresher?
    var screenEdgePanRecognizer:UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    var tapToDismissRecognizer:UITapGestureRecognizer = UITapGestureRecognizer()
    var leftMenuVC:MenuVC?
    var currentNavigationController:HomeNavigationController?
    
    var isShowingMenu = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let application = UIApplication.sharedApplication()
        
        if let appDelegate = application.delegate as? AppDelegate
        {
            appDelegate.rootViewController = self
        }
        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleLogoutNotification:", name: kLogoutNotificationName, object: nil)
        
        screenEdgePanRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: "leftEdgePan:")
        screenEdgePanRecognizer.edges = UIRectEdge.Left
        //screenEdgePanRecognizer?.delegate = self
        screenEdgePanRecognizer.delaysTouchesBegan = false
        //self.view.addGestureRecognizer(screenEdgePanRecognizer!)
        
        tapToDismissRecognizer = UITapGestureRecognizer(target: self, action: "tapToDismiss:")
        tapToDismissRecognizer.delegate = self;
        tapToDismissRecognizer.numberOfTapsRequired = 1;
        tapToDismissRecognizer.numberOfTouchesRequired = 1;

        DataSource.sharedInstance
        
        dispatch_async(getBackgroundQueue_UTILITY()) { () -> Void in
            DataSource.sharedInstance.createLocalDatabaseHandler { (dbInitialization) -> () in
                if dbInitialization == false
                {
                    print("\n  Could not create or initialize local database....\n")
                }
                else
                {
                    print("\n Did initialize local data base...\n")
                }
            }
        }
     
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        #else
            if #available (iOS 8.0, *)
            {
                let types: UIUserNotificationType = application.currentUserNotificationSettings()!.types
                if types.contains(.None)
                {
                    let settings = UIUserNotificationSettings(forTypes: [.Alert , .Badge , .Sound], categories: nil) //(forTypes: .Alert | .Badge | .Sound, categories: nil)
                    
                    application.registerUserNotificationSettings(settings)
                    //application.registerForRemoteNotifications()
                }
            }
            else
            {
                let types:UIRemoteNotificationType = application.enabledRemoteNotificationTypes()
                if types .contains(.None)
                {
                    application.registerForRemoteNotificationTypes([.Alert , .Badge , .Sound])
                }
            }
        #endif
        
        
        dispatch_async(getBackgroundQueue_CONCURRENT()) { () -> Void in
            DataSource.sharedInstance.getCountries({ (countries, error) -> () in
                if let recievedCountries = countries
                {
                    DataSource.sharedInstance.countries = recievedCountries
                }
            })
            
            DataSource.sharedInstance.getLanguages({ (languages, error) -> () in
                if let recievedLanguages = languages
                {
                    DataSource.sharedInstance.languages = recievedLanguages
                }
            })
        }
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
     
        showRegistrationVC()
        /*
        guard let user = DataSource.sharedInstance.user else
        {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Buton_Tapped_Notification_Name, object: nil)
            
            self.performSegueWithIdentifier("ShowLoginScreen", sender: nil)
            return
        }
        
        switch user.state
        {
            case .Normal:
                break
            case .Blocked:
                showAlertWithTitle("Warning".localizedWithComment(""), message: "BlockedUserMessage".localizedWithComment(""), cancelButtonTitle: "Close".localizedWithComment(""))
                return
            case .NeedToConfirm:
                showChangePasswordVC()
                return
            case .Undefined:
                showAlertWithTitle("Error".localizedWithComment(""), message: "UnknownError".localizedWithComment(""), cancelButtonTitle: "Close".localizedWithComment(""))
                return
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processMenuDisplaying:", name: kMenu_Buton_Tapped_Notification_Name, object: nil)
        
        if let navController = self.storyboard?.instantiateViewControllerWithIdentifier("HomeNavigationController") as? HomeNavigationController
        {
            self.addChildViewController(navController)
           
            if let _ = navController.viewControllers.first as? HomeVC
            {
                
            }
            else if let homeVC = self.storyboard?.instantiateViewControllerWithIdentifier("HomeVC") as? HomeVC
            {                
                navController.setViewControllers([homeVC], animated: true)
            }
            
            self.view.addSubview(navController.view)
            navController.didMoveToParentViewController(self)
            self.currentNavigationController = navController
            
            if let menuVC = self.storyboard?.instantiateViewControllerWithIdentifier("MenuVC") as? MenuVC
            {
                self.addChildViewController(menuVC)
                self.leftMenuVC = menuVC
                self.view.insertSubview(menuVC.view, belowSubview: currentNavigationController!.view)
                self.leftMenuVC?.didMoveToParentViewController(self)
            }
        }
        */
    }

    func showChangePasswordVC()
    {
        if let passwordChangeVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChangePasswordVC") as? ChangePasswordViewController
        {
            passwordChangeVC.delegate = self
            
            self.presentViewController(passwordChangeVC, animated: true, completion: nil)
        }
    }
    
    
    
  
    func handleLogoutNotification(notification:NSNotification?)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Buton_Tapped_Notification_Name, object: nil)
        DataSource.sharedInstance.dataRefresher?.stopRefreshingElements()
        DataSource.sharedInstance.dataRefresher = nil
        isShowingMenu = false
        
        DataSource.sharedInstance.performLogout {[weak self] () -> () in
            if let weakSelf = self
            {
                weakSelf.currentNavigationController?.willMoveToParentViewController(nil)
                weakSelf.currentNavigationController?.removeFromParentViewController()
                weakSelf.currentNavigationController?.view.removeFromSuperview()
                weakSelf.currentNavigationController?.didMoveToParentViewController(nil)
                weakSelf.currentNavigationController = nil
                
                weakSelf.leftMenuVC?.willMoveToParentViewController(nil)
                weakSelf.leftMenuVC?.removeFromParentViewController()
                weakSelf.leftMenuVC?.view.removeFromSuperview()
                weakSelf.leftMenuVC?.didMoveToParentViewController(nil)
                weakSelf.leftMenuVC = nil
                
                weakSelf.performSegueWithIdentifier("ShowLoginScreen", sender: nil)
            }
        }
    }
    
    //MARK: Menu
    func leftEdgePan(recognizer:UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.Began
        {
            print("left pan.")
            let translationX = round(recognizer.translationInView(recognizer.view!).x)
            let velocityX = round(recognizer.velocityInView(recognizer.view!).x)
            print(" Horizontal Velocity: \(velocityX)")
            print(" Horizontal Translation: \(translationX)")
            
            let ratio = ceil(velocityX / translationX)
            if  ratio > 3
            {
                showMenu(true, completion: nil)
            }
        }
    }
 
    func showLoginScreenWithReloginPrompt(showAlert:Bool)
    {
        if let menu = self.leftMenuVC
        {
            menu.view.removeFromSuperview()
            self.leftMenuVC = nil
        }
        if let navigationVC = self.currentNavigationController
        {
            navigationVC.view.removeFromSuperview()
            self.currentNavigationController = nil
        }
        
        if showAlert
        {
            let alertInfo = ["title":"Warning", "message":"Your session token is invalid, please login again"]
            self.performSegueWithIdentifier("ShowLoginScreen", sender: alertInfo)
        }
        else
        {
             self.performSegueWithIdentifier("ShowLoginScreen", sender: nil)
        }
    }
    
    func showRegistrationVC()
    {
        if let regVC = self.storyboard?.instantiateViewControllerWithIdentifier("RegistrationVC") as? RegistrationVC
        {
            self.presentViewController(regVC, animated: true, completion: nil)
        }
    }

    func processMenuDisplaying(notification:NSNotification?)
    {
        
        if isShowingMenu
        {
            if let info = notification?.userInfo as? [String:Int], numberTapped = info["tapped"]
            {
                
                switch numberTapped
                {
                case 0:
                    self.showHomeVC()
                case 1:
                    self.showElementsSortingVC()
                case 2:
                    self.showUserProfileVC()
                case 3:
                    self.showContactsVC()
                default:
                    break
                
                }
            }
            else
            {
                self.hideMenu(true, completion:nil)
            }
        }
        else
        {
            showMenu(true, completion: nil)
        }
       
    }
    
    func showMenu(animated:Bool, completion:(()->())?)
    {
        if let navController = self.currentNavigationController//, menu = self.leftMenuVC
        {
            let navFrame = navController.view.frame
            let movedToLeftFrame = CGRectOffset(navFrame, 200.0, 0.0)
            
            UIView.animateWithDuration(0.2,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseOut,
                animations:
                { () -> Void in
                navController.view.frame = movedToLeftFrame
            },
                completion: {[weak self] (finished) -> Void in
                if let weakSelf = self
                {
                    //weakSelf.view.bringSubviewToFront(menu.view)
                    //print("Menu Frame: \(menu.view.frame)")
                    weakSelf.isShowingMenu = true
                    
                    if let topVC = navController.topViewController
                    {
                        topVC.view.addGestureRecognizer(weakSelf.tapToDismissRecognizer)
                    }
                    else
                    {
                        NSLog("Could not instantiate top View Controller and add TapToDismiss recognizer.....")
                    }
                   
                }
                completion?()
            })
        }
    }
    
    func hideMenu(animated:Bool, completion:(()->())?)
    {
        if let navController = self.currentNavigationController
        {
            navController.topViewController?.view.removeGestureRecognizer(self.tapToDismissRecognizer)
            UIView.animateWithDuration(0.2,
                delay: 0.0,
                options: UIViewAnimationOptions.CurveEaseIn,
                animations: { () -> Void in
                navController.view.frame = self.view.bounds
            }, completion: {[weak self] (finished) -> Void in
                if let weakSelf = self
                {
                    weakSelf.isShowingMenu = false
                }
                
                completion?()
            })
        }
    }
    
    func showHomeVC()
    {
        if let navController = self.currentNavigationController
        {
            let currentVisibleIndex = navController.currentPresentedMenuItem()
            
            if currentVisibleIndex != 0
            {
                if let home = self.storyboard?.instantiateViewControllerWithIdentifier("HomeVC") as? HomeVC
                {
                    self.hideMenu(true, completion: {[weak self] () -> () in
                        if let weakSelf = self
                        {
                            weakSelf.currentNavigationController?.setViewControllers([home], animated: false)
                        }
                    })
                }
            }
            else
            {
                self.hideMenu(true, completion: nil)
            }
        }
    }
    
    func showElementsSortingVC()
    {
        if let recentsVC = self.storyboard?.instantiateViewControllerWithIdentifier("ElementsSortedByUserVC") as? ElementsSortedByUserVC
        {
            self.hideMenu(true, completion: {[weak self] () -> () in
                if let weakSelf = self
                {
                    weakSelf.currentNavigationController?.setViewControllers([recentsVC], animated: false)
                }
            })
        }
    }
    
    
    func showUserProfileVC()
    {
        if let profile = self.storyboard?.instantiateViewControllerWithIdentifier("UserProfileVC") as? UserProfileVC
        {
            self.hideMenu(true, completion: {[weak self] () -> () in
                if let weakSelf = self
                {
                    weakSelf.currentNavigationController?.setViewControllers([profile], animated: false)
                }
            })
        }
    }
    
    func showContactsVC()
    {
        if let myContacts = self.storyboard?.instantiateViewControllerWithIdentifier("MyContactsListVC") as? MyContactsListVC
        {
            self.hideMenu(true, completion: {[weak self] () -> () in
                if let weakSelf = self
                {
                    weakSelf.currentNavigationController?.setViewControllers([myContacts], animated: false)
                }
            })
        }
    }
    
    func tapToDismiss(recognizer:UITapGestureRecognizer)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    //MARK: - PasswordChangeDelegate
    func userDidChangePassword(newPassword: String?, sender: ChangePasswordViewController)
    {
        defer
        {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Buton_Tapped_Notification_Name, object: nil)
        }
        
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
    
    
    //MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "ShowLoginScreen"
        {
            if let destinationVC = segue.destinationViewController as? LoginVC
            {
                if let needAlertInfo = sender as? [String:String]
                {
                    destinationVC.alertInfoToShowAfterAppearance = needAlertInfo
                }
            }
        }
    }
    
}
