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
               
            case .Night:
                self.backgroundColor = UIColor.blackColor()
           
            }
        }
    }
    weak var handledElement:Element?
    @IBOutlet weak var datesTable:UITableView!
    @IBOutlet weak var ownerNameLabel:UILabel!
    @IBOutlet weak var editButton:UIButton?
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = false
        
        let selfBounds = self.bounds
        let shadowColor = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? UIColor.grayColor().CGColor : UIColor.blackColor().CGColor
        let shadowOpacity:Float = 0.5
        let shadowOffset = CGSizeMake(0.0, 3.0)
        let offsetShadowFrame = CGRectOffset(selfBounds, 0, shadowOffset.height)
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadii: CGSizeMake(5.0, 5.0))
        
        
        self.layer.shadowPath = offsetPath.CGPath
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = 3.0
        
        self.editButton?.tintColor = kWhiteColor
        
        if let creatorId = self.handledElement?.creatorId
        {
            var ownerNameToDisplay = String()
            
            if creatorId == DataSource.sharedInstance.user?.userId
            {
                if let name = DataSource.sharedInstance.user?.firstName as? String
                {
                    ownerNameToDisplay += name
                }
                if let lastName = DataSource.sharedInstance.user?.lastName as? String
                {
                    if ownerNameToDisplay.isEmpty
                    {
                        ownerNameToDisplay += lastName
                    }
                    else
                    {
                        ownerNameToDisplay += (" " + lastName)
                    }
                }
            }
            else if let contacts = DataSource.sharedInstance.getContactsByIds(Set([creatorId.integerValue]))
            {
                let owner = contacts.first
                
                if let name = owner?.firstName as? String
                {
                    ownerNameToDisplay += name
                }
                if let lastName = owner?.lastName as? String
                {
                    if ownerNameToDisplay.isEmpty
                    {
                        ownerNameToDisplay += lastName
                    }
                    else
                    {
                        ownerNameToDisplay += (" " + lastName)
                    }
                }
            }
            
            if !ownerNameToDisplay.isEmpty
            {
                ownerNameLabel.text = ownerNameToDisplay
            }
        }
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
        if active
        {
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
        if let editButton = self.viewWithTag(256) as? UIButton
        {
            editButton.hidden = false
            editButton.addTarget(self, action: "actionButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
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
    private func hideActionButtons()
    {
        if let editButton = self.viewWithTag(256) as? UIButton
        {
            editButton.hidden = true
        }
    }
}
