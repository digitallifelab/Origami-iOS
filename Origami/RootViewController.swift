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
    let dataRefresher = DataRefresher()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleLogoutNotification:", name: kLogoutNotificationName, object: nil)
        
        
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
            self.performSegueWithIdentifier("ShowHomeVC", sender: nil)
            
            dataRefresher.startRefreshingElementsWithTimeoutInterval(30.0)
            
            return
        }
        
        self.performSegueWithIdentifier("ShowLoginScreen", sender: nil)
    }
    
  
    func handleLogoutNotification(notification:NSNotification?)
    {
        self.dataRefresher.stopRefreshingElements()
        
        DataSource.sharedInstance.performLogout {[weak self] () -> () in
            if let weakSelf = self
            {
                weakSelf.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
}
