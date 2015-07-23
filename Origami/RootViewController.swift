//
//  RootViewController.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    
  
}
