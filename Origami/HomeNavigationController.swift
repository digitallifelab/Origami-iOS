//
//  HomeNavigationController.swift
//  Origami
//
//  Created by CloudCraft on 16.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class HomeNavigationController: UINavigationController {

    func currentPresentedMenuItem() -> NSInteger
    {
        if let _ =  self.topViewController as? HomeVC
        {
            return 0
        }
        
        if let _ = self.topViewController as? ElementsSortedByUserVC
        {
            return 1
        }
        
        if let _ = self.topViewController as? UserProfileVC
        {
            return 2
        }
        
        if let _ = self.topViewController as? MyContactsListVC
        {
            return 3
        }
        //WARNING: to expand menu items add other conditions here
        return NSIntegerMax
    }
}
