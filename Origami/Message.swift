//
//  Message.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Message:Hashable, CreateDateComparable
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
    65535 - user was blocked
    65534 - user was unBlocked
    */
    var type:MessageType = .Undefined
    var messageId:Int = 0
    var elementId:NSNumber?
    var creatorId:NSNumber?
    var isNew:NSNumber?
    
    var textBody:String?
    var firstName:String?
    
    private var pDateCreated:NSDate?
    
    //MARK: - CreateDateComparable conformance
    var dateCreated:NSDate?{
        get{
            return self.pDateCreated
        }
        set(newDate){
            self.pDateCreated = newDate
        }
    }
    //MARK: -
    convenience init(info:[String : AnyObject])
    {
        self.init()
        
        if info.count > 0
        {
            if let lvTypeId = info["TypeId"] as? Int, mesageType = MessageType(rawValue: lvTypeId)
            {
                self.type = mesageType
            }
            if let lvMessageId = info["MessageId"] as? Int
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
        
        toReturn["MessageId"] = self.messageId
        
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
        
        toReturn["TypeId"] = type.rawValue
        
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
    
    
    var hashValue:Int {
        
        return self.messageId.hashValue
    }
    
}

func == (lhs:Message, rhs:Message) -> Bool
{
    return (
        lhs.messageId == rhs.messageId &&  lhs.type == rhs.type &&
        lhs.creatorId?.integerValue == rhs.creatorId?.integerValue
       
    )
}



