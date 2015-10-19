//
//  FrameCounter.swift
//  Origami
//
//  Created by CloudCraft on 16.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

class FrameCounter
{
    @available(iOS 8.0, *)
    class func getCurrentTraitCollection() -> UITraitCollection
    {
        let traitCollection = UIScreen.mainScreen().traitCollection
        return traitCollection
    }
    
    class func getCurrentInterfaceIdiom() -> UIUserInterfaceIdiom
    {
        return UIDevice.currentDevice().userInterfaceIdiom
    }
    
    class func getCurrentDeviceOrientation() -> UIInterfaceOrientation
    {
        return UIApplication.sharedApplication().statusBarOrientation
    }
    
}
