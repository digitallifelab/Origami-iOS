//
//  DBElement.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class DBElement: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    func fillInfoFromInMemoryElement(element:Element)
    {
        self.elementId      = NSNumber(integer: element.elementId!)
        self.rootElementId  = NSNumber(integer: element.rootElementId)
        self.responsibleId  = NSNumber(integer: element.responsible)
        self.creatorId      = NSNumber(integer: element.creatorId)
        self.title          = element.title
        self.details        = element.details
        self.dateChanged    = element.changeDate?.dateFromServerDateString()
        self.dateCreated    = element.createDate.dateFromServerDateString()
        self.dateRemind     = element.remindDate
        self.dateFinished   = element.finishDate
        self.type           = NSNumber(integer:element.typeId)
        //print("New FinishState: \(element.finishState) )")
        self.finishState    = NSNumber(integer: element.finishState)
        self.isFavourite    = NSNumber(bool:element.isFavourite)
        self.isSignal       = NSNumber(bool:element.isSignal)
        self.hasAttaches    = NSNumber(bool: element.hasAttaches)

        let archDateOptional = element.archiveDate?.dateFromServerDateString()
        
        if let archDate = archDateOptional, currentArchDate = self.dateArchived
        {
            if  archDate.compare(currentArchDate) != .OrderedSame
            {
                //print("archived date before: \(self.dateArchived)")
                self.dateArchived = archDate
                //print("did Set NEW dateArchived. id = \(self.elementId?.integerValue ?? 0)")
                //print("archived date after: \(self.dateArchived)")
            }
        }
        else if archDateOptional != nil
        {
            self.dateArchived = archDateOptional
            //print(" Did set NEW date archived, id: \(self.elementId!)")
        }
        else if self.dateArchived != nil
        {
            self.dateArchived = nil
            //print(" Did Remove Archive Date, id: \(self.elementId!)")
        }
//        else if self.dateArchived == nil && archDateOptional == nil
//        {
//            print(" Did not change DateArchived, id: \(self.elementId!)")
//        }
        
    }
    
    func isTaskForCurrentUser() -> Bool{
        guard let responsibleIdInt = self.responsibleId?.integerValue, userId = DataSource.sharedInstance.user?.userId else
        {
            return false
        }
        return responsibleIdInt == userId
    }
    
    func lastChangeDateReadableString() -> String?
    {
        if let changeDate = self.dateChanged
        {
            if changeDate.lessThanDayAgo()
            {
                let timString = changeDate.timeStringShortStyle()
                return timString
            }
            
            let dateString = changeDate.dateStringShortStyle()
            return dateString
        }
        return nil
    }
    
    func creationDateReadableString(shouldEvaluateCurrentDay shouldEvaluateCurrentDay:Bool = true) -> String?
    {
        if let date = self.dateCreated
        {
            let readable:String = date.timeDateStringShortStyle() as String
            if shouldEvaluateCurrentDay
            {
                //TODO: create string like "2 days ago" , "3 months ago"
            }
            return readable
        }
        return nil
    }
    
    func isArchived() -> Bool
    {
        return self.dateArchived != nil
    }
    
    func isOwnedByCurrentUser() -> Bool
    {
        if let userId = DataSource.sharedInstance.user?.userId, elementCreatorId = self.creatorId?.integerValue
        {
            if userId == elementCreatorId
            {
                return true
            }
        }
        return false
    }
    
    var canBeEditedByCurrentUser:Bool
    {
        if let userId = DataSource.sharedInstance.user?.userId, elementCreatorId = self.creatorId?.integerValue
        {
            if userId == elementCreatorId
            {
                return true
            }
            else
            {
                return DataSource.sharedInstance.currentUserCanEditElementByManagedObjectID(self.objectID)
            }
        }
        return false
    }
    
    func addMessages(messages:Set<DBMessageChat>)
    {
        if let existingMessages = self.messages as? Set<DBMessageChat>
        {
            let newMessages = existingMessages.union(messages)
            self.messages = newMessages
            print("\n-> did add messages for \(self.elementId!)")
        }
        
    }
    
    func createCopyForServer() -> Element
    {
        let lvElement = Element()
        lvElement.elementId = self.elementId!.integerValue
        lvElement.creatorId = self.creatorId!.integerValue
        lvElement.responsible = self.responsibleId!.integerValue
        lvElement.archiveDate = self.dateArchived?.dateForServer()
        lvElement.typeId = self.type!.integerValue
        lvElement.finishState = self.finishState!.integerValue
        lvElement.finishDate = self.dateFinished
        lvElement.isSignal = self.isSignal!.boolValue
        lvElement.title = self.title
        lvElement.details = self.details
        lvElement.remindDate = self.dateRemind
        
        return lvElement
    }
    
    func orderedAttaches() -> [DBAttach]?
    {
        if let attachesSet = self.attaches as? Set<DBAttach>
        {
            var attachesArray = Array(attachesSet)
            attachesArray.sortInPlace({ (attach1, attach2) -> Bool in
                return attach1 < attach2 //DateCreateComparable protocol conformance
            })
            
            return attachesArray
        }
        return nil
    }
    
    var latestChatMessage:DBMessageChat? {
        if let messages = self.messages as? Set<DBMessageChat> where messages.count > 0
        {
            let latestMessage = messages.sort({ (message1, message2) -> Bool in
                
                if let date1 = message1.dateCreated, date2 = message2.dateCreated
                {
                    return date1.compare(date2) == .OrderedDescending
                }
            
                return false
                
            }).first
            
            return latestMessage
        }
        return nil
    }
    
    var latestAffectingDate : NSDate? {
        guard let lvDate = self.dateCreated else
        {
            return nil
        }
        
        var dateToReturn = lvDate
        
        if let lastMessageDate = self.latestChatMessage?.dateCreated
        {
            dateToReturn = lastMessageDate
        }
        
        if let changeDate = self.dateChanged
        {
            if changeDate.compare(dateToReturn) == .OrderedDescending
            {
                dateToReturn = changeDate
            }
        }
        
        return dateToReturn
    }
}
