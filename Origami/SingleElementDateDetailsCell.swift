//
//  SingleElementDateDetailsCell.swift
//  Origami
//
//  Created by CloudCraft on 27.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDateDetailsCell: UICollectionViewCell, UITableViewDataSource {
    
    var displayMode:DisplayMode = .Day {
        didSet{
            switch self.displayMode{
            case .Day:
                self.backgroundColor = kDayCellBackgroundColor
                buttonInformColor = kDaySignalColor
               
            case .Night:
                self.backgroundColor = UIColor.blackColor()
                buttonInformColor = kNightSignalColor
            }
        }
    }
    var handledElement:Element?
    var buttonInformColor = kDaySignalColor
    @IBOutlet var datesTable:UITableView!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = false
        
        let selfBounds = self.bounds
        let shadowColor = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? UIColor.grayColor().CGColor : UIColor.blackColor().CGColor
        let shadowOpacity:Float = 0.5
        let shadowOffset = CGSizeMake(0.0, 5.0)
        let offsetShadowFrame = CGRectOffset(selfBounds, 0, shadowOffset.height)
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadii: CGSizeMake(5.0, 5.0))
        
        
        self.layer.shadowPath = offsetPath.CGPath
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = 3.0
        self.layer.zPosition = 1000
    }
    
    //MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var countRows = 0
        if let dateCreated = handledElement?.createDate?.timeDateStringFromServerDateString() as? String
        {
            countRows += 1
        }
        if let dateModified = handledElement?.changeDate?.timeDateStringFromServerDateString() as? String
        {
            countRows += 1
        }
        if let dateFinished = handledElement?.finishDate?.timeDateString() as? String
        {
            countRows += 1
        }
        return countRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var datesCell = tableView.dequeueReusableCellWithIdentifier("DatesTableHolderCell", forIndexPath: indexPath) as! ElementDashboardDatesCell
        datesCell.displayMode = self.displayMode
        
        configureDateCellForRow(indexPath.row, cell: datesCell)
        
        return datesCell
    }
    
    func setupActionButtons(active:Bool)
    {
        if active{
            addActionToButtons()
        }
        else
        {
            hideActionButtons()
        }
    }
    
    private func configureDateCellForRow(row:Int, cell:ElementDashboardDatesCell)
    {
        switch row
        {
        case 0:
            cell.titleLabel.text = "Created".localizedWithComment("")
            cell.dateLael.text = handledElement?.createDate?.dateFromServerDateString()?.timeDateString() as String? ?? nil
        case 1:
            cell.titleLabel.text = "Changed".localizedWithComment("")
            cell.dateLael.text = handledElement?.changeDate?.dateFromServerDateString()?.timeDateString() as String? ?? nil
        case 2:
            cell.titleLabel.text = "Finished".localizedWithComment("")
            cell.dateLael.text = handledElement?.finishDate?.timeDateString() as String? ?? nil
        default:
            break
        }
    }
    
     //MARK: element is owned
    private func addActionToButtons()
    {
        for var i = 0; i < 8; i++
        {
            if let buttonSubView = self.viewWithTag(i) as? UIButton
            {
                if buttonSubView.hidden
                {
                    buttonSubView.hidden = false
                }
                buttonSubView.addTarget(self, action: "actionButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
        
        if let editButton = self.viewWithTag(256) as? UIButton
        {
            editButton.hidden = false
            editButton.addTarget(self, action: "actionButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
        }
        
        setupSignalButton()
    }
    
    private func setupSignalButton()
    {
        if let currentElement = self.handledElement, signalButton = self.viewWithTag(ActionButtonCellType.Signal.rawValue)
        {
            signalButton.tintColor = (currentElement.isSignal!) ? buttonInformColor : UIColor.whiteColor()
        }
    }
    
    func actionButtonTapped(sender:AnyObject?)
    {
        if let button = sender as? UIButton
        {
            var theTag = button.tag
            if theTag > 7
            {
                theTag = 0
            }
            NSNotificationCenter.defaultCenter().postNotificationName(kElementActionButtonPressedNotification, object: self, userInfo: ["actionButtonIndex" : theTag])
        }
    }
    
    //MARK: element is not owned
    func hideActionButtons()
    {
        for var i = 0; i < 8; i++
        {
            if let buttonSubView = self.viewWithTag(i) as? UIButton
            {
                buttonSubView.hidden = true
                //buttonSubView.addTarget(self, action: "actionButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
        if let editButton = self.viewWithTag(256) as? UIButton
        {
            editButton.hidden = true
        }
    }
}
