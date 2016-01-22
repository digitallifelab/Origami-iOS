//
//  DBMessageChat.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class DBMessageChat: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    func fillInfoFromMessageObject(message:Message)
    {
        if let selfId = self.messageId?.integerValue
        {
            if selfId != message.messageId
            {
                self.messageId = NSNumber(integer:message.messageId)
               // print("---> WARNING:  Message did change messageId: \(selfId) -> \(self.messageId)")
            }
        }
        else
        {
            self.messageId = NSNumber(integer:message.messageId)
        }
        
        if self.textBody != message.textBody
        {
            self.textBody = message.textBody
        }
        if let ownDate = self.dateCreated, newDate = message.dateCreated
        {
            if ownDate.compare(newDate) != .OrderedSame
            {
                self.dateCreated = message.dateCreated
                print("did Update message date.")
            }
        }
        else
        {
            self.dateCreated = message.dateCreated
            //print("did Set New message date.")
        }
        
        if let _ = self.elementId?.integerValue
        {
            if self.elementId!.integerValue != message.elementId!
            {
                self.elementId = NSNumber(integer: message.elementId!)
            }
        }
        else
        {
            self.elementId = NSNumber(integer: message.elementId!)
        }
        
        if let _ = self.creatorId?.integerValue
        {
            if self.creatorId!.integerValue != message.creatorId!
            {
                self.creatorId = NSNumber(integer: message.creatorId!)
            }
        }
        else
        {
            self.creatorId = NSNumber(integer:message.creatorId!)
        }
        
        if self.firstName != message.firstName
        {
            self.firstName = message.firstName
        }
    }
}
