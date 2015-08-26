//
//  Country.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Country
{
    var countryId:NSNumber?
    var countryName:String?
    
    init(info:[String:AnyObject])
    {
        if info.count > 0
        {
            if let lvId = info["Id"] as? NSNumber
            {
                self.countryId = lvId
            }
            
            if let lvName = info["Name"] as? String
            {
                self.countryName = lvName
            }
        }
    }
}


/*
if FrameCounter.isLowerThanIOSVersion("8.0")
{
leftTopMenuPopupVC.modalPresentationStyle = UIModalPresentationStyle.Popover
if FrameCounter.getCurrentInterfaceIdiom() == .Pad
{
var aPopover:UIPopoverController = UIPopoverController(contentViewController: leftTopMenuPopupVC)
aPopover.popoverContentSize = CGSizeMake(200, 150.0)
aPopover.delegate = self
aPopover.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItem!, permittedArrowDirections: .Any, animated: true)
}
else
{
leftTopMenuPopupVC.view.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
self.presentViewController(leftTopMenuPopupVC, animated: true, completion: { () -> Void in

})
}
}
else
{

*/