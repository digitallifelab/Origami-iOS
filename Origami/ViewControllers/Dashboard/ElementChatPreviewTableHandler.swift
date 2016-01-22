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
    
    lazy var messageObjects:[ChatMessagePreviewStruct] = [ChatMessagePreviewStruct]()
    let noAvatarImage = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
    var contactsForLastMessages:[Contact]?

    lazy var currentAvatars = [String:UIImage]()
    
    weak var tableView:UITableView?
    
    override init()
    {
        super.init()
    }
    
    convenience init?(messages:[ChatMessagePreviewStruct]?) // failable initializer - we don`t need to show messages table in messages cell if there are no messages in element chat
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

        chatCell.backgroundColor = UIColor.clearColor()

        if let messageInfo = messageForIndexPath(indexPath)
        {
            chatCell.dateLabel.text = messageInfo.messageDate
            chatCell.messageLabel.text = messageInfo.messageBody
            chatCell.avatarView?.image = messageInfo.authorAvatar
            chatCell.nameLabel.text = messageInfo.authorName
        }
        
        chatCell.displayMode = self.displayMode
        return chatCell
    }
    
    func messageForIndexPath(indexPath:NSIndexPath) -> ChatMessagePreviewStruct? //user also as external API
    {
        return messageObjects[indexPath.row] ?? nil
    }
}
