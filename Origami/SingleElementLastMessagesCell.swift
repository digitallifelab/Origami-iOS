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
        {
        didSet{
            if let messagesArray = messages
            {
                trytoGetContactsForLastMessages()
            }
        }
    }
    var contactsForLastMessages:[Contact]?
   
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
        self.messagesTable.scrollsToTop = false
        
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
    
    private func trytoGetContactsForLastMessages()
    {
        var contactIDs = Set<Int>()
        if let messages = self.messages
        {
            for aMessage in messages
            {
                contactIDs.insert(aMessage.creatorId!.integerValue)
            }
        }
        
        if let contacts = DataSource.sharedInstance.getContactsByIds(contactIDs)
        {
            self.contactsForLastMessages = Array(contacts)
        }
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
        
        var chatCell = tableView.dequeueReusableCellWithIdentifier("PreviewCell", forIndexPath: indexPath) as! ChatPreviewCell
        chatCell.selectionStyle = .None
        chatCell.displayMode = self.displayMode
        chatCell.backgroundColor = UIColor.clearColor()
        if let lvMessages = self.messages
        {
            let message = lvMessages[indexPath.row]
            chatCell.messageLabel.text = message.textBody
            chatCell.avatarView.tintColor = kDayCellBackgroundColor
            chatCell.avatarView.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            
            if let messageDate = message.dateCreated
            {
                var messageDateString = messageDate.timeDateStringShortStyle()
                chatCell.dateLabel.text = messageDateString as String
            }
            
            if let creatorId = message.creatorId
            {
                if creatorId.integerValue == DataSource.sharedInstance.user!.userId!.integerValue
                {
                    if let username = DataSource.sharedInstance.user!.userName as? String
                    {
                        if let imageData = DataSource.sharedInstance.getAvatarDataForContactUserName(username)
                        {
                            chatCell.avatarView.image = UIImage(data: imageData)
                        }
                        else
                        {
//                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
//                                DataSource.sharedInstance.loadAvatarFromDiscForLoginName(username, completion: {[weak self] (_, _) -> () in
//                                    if let weakSelf = self
//                                    {
//                                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                            weakSelf.messagesTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
//                                        })
//                                        
//                                    }
//                                 
//                                })
//                            })
                          
                        }
                    }
                    chatCell.nameLabel.text = DataSource.sharedInstance.user?.firstName as? String ?? DataSource.sharedInstance.user?.lastName as? String
                }
                else
                {
                    if let contact = contactForMessage(message) , userName = contact.userName as? String
                    {
                        chatCell.nameLabel.text = (contact.firstName as? String ?? contact.lastName as? String) ?? "unknown"
                        if let imageData = DataSource.sharedInstance.getAvatarDataForContactUserName(contact.userName! as String)
                        {
                            chatCell.avatarView.image = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
        else
        {
            chatCell.messageLabel.text = "Type a message."
        }
        
        return chatCell
    }
    
    private func contactForMessage(message:Message) -> Contact?
    {
        if let contacts = self.contactsForLastMessages, creatorId = message.creatorId
        {
            for aContact in contacts
            {
                if aContact.contactId!.isEqualToNumber(creatorId)
                {
                    return aContact
                }
            }
        }
        return nil
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
