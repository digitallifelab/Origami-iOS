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
            DataSource.sharedInstance.messagesLoader = MessagesLoader()//self.messagesLoader
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
