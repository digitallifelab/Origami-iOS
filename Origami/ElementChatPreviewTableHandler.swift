//
//  ElementChatPreviewTableHandler.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementChatPreviewTableHandler: NSObject, UITableViewDelegate, UITableViewDataSource
{
    var displayMode:DisplayMode = .Day
    
    lazy var messageObjects:[Message] = [Message]()
    let noAvatarImage = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
    var contactsForLastMessages:[Contact]?

    lazy var currentAvatars = [String:UIImage]()
    
    weak var tableView:UITableView?
    
    override init()
    {
        super.init()
    }
    
    convenience init?(messages:[Message]?) // failable initializer - we don`t need to show messages table in messages cell if there are no messages in element chat
    {
        self.init()
        if messages == nil
        {
            return nil
        }
        if messages!.isEmpty
        {
            return nil
        }
        self.messageObjects = messages!
        self.trytoGetContactsForLastMessages()
        print(" \n added Observer Dashboard messages table handler ..........")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshTable:", name: "FinishedProcessingContactAvatars", object: nil)
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("\n removed Observer Dashboard messages table handler- > \n")
    }
    
    private func trytoGetContactsForLastMessages()
    {
        var contactIDs = Set<Int>()
            for aMessage in self.messageObjects
            {
                if let aCreatorId = aMessage.creatorId
                {
                    contactIDs.insert(aCreatorId)//!.integerValue)
                }
            }
            if let contacts = DataSource.sharedInstance.getContactsByIds(contactIDs)
            {
                self.contactsForLastMessages = Array(contacts)
            }
    }

    //DataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //print("  >>>>>   Preview messages count: \(messageObjects.count )")
        return messageObjects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        self.tableView = tableView
        let chatCell = tableView.dequeueReusableCellWithIdentifier("PreviewCell", forIndexPath: indexPath) as! ChatPreviewCell
        chatCell.messageLabel.text = messageObjects[indexPath.row].textBody
        chatCell.backgroundColor = UIColor.clearColor()

        let message = messageObjects[indexPath.row]

        if let messageDate = message.dateCreated
        {
            if messageDate.lessThanDayAgo()
            {
                chatCell.dateLabel.text = messageDate.timeStringShortStyle()
            }
            else
            {
                chatCell.dateLabel.text = messageDate.dateStringShortStyle()
            }
        }
        
        if let creatorId = message.creatorId, userID = DataSource.sharedInstance.user?.userId
        {
            if creatorId == userID
            {
                chatCell.nameLabel.text = DataSource.sharedInstance.user?.initialsString()//firstName /*as? String*/ ?? DataSource.sharedInstance.user?.lastName //as? String
                
                if let username = DataSource.sharedInstance.user?.userName //as? String
                {
                    if let image = self.currentAvatars[username]
                    {
                        chatCell.avatarView.image = image
                    }
                    else
                    {
                        chatCell.avatarView.image = noAvatarImage
                        loadAvatarForUserName(username, andIndexPath:indexPath)
                    }
                }
                
            }
            else
            {
                if let contact = contactForMessage(message)
                {
                    if !contact.userName.isEmpty
                    {
                        chatCell.nameLabel.text = contact.initialsString() //(contact.firstName /*as? String*/ ?? contact.lastName /* as? String*/) ?? "unknown"
                        
                        if let image = self.currentAvatars[contact.userName]
                        {
                            chatCell.avatarView.image = image
                        }
                        else
                        {
                            chatCell.avatarView.image = noAvatarImage
                            loadAvatarForUserName(contact.userName, andIndexPath:indexPath)
                        }
                    }
                    
                }
                else
                {
                    print(" -> No CONTACT for message found..")
                }
            }
        }
        
        chatCell.displayMode = self.displayMode
        return chatCell
    }
    
    func messageForIndexPath(indexPath:NSIndexPath) -> Message? //user also as external API
    {
        return messageObjects[indexPath.row] ?? nil
    }
    
    private func contactForMessage(message:Message) -> Contact?
    {
        if let contacts = self.contactsForLastMessages, creatorId = message.creatorId
        {
            for aContact in contacts
            {
                if aContact.contactId == creatorId
                {
                    return aContact
                }
            }
        }
        return nil
    }
    
    private func loadAvatarForUserName(name:String , andIndexPath indexPath:NSIndexPath)
    {
        if let imageData = DataSource.sharedInstance.getAvatarDataForContactUserName(name)
        {
            if let avatar = UIImage(data: imageData)
            {
                self.currentAvatars[name] = avatar
            }
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
            dispatch_after(timeout, dispatch_get_main_queue(), { [weak self]() -> Void in
                if let aSelf = self
                {
                    aSelf.tableView?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                }
            })
        }
        else
        {
            let row = indexPath.row
            let section = indexPath.section
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                DataSource.sharedInstance.loadAvatarFromDiscForLoginName(name, completion: {[weak self] (fullImage, error) -> () in
                    
                    if let weakSelf = self
                    {
                        if let avatarData = DataSource.sharedInstance.getAvatarDataForContactUserName(name)
                        {
                            if let avatar = UIImage(data: avatarData)
                            {
                                weakSelf.currentAvatars[name] = avatar
                                dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                    if let aSelf = self, table = aSelf.tableView
                                    {
                                        table.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: section)], withRowAnimation: .None)
                                    }
                                })
                            }
                        }
                    }
                })
            })
        }
    }
    
    func indexPathsForUserId(anId:Int) -> [NSIndexPath]?
    {
        if self.messageObjects.isEmpty
        {
            return nil
        }
        
        let messages = self.messageObjects
        
        var counter = 0
        var indexPaths = [NSIndexPath]()
        for aMessage in messages
        {
            if let creatorId = aMessage.creatorId
            {
                if creatorId == anId
                {
                    indexPaths.append(NSIndexPath(forRow: counter, inSection: 0))
                }
            }
            counter++
        }
        if !indexPaths.isEmpty
        {
            return indexPaths
        }
        
        return nil
    }
    
//    //MARK: UITableViewDelegate
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        
//    }
    
    
    //MARK: ---
    
    func appendMessages(messages:[Message])
    {
        let currentCount = messageObjects.count
        let newMessagesCount = messages.count
        if newMessagesCount >= currentCount
        {
            messageObjects = messages
        }
        else
        {
            messageObjects.removeRange(0...newMessagesCount)
            
            messageObjects += messages
        }
    }

    func refreshTable(note:NSNotification)
    {
        self.trytoGetContactsForLastMessages()
        if let table = self.tableView, userInfo = note.userInfo, ownerId = userInfo["avatarOwnerId"] as? NSNumber, indexPaths = indexPathsForUserId(ownerId.integerValue)
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                table.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
            })
        }
    }
    
    
}
