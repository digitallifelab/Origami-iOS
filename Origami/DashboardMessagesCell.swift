//
//  DashboardMessagesCell.swift
//  Origami
//
//  Created by CloudCraft on 11.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class DashboardMessagesCell : UICollectionViewCell, UITableViewDelegate, MessageObserver // to simplify development, I don`t divide simple table delegate logic to separate classes
{
    var displayMode:DisplayMode = .Day
    var messagesDatasource:ElementChatPreviewTableHandler?
    @IBOutlet var messagesTable:UITableView!
    var currentMessages:[Message]?
    
        override func awakeFromNib() {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: FinishedLoadingMessages, object: DataSource.sharedInstance)
            messagesTable.scrollsToTop = false
            if currentMessages == nil
            {
                currentMessages = [Message]()
            }
        }
    override func prepareForReuse()
    {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: FinishedLoadingMessages, object: DataSource.sharedInstance)
        
        if currentMessages == nil
        {
            currentMessages = [Message]()
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        //NSNotificationCenter.defaultCenter().postNotificationName(kHomeScreenMessageTappedNotification, object:nil, userInfo: nil)
        
        if let messageTapped = self.messagesDatasource?.messageForIndexPath(indexPath)
        {
            NSNotificationCenter.defaultCenter().postNotificationName(kHomeScreenMessageTappedNotification, object:messageTapped, userInfo: nil)
        }
    }
    
    
    //MARK: --------
    
    func getLastMessages()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: FinishedLoadingMessages, object: DataSource.sharedInstance)
        
        DataSource.sharedInstance.getLastMessagesForDashboardCount(MaximumLastMessagesCount/*3 by default*/, completion: {[weak self] (messages) -> () in
            if let aSelf = self
            {
                if let recievedMessages = messages, _ = aSelf.currentMessages
                {
                    aSelf.reloadChatTableWithNewMessages(recievedMessages)
                    DataSource.sharedInstance.addObserverForNewMessagesForElement(aSelf, elementId: All_New_Messages_Observation_ElementId)
                }
                else
                {
                    NSNotificationCenter.defaultCenter().addObserver(aSelf, selector: "refreshHomeMessages:", name: FinishedLoadingMessages, object: DataSource.sharedInstance)
                }
            }
        })
    }
    
    func reloadChatTableWithNewMessages(messages:[Message]?)
    {
        if let toShow = messages, existing = self.currentMessages
        {
            let currentMessagesSet = Set(existing)
            let newMessages = Set(toShow)
            
            let filteredSetOfMessages = currentMessagesSet.exclusiveOr(newMessages)
            var messagesArray = Array(filteredSetOfMessages)
            
            ObjectsConverter.sortMessagesByDate(&messagesArray)
            
            let count = messagesArray.count
            if count > MaximumLastMessagesCount
            {
                //leave only 3 last messages ( or any number set in "MaximumLastMessagesCount" constant)
                let cutArray = Array(messagesArray[count-MaximumLastMessagesCount..<count])
                self.messagesDatasource = ElementChatPreviewTableHandler(messages: cutArray)
            }
            else
            {
                self.messagesDatasource = ElementChatPreviewTableHandler(messages: toShow)
            }
            
            self.messagesDatasource?.displayMode = self.displayMode
            self.messagesTable.dataSource = self.messagesDatasource
            self.messagesTable.delegate = self
            self.messagesTable.reloadData()
        }
    }
    
    func refreshHomeMessages(notification:NSNotification?)
    {
        getLastMessages()
    }
    
    //MARK: MessageObserver
    func newMessagesAdded(messages:[Message])
    {
        let mainQueue = NSOperationQueue.mainQueue()
        
        mainQueue.addOperationWithBlock
            {
                [unowned self] () -> Void in
                self.reloadChatTableWithNewMessages(messages)
        }
    }
}
