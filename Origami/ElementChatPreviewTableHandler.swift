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
    let noAvatarImage = UIImage(named: "icon-No-Avatar")
    override init()
    {
        super.init()
    }
    
    convenience init?(messages:[Message]) // failable initializer - we don`t need to show messages table in messages cell if there are no messages in element chat
    {
        self.init()
        if messages.isEmpty
        {
            return nil
        }
        self.messageObjects = messages
    }
    
    func reloadLastMessagesForElementId(elementId:NSNumber)
    {
        self.messageObjects = DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: elementId, lastMessageId: nil)
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
        chatCell.avatarView.image = noAvatarImage
        chatCell.displayMode = self.displayMode
        return chatCell
    }
    
    func messageForIndexPath(indexPath:NSIndexPath) -> Message?
    {
        return messageObjects[indexPath.row] ?? nil
    }
    
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
