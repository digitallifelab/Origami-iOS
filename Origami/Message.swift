//
//  Message.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Message:NSObject
{
    /*
    0 - chat message (user`s answer),
    1 - invitation,
    4 - On(Off)line,
    7 - assotiation QUESTION,
    8 - connection between words QUESTION,
    9 - range words QUESTION,
    10 - user`s opinion,
    11 - change mood animation,
    12 - changed user info,
    13 - changed user photo,
    14 - definition QUESTION
    */
    var typeId:NSNumber?
    var messageId:NSNumber?
    var elementId:NSNumber?
    var creatorId:NSNumber?
    var isNew:NSNumber?
    var dateCreated:NSDate?
    var textBody:String?
    var firstName:String?
    
    convenience init(info:[String : AnyObject])
    {
        self.init()
        
        if info.count > 0
        {
            if let lvTypeId = info["TypeId"] as? NSNumber
            {
                self.typeId = lvTypeId
            }
            if let lvMessageId = info["MessageId"] as? NSNumber
            {
                self.messageId = lvMessageId
            }
            if let lvElementId = info["ElementId"] as? NSNumber
            {
                self.elementId = lvElementId
            }
            if let lvCreatorId = info["CreatorId"] as? NSNumber
            {
                self.creatorId = lvCreatorId
            }
            if let lvIsNew = info["IsNew"] as? NSNumber
            {
                self.isNew = lvIsNew
            }
            if let lvFirstName = info["FirstName"] as? String
            {
                self.firstName = lvFirstName
            }
            if let lvMessage = info["Msg"] as? String
            {
                self.textBody = lvMessage
            }
            
            if let dateString = info["CreateDate"] as? NSString
            {
                self.dateCreated = dateString.dateFromServerDateString()
            }
        }
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        var toReturn = [String:AnyObject]()
        if let message = textBody
        {
            toReturn["Msg"] = message
        }
        if let idMessage = messageId
        {
            toReturn["MessageId"] = idMessage
        }
        if let lvElementId = self.elementId
        {
            toReturn["ElementId"] = lvElementId
        }
        if creatorId != nil
        {
            toReturn["CreatorId"] = creatorId
        }
        if isNew != nil
        {
            toReturn["IsNew"] = isNew
        }
        if typeId != nil
        {
            toReturn["TypeId"] = typeId
        }
        if firstName != nil
        {
            toReturn["FirstName"] = firstName
        }
        if dateCreated != nil
        {
            toReturn["CreateDate"] = dateCreated!.dateForServer()
        }
        
        return toReturn
    }
    
    override func isEqual(object:AnyObject?)->Bool
    {
        if let message = object as? Message
        {
            return (self.messageId?.integerValue == message.messageId?.integerValue &&
                self.creatorId?.integerValue == message.creatorId?.integerValue &&
                self.typeId?.integerValue == message.typeId?.integerValue)
        }
        else
        {
            return false
        }
    }
    
    override var hash:Int
        {
            if self.messageId != nil
            {
                return self.messageId!.hashValue ^ self.textBody!.hashValue
            }
            else
            {
                return self.textBody!.hashValue
            }
    }
    
    func compareToAnotherMessage(another:Message) -> NSComparisonResult
    {
        if self.dateCreated != nil  && another.dateCreated != nil
        {
            let comparisonResult = self.dateCreated!.compare(another.dateCreated!)
            return comparisonResult
        }
        else if self.dateCreated != nil && another.dateCreated == nil
        {
            return .OrderedDescending
        }
        else if another.dateCreated != nil && self.dateCreated == nil
        {
            return .OrderedDescending
        }
        else
        {
            return .OrderedSame
        }
    }
}