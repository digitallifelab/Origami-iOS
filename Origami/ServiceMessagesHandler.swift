//
//  ServiceMessagesHandler.swift
//  Origami
//
//  Created by CloudCraft on 15.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
class ServiceMessagesHandler {

    var isUpdatingContacts = false
    
    var contactAvatarChangeIDs = Set<Int>()
    var contactInfoChangeIDs = Set<Int>()
    var changedUsersStatuses = [Int:PersonAuthorisationState]()  // [userID:Message]
    
    private func getBlockedUserIDs() -> Set<Int>?
    {
        var returningSet : Set<Int>?
        for (key, status) in changedUsersStatuses
        {
            if status == .Blocked
            {
                if let _ = returningSet{
                    returningSet!.insert(key)
                }
                else
                {
                    returningSet = Set([key])
                }
            }
        }
        
        return returningSet
    }
    
    /**
    - Note: Be shure, that method invocation does not happen on MainThread
    */
    func startProcessingServiceMessages(messages:[Message])
    {
        for aMessage in messages
        {
            switch aMessage.type
            {
            case .UserUnblocked:
                if let userIdInt = aMessage.getTargetUserIdFromMessageBody()
                {
                    changedUsersStatuses[userIdInt] = .Normal
                }
            case .UserBlocked:
                if let userIdInt = aMessage.getTargetUserIdFromMessageBody()
                {
                    changedUsersStatuses[userIdInt] = .Blocked
                }
            case .UserInfoUpdated:
                if let userIdInt = aMessage.getTargetUserIdFromMessageBody()
                {
                    contactInfoChangeIDs.insert(userIdInt)
                }
            case .UserPhotoUpdated:
                if let userIdInt = aMessage.getTargetUserIdFromMessageBody()
                {
                    if let lastSyncDateForContactAvatar = DataSource.sharedInstance.getLastAvatarSyncDateForContactId(userIdInt), messageDate = aMessage.dateCreated
                    {
                        if lastSyncDateForContactAvatar.compare(messageDate) != .OrderedDescending
                        {
                            contactAvatarChangeIDs.insert(userIdInt)
                        }
                        else
                        {
                            break
                        }
                    }
                    else
                    {
                        contactAvatarChangeIDs.insert(userIdInt)
                    }
                }
            case .OnlineStatusChanged:
                print("Recieved Service Message  User did change OnlineStatus: element:\(aMessage.elementId!), status = \(aMessage.textBody!)")
            default:
                break
            }
        }
        
        if !changedUsersStatuses.isEmpty { /// long procedure
            self.startUpdatingUsersStatuses()
        }
        
        if !contactAvatarChangeIDs.isEmpty { /// might me longer, because data from disc is also erased, asynchronously, but might be long
            print("\n Changed User Avatars for IDs: \(contactAvatarChangeIDs)\n")
            self.startUpdatingChangedUserAvatars()
        }
        
        if !contactInfoChangeIDs.isEmpty {
            print("\n Changed User Info for IDs:  \(contactInfoChangeIDs)\n")
        }
    }
    
    /**
    
    If current user is blocked, method returns and *Logout* chain is started
    
    if current user is not blocked the currently existing contacts start to update *`state`* property
    - Note: This method is Synchronous -> Don`t call it on Main Thread
    */
    private func startUpdatingUsersStatuses()
    {
        if isUpdatingContacts {
            NSLog(" ERROR -> Never call \"startUpdatingUsersInfoStatuses\" while updating is in progress.")
            return
        }
        
        if changedUsersStatuses.isEmpty {
            isUpdatingContacts = false
            return
        }
        
        isUpdatingContacts = true
        
        guard let currentUserID = DataSource.sharedInstance.user?.userId else
        {
            isUpdatingContacts = false
            return
        }
        
        if let userStatus = changedUsersStatuses[currentUserID],  currentStatus = DataSource.sharedInstance.user?.state
        {
            if userStatus != currentStatus
            {
                switch userStatus
                {
                case .Blocked:
                    DataSource.sharedInstance.user?.state = .Blocked
                    isUpdatingContacts = false
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        NSNotificationCenter.defaultCenter().postNotificationName(kLogoutNotificationName, object: self)
                    })
                    
                    return
                default:
                    DataSource.sharedInstance.user?.state = userStatus //we are interested now only in "Blocked" status
                }
            }
        }
        
        
        
        do{
             let allCurrentContacts = try DataSource.sharedInstance.getMyContacts()
                var shouldPostContactsUpdateNotification = false
                
                for aContact in allCurrentContacts
                {
                    if let statusInt = aContact.contactId?.integerValue, let contactStatus:PersonAuthorisationState = changedUsersStatuses[statusInt]
                    {
                        aContact.state = NSNumber(integer:contactStatus.rawValue)
                        shouldPostContactsUpdateNotification = true
                        //print("->ServiceMessagesHandler  did update status for contact:  ID:\(aContact.contactId)  LoginName:\(aContact.userName)\n")
                    }
                }
                
                if shouldPostContactsUpdateNotification
                {
                    NSNotificationCenter.defaultCenter().postNotificationName(kContactsStatusDidChangeNotification, object: self)
                }
                
                changedUsersStatuses.removeAll()
                
                isUpdatingContacts = false
        }
        catch
        {
            isUpdatingContacts = false
        }
    }
    
    private func startUpdatingChangedUserAvatars()
    {
        if isUpdatingContacts {
            NSLog(" ERROR -> Never call \"startUpdatingChangedUserAvatars\" while updating is in progress.")
            return
        }
        
        isUpdatingContacts = true
        
        if contactAvatarChangeIDs.isEmpty {
            isUpdatingContacts = false
            return
        }
        

        isUpdatingContacts = true
        
        do
        {
            let allCurrentContacts = try DataSource.sharedInstance.getMyContacts()
            isUpdatingContacts = true
            
            let currentDate = NSDate()
            
            
            for aContact in allCurrentContacts
            {
                guard let contactId = aContact.contactId?.integerValue, userName = aContact.userName else
                {
                    continue
                }
                
                if contactAvatarChangeIDs.contains(contactId)
                {
                    DataSource.sharedInstance.cleanAvatarDataForUserName(userName, userId: contactId)
                    print("->ServiceMessagesHandler  did CLEAN AVATAR for contact:  ID:\(contactId)  LoginName:\(userName)\n")
                    DataSource.sharedInstance.setLastAvatarSyncDate(currentDate, forContactId: contactId)
                }
            }
            
            contactAvatarChangeIDs.removeAll()
            
            isUpdatingContacts = false
        }
        catch
        {
            isUpdatingContacts = false
            return
        }
        

        
    }
    
    
    
}

