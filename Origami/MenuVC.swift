//
//  MenuVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit
//MARK: Enum
enum SideMenuCellType
{
    case Regular
    case DisplayModeSwitch
    
    init()
    {
        self = .Regular
    }
}
//MARK: Protocol
protocol SwitchDelegate
{
    func switcher(aSwitch: UISwitch?, didChangeState:Bool)
}
////////////////////////////////////
///////////////////////////////////
//MARK: -------------------
/////////////////////////////

class SideMenuCell: UITableViewCell
{
    var cellType = SideMenuCellType()
    @IBOutlet var label:UILabel!
    var menuIcon:UIImageView?
    var switcher:UISwitch?
    var switchDelegate:SwitchDelegate?
    
    override func prepareForReuse() {
        self.cellType = .Regular
        var nightModeOn:Bool = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        switcher?.on = nightModeOn
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        switch cellType{
        case .Regular:
            switcher = nil
        case .DisplayModeSwitch:
            for aControl in self.contentView.subviews
            {
                if let aSwitch = aControl as? UISwitch
                {
                    self.switcher = aSwitch
                    switcher!.hidden = false
                    assignActionsToSwitch()
                    break
                }
            }
        }
        
        for aSubView in self.contentView.subviews
        {
            if let anImageView = aSubView as? UIImageView
            {
                self.menuIcon = anImageView
                break
            }
        }
    }
    
    func assignActionsToSwitch()
    {
        self.switcher!.addTarget(self, action: "switchDidChangeValue:", forControlEvents: .ValueChanged)
    }
    
    func switchDidChangeValue(sender:UISwitch)
    {
        switchDelegate?.switcher(sender, didChangeState: sender.on)
    }
}
////////////////////////////////////
///////////////////////////////////
//MARK: -------------------
/////////////////////////////

class MenuVC: UIViewController , UITableViewDelegate, UITableViewDataSource, SwitchDelegate {

    @IBOutlet var visialEffectBackgroundView:UIVisualEffectView!
    var menuTable:UITableView?
    var menuItemsTitles = ["Home", "Profile", "DisplayMode"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        for aView in self.visialEffectBackgroundView.contentView.subviews
        {
            if let table = aView as? UITableView
            {
                self.menuTable = table
                self.menuTable?.delegate = self
                self.menuTable?.dataSource = self
                break
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return menuItemsTitles.count //menu items
        case 1:
            return 1 //LogOut
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var menuCell = tableView.dequeueReusableCellWithIdentifier("SideMenuCell", forIndexPath: indexPath) as! SideMenuCell
        
        configureMenuCell(menuCell, forIndexpath: indexPath)
        
        return menuCell
        
    }

    func configureMenuCell(cell:SideMenuCell, forIndexpath indexPath:NSIndexPath)
    {
        if let cellTitle = titleForMenuCellAtIndexPath(indexPath)
        {
            cell.label.text = cellTitle
            if cellTitle == "DisplayMode"
            {
                cell.cellType = .DisplayModeSwitch
                cell.switchDelegate = self
            }
            else
            {
                cell.cellType = .Regular
            }
        }
    }
    
    func titleForMenuCellAtIndexPath(indexPath:NSIndexPath) -> String?
    {
        if indexPath.section == 1 && indexPath.row == 0
        {
            return "LogOut".localizedWithComment("")
        }
        else if indexPath.section == 0 && (indexPath.row >= 0 && indexPath.row < menuItemsTitles.count)
        {
            return menuItemsTitles[indexPath.row]
        }
        else
        {
            return nil
        }
    }
    
    
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section
        {
        case 0:
            return "Menu"
        case 1:
            return "authorization"
        default:
            return nil
        }
    }
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section < 2
        {
            return 40.0
        }
        return 0.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        switch indexPath.section
        {
        case 0:
            switch indexPath.row
            {
            case 0: //home button
                self.dismissViewControllerAnimated(true, completion: nil)
            case 1: // profile
                NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self, userInfo: ["tapped":indexPath.row] as [NSObject:AnyObject])
            default: break
            }
        case 1: //logout tapped
            
            let logoutNotification = NSNotification(name: "LogOutPressed", object: nil)
            NSNotificationCenter.defaultCenter().postNotification(logoutNotification)
        default: break
        }
    }
    
    //MARK: SwitchDelegate
    func switcher(aSwitch: UISwitch?, didChangeState state: Bool) {
        NSUserDefaults.standardUserDefaults().setBool( state , forKey: NightModeKey)
        
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Switch_Night_Mode_Changed, object: nil, userInfo: ["mode":state])
    }

}
