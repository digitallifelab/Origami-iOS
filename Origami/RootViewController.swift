//
//  RootViewController.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //var messagesLoader = MessagesLoader()
    var dataRefresher:DataRefresher?
    var screenEdgePanRecognizer:UIScreenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer()
    var tapToDismissRecognizer:UITapGestureRecognizer = UITapGestureRecognizer()
    var leftMenuVC:MenuVC?
    var currentNavigationController:HomeNavigationController?
    
    var isShowingMenu = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
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

        
        
        var appDelegate = UIApplication.sharedApplication().delegate
        var application = UIApplication.sharedApplication()
        
        if FrameCounter.isLowerThanIOSVersion("8.0")
        {
            var types:UIRemoteNotificationType = application.enabledRemoteNotificationTypes()
            if (types == .None)
            {
                application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
            }
        }
        else
        {
            var types: UIUserNotificationType = application.currentUserNotificationSettings().types
            if types == .None
            {
                let settings = UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil)
                
                application.registerUserNotificationSettings(settings)
                //application.registerForRemoteNotifications()
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        DataSource.sharedInstance.cleanDataCache()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        if let user = DataSource.sharedInstance.user
        {
            //self.performSegueWithIdentifier("ShowHomeVC", sender: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "processMenuDisplaying:", name: kMenu_Buton_Tapped_Notification_Name, object: nil)
            
            if let navController = self.storyboard?.instantiateViewControllerWithIdentifier("HomeNavigationController") as? HomeNavigationController
            {
                self.currentNavigationController = navController
                self.view.addSubview(navController.view)
                if let homeVC = self.storyboard?.instantiateViewControllerWithIdentifier("HomeVC") as? HomeVC
                {
                    //navController.setViewControllers([homeVC], animated: true)
                    if let menuVC = self.storyboard?.instantiateViewControllerWithIdentifier("MenuVC") as? MenuVC
                    {
                        self.leftMenuVC = menuVC
                        self.view.insertSubview(menuVC.view, belowSubview: currentNavigationController!.view)
                    }
                    navController.setViewControllers([homeVC], animated: true)
                }
            }
            
            return
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Buton_Tapped_Notification_Name, object: nil)
        
        self.performSegueWithIdentifier("ShowLoginScreen", sender: nil)
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
                //weakSelf.dismissViewControllerAnimated(true, completion: nil)
                weakSelf.currentNavigationController?.view.removeFromSuperview()
                weakSelf.leftMenuVC?.view.removeFromSuperview()
                weakSelf.currentNavigationController = nil
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
            println("left pan.")
            let translationX = round(recognizer.translationInView(recognizer.view!).x)
            let velocityX = round(recognizer.velocityInView(recognizer.view!).x)
            println(" Horizontal Velocity: \(velocityX)")
            println(" Horizontal Translation: \(translationX)")
            
            let ratio = ceil(velocityX / translationX)
            if  ratio > 3
            {
                showMenu(true, completion: nil)
            }
        }
    }
    
    func getCurrentTopViewController() -> UIViewController?
    {
        if isShowingMenu
        {
            return self.leftMenuVC
        }
        return self.currentNavigationController
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
                self.hideMenu(true, completion: { () -> () in
                    
                })
            }
        }
        else
        {
            showMenu(true, completion: {[weak self] () -> () in
                
           })    
        }
       
    }
    
    func showMenu(animated:Bool, completion:(()->())?)
    {
        if let navController = self.currentNavigationController, menu = self.leftMenuVC
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
                    println("Menu Frame: \(menu.view.frame)")
                    weakSelf.isShowingMenu = true
                    navController.topViewController.view.addGestureRecognizer(weakSelf.tapToDismissRecognizer)
                }
                completion?()
            })
        }
    }
    
    func hideMenu(animated:Bool, completion:(()->())?)
    {
        if let navController = self.currentNavigationController
        {
            navController.topViewController.view.removeGestureRecognizer(self.tapToDismissRecognizer)
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
    
    
}
