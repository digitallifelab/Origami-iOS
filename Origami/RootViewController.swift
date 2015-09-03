//
//  RootViewController.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    //var messagesLoader = MessagesLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleLogoutNotification:", name: kLogoutNotificationName, object: nil)
        
        
        var appDelegate = UIApplication.sharedApplication().delegate
        var application = UIApplication.sharedApplication()
        
        if FrameCounter.isLowerThanIOSVersion("8.0")
        {
            application.registerForRemoteNotificationTypes(.Alert | .Badge | .Sound)
        }
        else
        {
            let settings = UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil)
        
            application.registerUserNotificationSettings(settings)
        }
        
        /*
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        {
            UIUserNotificationType types;
            types = [[UIApplication sharedApplication] currentUserNotificationSettings].types;
        
            if (types & UIUserNotificationTypeAlert)
                pushEnabled=YES;
            else
                pushEnabled=NO;
        }
        else
        {
            UIRemoteNotificationType types;
            types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
            
            if (types & UIRemoteNotificationTypeAlert)
                pushEnabled=YES;
            else
                pushEnabled=NO;
        
        }
        
        */
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        DataSource.sharedInstance.cleanDataCache()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        if let user = DataSource.sharedInstance.user
        {
            self.performSegueWithIdentifier("ShowMainTabbar", sender: nil)
            
            return
        }
        
        self.performSegueWithIdentifier("ShowLoginScreen", sender: nil)
    }
    
  
    func handleLogoutNotification(notification:NSNotification?)
    {
        DataSource.sharedInstance.performLogout {[weak self] () -> () in
            if let weakSelf = self
            {
                weakSelf.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
}
