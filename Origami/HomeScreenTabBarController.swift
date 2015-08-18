//
//  HomeScreenTabBarController.swift
//  Origami
//
//  Created by CloudCraft on 14.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class HomeScreenTabBarController: UITabBarController {

    

    override func viewDidLoad() {
        super.viewDidLoad()
        let isNightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
       // self.tabBar.tintColor = (isNightModeOn) ? kWhiteColor : kDayCellBackgroundColor
        //UITabBar.appearance().tintColor = (isNightModeOn) ? kWhiteColor : kDayCellBackgroundColor
        self.tabBar.tintColor = kWhiteColor //: kDayCellBackgroundColor
    }
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
//    {
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//        
//        
//    }
}
