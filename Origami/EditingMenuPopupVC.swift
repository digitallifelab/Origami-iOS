//
//  EditingMenuPopupVC.swift
//  Origami
//
//  Created by CloudCraft on 31.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class EditingMenuPopupVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let menuItems:[String] = ["Add Element", "Add Attachment", "Chat"]
    
    @IBOutlet var table:UITableView!
    var delegate:ButtonTapDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.rowHeight = UITableViewAutomaticDimension
        table.estimatedRowHeight = 60.0
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 1-  post notification about menu item was pressed
        
        // 2-  dismiss self
        NSNotificationCenter.defaultCenter().postNotificationName("PopupMenuItemPressed", object: self, userInfo: ["title":menuItems[indexPath.row]])
        
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var menuCell = tableView.dequeueReusableCellWithIdentifier("PopupMenuCell", forIndexPath: indexPath) as! PopupMenuCell
        configureMenuCell(menuCell, forIndexPath: indexPath)
        return menuCell
    }
    
    func configureMenuCell(cell:PopupMenuCell, forIndexPath indexPath:NSIndexPath)
    {
        if indexPath.row >= 0 && indexPath.row < menuItems.count
        {
            cell.leftIcon.tintColor = kDayCellBackgroundColor
            cell.menuItemlabel.text = menuItems[indexPath.row]
            switch indexPath.row
            {
            case 0:
                cell.leftIcon.image = UIImage(named: "icon-newElement")
                
            case 1:
                cell.leftIcon.image = UIImage(named: "button-attach")
                //cell.leftIcon.tintColor = kNightSignalColor
            case 2:
                cell.leftIcon.image = UIImage(named: "icon-chat")
                //cell.leftIcon.tintColor = kDaySignalColor
            default:
                cell.leftIcon.tintColor = UIColor.blackColor()
            }
        }
        else
        {
            return
        }
      
    }

}
