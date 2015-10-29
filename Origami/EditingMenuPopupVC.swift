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
        //table.layer.borderWidth = 1.0
        
    
        if #available (iOS 8.0, *) {
            
        }
        else {
            if FrameCounter.getCurrentInterfaceIdiom() == .Phone{
                addTapToDismissGesture()
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // 1-  post notification about menu item was pressed
        
        // 2-  dismiss self
        NSNotificationCenter.defaultCenter().postNotificationName(kPopupMenuItemPressedNotification, object: self, userInfo: ["title":menuItems[indexPath.row]])
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let menuCell = tableView.dequeueReusableCellWithIdentifier("PopupMenuCell", forIndexPath: indexPath) as! PopupMenuCell
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
                cell.leftIcon.image = UIImage(named: "icon-newElement")?.imageWithRenderingMode(.AlwaysTemplate)
                
            case 1:
                cell.leftIcon.image = UIImage(named: "icon-attach")?.imageWithRenderingMode(.AlwaysTemplate)
                //cell.leftIcon.tintColor = kNightSignalColor
            case 2:
                cell.leftIcon.image = UIImage(named: "icon-chat")?.imageWithRenderingMode(.AlwaysTemplate)
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
    //MARK: iPhone iOS 7 stuff
    func addTapToDismissGesture()
    {
        let dummyButton = UIButton(type:.Custom) //as! UIButton
        //dummyButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        dummyButton.opaque = true
        dummyButton.backgroundColor = UIColor.clearColor()
        dummyButton.tintColor = kDayCellBackgroundColor
        dummyButton.setTitle("Cancel", forState: .Normal)
        if let font = UIFont(name: "SegoeUI", size: 25)
        {
            let attributes = [NSFontAttributeName:font, NSForegroundColorAttributeName:kDayCellBackgroundColor]
            let attributedString = NSAttributedString(string: "Cancel", attributes: attributes)
            dummyButton.setAttributedTitle(attributedString, forState: .Normal)
            //dummyButton.setAttributedTitle(attributedString, forState: UIControlState.Highlighted)
        }
        
        dummyButton.addTarget(self, action: "dismissSelfByCancelling:", forControlEvents: .TouchUpInside)
        //dummyButton.layer.borderWidth = 1.0
        self.view.insertSubview(dummyButton, aboveSubview: self.table)
        
        //add constraints to button
        let viewsDict = ["button":dummyButton]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[button]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views:viewsDict )
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(185)-[button]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: viewsDict)
        
        self.view.addConstraints(horizontalConstraints)
        self.view.addConstraints(verticalConstraints)
    
    }
    
    func dismissSelfByCancelling(sender:UIButton?)
    {
        if let button = sender
        {
            button.userInteractionEnabled = false
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
