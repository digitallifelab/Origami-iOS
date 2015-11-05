//
//  DashboardMessagesCell.swift
//  Origami
//
//  Created by CloudCraft on 11.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class DashboardMessagesCell : UICollectionViewCell, UITableViewDelegate // to simplify development, I don`t divide simple table delegate logic to separate classes
{
    var displayMode:DisplayMode = .Day
    var messagesDatasource:ElementChatPreviewTableHandler?
    @IBOutlet var messagesTable:UITableView!
    //var currentMessages:[Message]?
    var messages:[DBMessageChat]?
    
    override func awakeFromNib()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: FinishedLoadingMessages, object: DataSource.sharedInstance)
        messagesTable.scrollsToTop = false
    }
    
    override func prepareForReuse()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: FinishedLoadingMessages, object: DataSource.sharedInstance)
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let tappedMessage = messages?[indexPath.row], elementId = tappedMessage.elementId
        {
             NSNotificationCenter.defaultCenter().postNotificationName(kHomeScreenMessageTappedNotification, object:elementId, userInfo: nil)
        }
    }
    
    
    //MARK: --------
    
    func getLastMessages()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: FinishedLoadingMessages, object: DataSource.sharedInstance)
        
        let bgOpUserInteractive = NSBlockOperation() {
            DataSource.sharedInstance.localDatadaseHandler?.readLastMessagesForHomeDashboard {[weak self] (dbMessages, error) -> () in
                
                if let dbError = error
                {
                    print("error while querying messages from dashboart messages cell: \(dbError)")
                    return
                }
                
                if let messagesFromDB = dbMessages
                {
                    if let weakSelf = self
                    {
                        weakSelf.messages = messagesFromDB
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            weakSelf.reloadChatTableWithNewMessages(weakSelf.messages)
                        })
                    }
                }
            }
        }
        
        if #available (iOS 9.0, *)
        {
            bgOpUserInteractive.qualityOfService = NSQualityOfService.UserInteractive
        }
        else
        {
            bgOpUserInteractive.queuePriority = .High
        }
        
        let bgQueue = NSOperationQueue()
        bgQueue.maxConcurrentOperationCount = 2
        bgQueue.addOperation(bgOpUserInteractive)
    }
    
    func reloadChatTableWithNewMessages(messages:[DBMessageChat]?)
    {
        guard let nonNilMessages = messages else
        {
            return
        }
        
        //prepare info for chat cells
        var messageInfosForDataSource = [ChatMessagePreviewStruct]()
        
        for aChatMessage in nonNilMessages
        {
            var dateString = aChatMessage.dateCreated?.timeDateString()
            if let date = aChatMessage.dateCreated
            {
                if date.lessThanDayAgo()
                {
                    dateString = date.timeStringShortStyle()
                }
                else
                {
                    dateString = date.dateStringShortStyle()
                }
            }
            
            var messageInfo = ChatMessagePreviewStruct(name: nil, text: aChatMessage.textBody, date: dateString, avatarPreview: nil)
            
           
            if let creatorId = aChatMessage.creatorId?.integerValue
            {
                var lvUserName:String?
                
                if let messageCreatorTuple = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(creatorId)
                {
                    if let dbPerson = messageCreatorTuple.db
                    {
                        messageInfo.authorName = dbPerson.initialsString()
                        lvUserName = dbPerson.userName
                    }
                    else if let  memoryPerson = messageCreatorTuple.memory // should be only current user
                    {
                        messageInfo.authorName = memoryPerson.initialsString()
                        lvUserName = memoryPerson.userName
                    }
                }
                
                if let avatarPreview = DataSource.sharedInstance.getAvatarForUserId(creatorId)
                {
                    messageInfo.authorAvatar = avatarPreview
                }
                else if let userName = lvUserName
                {
                    DataSource.sharedInstance.startLoadingAvatarForUserName((name:userName,id:creatorId))
                }
                
            }
            
            messageInfosForDataSource.append(messageInfo)
        }
        
        self.messagesDatasource = ElementChatPreviewTableHandler(messages: messageInfosForDataSource)
        
        self.messagesDatasource?.displayMode = self.displayMode
        self.messagesTable.dataSource = self.messagesDatasource
        self.messagesTable.delegate = self
        self.messagesTable.reloadData()
    }
    
//    func refreshHomeMessages(notification:NSNotification?)
//    {
//        getLastMessages()
//    }
    
}
