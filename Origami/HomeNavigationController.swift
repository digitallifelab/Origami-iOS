//
//  HomeNavigationController.swift
//  Origami
//
//  Created by CloudCraft on 16.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//



/*
        NOTE!

This subclass is created mostly to handle custom appearance ob tabbar controller`s button.

According to design it should be at the right instead of center

AnyWay tapping on tabbar at the center still has effect of returning to Home Screen, also as tapping on "Home" image

*/
import UIKit

class HomeNavigationController: UINavigationController {

    func currentPresentedMenuItem() -> NSInteger
    {
        if let vc =  self.topViewController as? HomeVC
        {
            return 0
        }
        
        if let vc = self.topViewController as? UserProfileVC
        {
            return 1
        }
        
        if let vc = self.topViewController as? MyContactsListVC
        {
            return 2
        }
         //WARNING: to expand menu items add ather conditions here
        return NSIntegerMax
    }

}
