//
//  MenuTableViewController.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {

    
    @IBOutlet var nightModeSwitch:UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nightModeToggledOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        nightModeSwitch.on = nightModeToggledOn
        
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self, userInfo: ["tapped":indexPath.row] as [NSObject:AnyObject])
    }
    
    @IBAction func toggleNghtDayModes(sender:UISwitch)
    {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: NightModeKey)
        
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Switch_Night_Mode_Changed, object: nil, userInfo: ["mode":sender.on]) //["mode": (sender.on) ? 1 : 0 ])
    }
    
}
