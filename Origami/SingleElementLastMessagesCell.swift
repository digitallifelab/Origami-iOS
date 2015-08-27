//
//  SingleElementLastMessagesCell.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementLastMessagesCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate
{
    var cellMessageTapDelegate:MessageTapDelegate?
    var messages:[Message]?
    var displayMode:DisplayMode = .Day {
        didSet{
            switch displayMode{
            case .Day:
                chatIcon.backgroundColor = kDaySignalColor
                self.backgroundColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)
            
            case .Night:
                chatIcon.backgroundColor = kNightSignalColor
                self.backgroundColor = UIColor.blackColor()
            }
        }
    }
    
    @IBOutlet var chatIcon:UILabel!
    @IBOutlet var messagesTable:UITableView!
    
    override func awakeFromNib() {
        self.backgroundColor = UIColor.clearColor()
        messagesTable.layer.borderWidth = 1.0
    }
    
    override func prepareForReuse() {
        //messages = nil
        self.backgroundColor = UIColor.clearColor()
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        let chatIconBounds = chatIcon.bounds
        let roundedLeftBottomPath = UIBezierPath(roundedRect: chatIconBounds, byRoundingCorners: UIRectCorner.BottomLeft, cornerRadii: CGSizeMake(5, 5))
        
        var shape = CAShapeLayer()
        shape.frame = chatIconBounds
        shape.path = roundedLeftBottomPath.CGPath
        
        chatIcon.layer.mask = shape
        
        //rotate chatIcon
        let angle = CGFloat(-90.0 * CGFloat(M_PI) / 180.0)
        chatIcon.layer.anchorPoint = CGPointMake(0.0, 1.0)
        chatIcon.transform = CGAffineTransformMakeRotation(angle)
    
        self.messagesTable.dataSource = self
        self.messagesTable.delegate = self
        
    
         //apply shadow to us
        self.layer.masksToBounds = false
        let selfBounds = self.bounds
        
        let shadowColor = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? UIColor.grayColor().CGColor : UIColor.blackColor().CGColor
        let shadowOpacity:Float = 0.5
        let shadowOffset = CGSizeMake(0.0, 2.0)
        let offsetShadowFrame = CGRectOffset(selfBounds, 0, shadowOffset.height)
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = 2.0
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadii: CGSizeMake(5.0, 5.0))
        self.layer.shadowPath = offsetPath.CGPath
        
        //self.layer.shouldRasterize = true
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.messages != nil
        {
            return self.messages!.count
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var messageCell = tableView.dequeueReusableCellWithIdentifier("PreviewCell", forIndexPath: indexPath) as! ChatPreviewCell
        messageCell.selectionStyle = .None
        messageCell.displayMode = self.displayMode
        
        if let lvMessages = self.messages
        {
            let message = lvMessages[indexPath.row]
            messageCell.messageLabel.text = message.textBody
            messageCell.avatarView.tintColor = kDayCellBackgroundColor
            messageCell.avatarView.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            
            if let messageDate = message.dateCreated
            {
                var messageDateString = messageDate.timeDateStringShortStyle()
                messageCell.dateLabel.text = messageDateString as String
            }
            
            if message.creatorId != nil
            {
                if message.creatorId!.integerValue == DataSource.sharedInstance.user!.userId!.integerValue
                {
                    DataSource.sharedInstance.loadAvatarForLoginName(DataSource.sharedInstance.user!.userName as! String, completion: {[weak messageCell] (image) -> () in
                        if let cell = messageCell, avatarImage = image
                        {
                            cell.avatarView.image = avatarImage
                        }
                    })
                    
                    messageCell.nameLabel.text = DataSource.sharedInstance.user?.firstName as? String ?? DataSource.sharedInstance.user?.lastName as? String
                }
                else
                {
                    if let contacts = DataSource.sharedInstance.getContactsByIds(Set([message.creatorId!.integerValue]))
                    {
                        var contact = contacts.first
                        messageCell.nameLabel.text = contact?.firstName as? String ?? contact?.lastName as? String
                    }
                }
            }
        }
        else
        {
            messageCell.messageLabel.text = "Type a message."
        }
        
        return messageCell
    }
    
   
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let
            delegate = self.cellMessageTapDelegate,
            currentMessages = self.messages
        {
            if indexPath.row >= 0 && indexPath.row < currentMessages.count
            {
                let tappedMessage = currentMessages[indexPath.row]
                delegate.chatMessageWasTapped(tappedMessage)
            }
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    //MARK: external calls
    func reloadTable()
    {
        self.messagesTable.reloadData()
    }
}
