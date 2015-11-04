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
        if let archDate = element.archiveDate?.dateFromServerDateString()
        {
            self.dateArchived = archDate
            print("did Set dateArchived.")
        }
        else
        {
            self.dateArchived = nil
            print("did Delete dateArchived")
        }
        self.dateFinished   = element.finishDate
        self.type           = NSNumber(integer:element.typeId)
        self.finishState    = NSNumber(integer: element.finishState)
        self.isFavourite    = NSNumber(bool:element.isFavourite)
        self.isSignal       = NSNumber(bool:element.isSignal)
        self.hasAttaches    = NSNumber(bool: element.hasAttaches)
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
}
