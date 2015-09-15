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
    let noAvatarImage = UIImage(named: "icon-contacts")
    //var imageFilterer:ImageFilter? = ImageFilter()
    var contactsForLastMessages:[Contact]?
    
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
    }
    
    func reloadLastMessagesForElementId(elementId:NSNumber)
    {
        if let messages = DataSource.sharedInstance.getChatPreviewMessagesForElementId(elementId)
        {
            self.messageObjects = messages
            trytoGetContactsForLastMessages()
        }
    }
    
    private func trytoGetContactsForLastMessages()
    {
        var contactIDs = Set<Int>()
            for aMessage in self.messageObjects
            {
                contactIDs.insert(aMessage.creatorId!.integerValue)
            }
            if let contacts = DataSource.sharedInstance.getContactsByIds(contactIDs)
            {
                self.contactsForLastMessages = Array(contacts)
            }
    }

    //DataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //println("  >>>>>   Preview messages count: \(messageObjects.count )")
        return messageObjects.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var chatCell = tableView.dequeueReusableCellWithIdentifier("PreviewCell", forIndexPath: indexPath) as! ChatPreviewCell
        chatCell.messageLabel.text = messageObjects[indexPath.row].textBody
        chatCell.backgroundColor = UIColor.clearColor()
        // nest two filtering method calls are test stuff
        //1st
//        imageFilterer.filterImageBlackAndWhiteInBackGround(UIImage(named: "testImageToFilter")!, completeInMainQueue: true) { [weak chatCell](image) -> () in
//            if let chatWeakCell = chatCell
//            {
//                chatWeakCell.avatarView.image = image
//            }
//        }
        //2nd
        //chatCell.avatarView.image = ImageFilter().filterImageBlackAndWhite(UIImage(named: "testImageToFilter")!)
        
        //chatCell.avatarView.image = UIImage(named: "testImageToFilter")
        chatCell.avatarView.tintColor = kDayCellBackgroundColor
        let message = messageObjects[indexPath.row]
        if let messageDate = message.dateCreated
        {
            var messageDateString = messageDate.timeDateStringShortStyle()
            chatCell.dateLabel.text = messageDateString as String
        }
        if message.creatorId != nil
        {
            if message.creatorId!.integerValue == DataSource.sharedInstance.user!.userId!.integerValue
            {
                if let username = DataSource.sharedInstance.user!.userName as? String
                {
                    DataSource.sharedInstance.loadAvatarForLoginName(username, completion: {[weak chatCell] (image) -> () in
                        if let cell = chatCell, avatarImage = image
                        {
                            cell.avatarView.image = avatarImage
                        }
                    })
                }
                chatCell.nameLabel.text = DataSource.sharedInstance.user?.firstName as? String ?? DataSource.sharedInstance.user?.lastName as? String
            }
            else
            {
                if let contacts = self.contactsForLastMessages
                {
                    for aContact in contacts
                    {
                        if let userName = aContact.userName as? String
                        {
                            DataSource.sharedInstance.loadAvatarForLoginName(userName, completion: {[weak chatCell] (image) -> () in
                                if let cell = chatCell, avatarImage = image
                                {
                                    cell.avatarView.image = avatarImage
                                }
                            })
                        }
                    }
                }
            }
        }
        
        chatCell.displayMode = self.displayMode
        return chatCell
    }
    
    func messageForIndexPath(indexPath:NSIndexPath) -> Message?
    {
        return messageObjects[indexPath.row] ?? nil
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

    
    
}
