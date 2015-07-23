//
//  DashMessagesHandler.swift
//  Origami
//
//  Created by CloudCraft on 08.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

class DashMessagesHandler:NSObject, UITableViewDelegate, UITableViewDataSource
{

    private var messagesToDisplay:[Message]?
    
    var table:UITableView?
    
    convenience init(messages:[Message])
    {
        self.init()
        self.messagesToDisplay = messages
    }
    
    func setNewMessages(messages:[Message])
    {
        self.messagesToDisplay = messages
    }
    
    func appendMessages(messages:[Message])
    {
        if self.messagesToDisplay != nil
        {
            self.messagesToDisplay! += messages
        }
        else
        {
            self.messagesToDisplay = messages
        }
        
        if self.table != nil
        {
            reloadTableWithNewMessagesCount(messages.count)
        }
    }
    
    func removeMessages(clean:Bool)
    {
        if clean
        {
            self.messagesToDisplay = nil
            return
        }
        
         self.messagesToDisplay?.removeAll(keepCapacity: true)
        reloadTableWithNewMessagesCount(0)
    }
    
    func reloadTableWithNewMessagesCount(newCount:Int)
    {
        if newCount > 0
        {
            let existingCount = self.table?.numberOfRowsInSection(0)
            var lvPaths = [NSIndexPath]()
            for var i = 0; i < newCount; i++
            {
                let lvPath:NSIndexPath = NSIndexPath(forRow: existingCount! + i, inSection: 0)
            }
            self.table?.insertRowsAtIndexPaths(lvPaths, withRowAnimation:UITableViewRowAnimation.Fade)
        }
        else
        {
            self.table?.reloadData()
        }
    }
    
    //MARK: DataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.messagesToDisplay!.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let messageCell = tableView.dequeueReusableCellWithIdentifier("DashMessageCell", forIndexPath: indexPath) as! ChatPreviewCell
        
        let messageInfo = textInfoForIndexPath(indexPath)
        
        messageCell.nameLabel.text = messageInfo.first
        messageCell.messageLabel.text = messageInfo.last
        
        return messageCell
    }
    
    func textInfoForIndexPath(indexPath:NSIndexPath) -> [String]
    {
        var toReturn = ["",""]
        if messagesToDisplay != nil && messagesToDisplay!.count > 0
        {
            let existingMessage:Message = messagesToDisplay![indexPath.row]// as Message
            
            if existingMessage.firstName != nil
            {
                toReturn.insert(existingMessage.firstName!, atIndex: 0) //3 strings
                toReturn.removeLast() //2 strings
            }
            if existingMessage.textBody != nil
            {
                toReturn.removeLast() //1 string if with name, 2 strings if without name
                toReturn.append(existingMessage.textBody!)
            }
        }
        return toReturn
    }
    
    
    
    
}