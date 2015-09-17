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
    @IBOutlet weak var label:UILabel!
    @IBOutlet var menuIcon:UIImageView?
    var switcher:UISwitch?
    var switchDelegate:SwitchDelegate?
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day:
                self.label.textColor = kBlackColor
            case .Night:
                self.label.textColor = kWhiteColor
            }
        }
    }
    override func prepareForReuse()
    {
        self.cellType = .Regular
        var nightModeOn:Bool = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        switcher?.on = nightModeOn
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func layoutSubviews()
    {
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
                    self.switcher!.hidden = false
                    setupSwitch()
                    break
                }
            }
        }
    }
    
    func setupSwitch()
    {
        self.switcher!.setOn(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey), animated: false) 
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

    //@IBOutlet var visialEffectBackgroundView:UIVisualEffectView!
    @IBOutlet weak var menuTable:UITableView?
    var menuItemsTitles = ["Home", "Sorting".localizedWithComment(""), "Profile".localizedWithComment(""), "Contacts".localizedWithComment(""), "Display Mode".localizedWithComment("")]
    
    var displayMode:DisplayMode = .Day
        {
        didSet{
            switch displayMode
            {
            case .Day:
                self.view.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.8)
            case .Night:
                self.view.backgroundColor = kBlackColor
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.menuTable?.scrollsToTop = false
        self.menuTable?.delegate = self
        self.menuTable?.dataSource = self
        self.menuTable?.backgroundColor = UIColor.clearColor()// kDayNavigationBarBackgroundColor

        //self.view.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.8)
        self.setAppaeranceForNightModeDidChange(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
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
        menuCell.backgroundColor = UIColor.clearColor()
        configureMenuCell(menuCell, forIndexpath: indexPath)
        
        return menuCell
        
    }

    func configureMenuCell(cell:SideMenuCell, forIndexpath indexPath:NSIndexPath)
    {
        if let cellTitle = titleForMenuCellAtIndexPath(indexPath)
        {
            cell.label.text = cellTitle
            cell.displayMode = self.displayMode
            if cellTitle == "Display Mode".localizedWithComment("")
            {
                cell.cellType = .DisplayModeSwitch
                cell.switchDelegate = self
                cell.label.numberOfLines = 2
                cell.label.lineBreakMode = NSLineBreakMode.ByWordWrapping
                cell.label.sizeToFit()
            }
            else
            {
                cell.cellType = .Regular
                cell.label.numberOfLines = 1
            }
            
            cell.menuIcon?.image = menuIconForIndexPath(indexPath)
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
    
    func menuIconForIndexPath(indexPath:NSIndexPath) -> UIImage?
    {
        let section = indexPath.section
        let row = indexPath.row
        switch section
        {
        case 0:
            switch row{
            case 0:
                return UIImage(named: "menu-icon-home")?.imageWithRenderingMode(.AlwaysTemplate) // set "alwaysTemplate" in code because ios 7 from storyboard does not understand image assets set to be alwaystemplate...
            case 1:
                return UIImage(named: "menu-icon-sorting")?.imageWithRenderingMode(.AlwaysTemplate)
            case 2:
                return UIImage(named: "menu-icon-profile")?.imageWithRenderingMode(.AlwaysTemplate)
            case 3:
                return UIImage(named: "menu-icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            case 4:
                return UIImage(named: "menu-icon-displaymode")?.imageWithRenderingMode(.AlwaysTemplate)
            default:
                break
            }
        case 1:
            return UIImage(named: "menu-icon-logout")?.imageWithRenderingMode(.AlwaysTemplate)
        default:
            break
        }
        return nil
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section
        {
        case 0:
            return "Menu".localizedWithComment("")
        case 1:
            return "authorization".localizedWithComment("")
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
            case 0..<4:
                NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self, userInfo: ["tapped":indexPath.row] as [NSObject:AnyObject])
            default: break
            }
        case 1: //logout tapped
            NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self, userInfo: ["tapped":0] as [NSObject:AnyObject])
            let logoutNotification = NSNotification(name: kLogoutNotificationName, object: nil)
            
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
            dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                 NSNotificationCenter.defaultCenter().postNotification(logoutNotification)
            })
           
        default: break
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    //MARK: SwitchDelegate
    func switcher(aSwitch: UISwitch?, didChangeState state: Bool) {
        NSUserDefaults.standardUserDefaults().setBool( state , forKey: NightModeKey)
        setAppaeranceForNightModeDidChange(state)
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Switch_Night_Mode_Changed, object: nil, userInfo: ["mode":state])
    }
    
    
    func setAppaeranceForNightModeDidChange(nightMode:Bool)
    {
        if nightMode
        {
            displayMode = .Night
            self.menuTable?.reloadData()
            return
        }
        displayMode = .Day
        self.menuTable?.reloadData()
        
    }
    

}
