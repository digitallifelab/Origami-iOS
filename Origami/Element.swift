//
//  Element.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Element:NSObject
{
    var elementId:NSNumber?
    var rootElementId:NSNumber = NSNumber(integer: 0)
    var typeId:NSNumber = NSNumber(integer: 0)
    var title:NSString?
    var details:NSString?
    var attachIDs:[NSNumber] = [NSNumber]()
    var responsible:NSNumber = NSNumber(integer: 0)
    var passWhomIDs:[NSNumber] = [NSNumber]()
    var isSignal:NSNumber = NSNumber(integer: 0)
    var isFavourite:NSNumber = NSNumber(integer: 0)
    var hasAttaches:NSNumber = NSNumber(integer: 0)
    var finishState:NSNumber = NSNumber(integer: 10)
    var finishDate:NSDate?
    var remindDate:NSDate?
    var creatorId:NSNumber = NSNumber(integer: 0)
    var createDate:NSString?
    var changerId:NSNumber?
    var changeDate:NSString?
    var archiveDate:NSString? {
        didSet{
            if archiveDate as! String == kWrongEmptyDate
            {
                
            }
        }
    }
    
    convenience init(info:[String:AnyObject])
    {
        self.init()
        
        if let attachFiles = info["Attaches"] as? [NSNumber]
        {
            self.attachIDs = attachFiles
        }
        if let presentAttaches = info["HasAttaches"] as? NSNumber
        {
            self.hasAttaches = presentAttaches
        }
        if let fav = info["IsFavorite"] as? NSNumber
        {
            self.isFavourite = fav.boolValue
        }
        if let signal = info["IsSignal"] as? NSNumber
        {
            self.isSignal = signal.boolValue
        }
        if let lvTitle = info["Title"] as? NSString
        {
            self.title = lvTitle
        }
        if let lvDescription = info["Description"] as? NSString
        {
            self.details = lvDescription
        }
        if let lvId = info["ElementId"] as? NSNumber
        {
            self.elementId = lvId
        }
        if let rootId = info["RootElementId"] as? NSNumber
        {
            self.rootElementId = rootId
        }
        if let type = info["TypeId"] as? NSNumber
        {
            self.typeId = type
        }
        if let finish = info["FinishState"] as? NSNumber
        {
            self.finishState = finish
        }
        if let finishDate = info["FinishDate"] as? String
        {
            if let date = finishDate.dateFromServerDateString() //still optional
            {
                self.finishDate = date
            }
        }
        if let remind = info["RemindDate"] as? NSString
        {
            self.remindDate = remind.dateFromServerDateString()
        }
        if let creator = info["CreatorId"] as? NSNumber
        {
            self.creatorId = creator
        }
        if let responsibleD = info["Responsible"] as? NSNumber
        {
            self.responsible = responsibleD
        }
        if let creationDate = info["CreateDate"] as? NSString
        {
            self.createDate = creationDate
        }
        if let changer = info["ChangerId"] as? NSNumber
        {
            self.changerId = changer
        }
        if let lvChangeDate = info["ChangeDate"] as? NSString
        {
            self.changeDate = lvChangeDate
        }
        if let archDate = info["ArchDate"] as? String
        {
            if archDate == kWrongEmptyDate
            {
                NSLog(" \n Element archive date recieved : \"\(archDate)\" \n")
                self.archiveDate = "/Date(0)/"
            }
            else
            {
                self.archiveDate = archDate
            }
           
        }
        if info["PassWhomIds"] !== NSNull()
        {
            if let passIDs = info["PassWhomIds"] as? [NSNumber]
            {
                self.passWhomIDs = passIDs
            }
        }
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        var toReturn = [String:AnyObject]()
        toReturn["Responsible"] = self.responsible
        toReturn["ElementId"] = self.elementId //?? NSNull()
        toReturn["RootElementId"] = self.rootElementId //?? NSNull()
        toReturn["TypeId"] = self.typeId //?? NSNull()
        toReturn["Title"] = self.title //?? ""
        toReturn["Description"] = self.details //?? ""
        toReturn["Attaches"] = self.attachIDs //?? NSNull()
        toReturn["HasAttaches"] = self.hasAttaches //?? NSNull()
        toReturn["PassWhomIds"] = self.passWhomIDs //?? NSNull()
        toReturn["IsSignal"] = self.isSignal //?? NSNull()
        toReturn["IsFavorite"] = self.isFavourite //?? NSNull()
        toReturn["FinishState"] = self.finishState //?? NSNull()
        toReturn["FinishDate"] = self.finishDate?.dateForServer() ?? NSDate.dummyDate() //extension on NSDate
        toReturn["RemindDate"] = self.remindDate?.dateForServer() ?? NSDate.dummyDate()
        if let archDateString = self.archiveDate as? String
        {
            if archDateString == kWrongEmptyDate
            {
                self.archiveDate = NSDate.dummyDate()
            }
        }
        
        toReturn["ArchDate"] = self.archiveDate //?? NSNull()
        toReturn["CreateDate"] = self.createDate //?? NSNull()
        toReturn["CreatorId"] = self.creatorId //?? NSNull()
        toReturn["ChangeDate"] = self.changeDate //?? NSNull()
        toReturn["ChangerId"] = self.changerId //?? NSNull()
       
        return toReturn
    }
    
    func createCopy() -> Element
    {
        let copyOfSelf = Element(info: self.toDictionary())
        return copyOfSelf
    }
    
    func isArchived() -> Bool
    {
        if let archiveDateString = self.archiveDate as? String, let archiveDate = archiveDateString.dateFromServerDateString()
        {
            return true
        }
        return false
    }
    
    func isOwnedByCurrentUser() -> Bool
    {
        if let user = DataSource.sharedInstance.user, userIdInt = user.userId?.integerValue
        {
            if userIdInt == self.creatorId.integerValue
            {
                return true
            }
        }
        return false
    }
    
    func isTaskForCurrentUser() -> Bool
    {
        if let user = DataSource.sharedInstance.user, userIdInt = user.userId?.integerValue
        {
            if userIdInt == self.responsible.integerValue
            {
                return true
            }
        }
        return false
    }
    
    func isFinished() -> Bool
    {
        if let finishDateString = self.finishDate
        {
            return true
        }
        return false
    }
    
    func lastChangeDateReadableString() -> String?
    {
        let todayDate = NSDate()
        let yesterday = todayDate.dateByAddingTimeInterval(-1.days)
        
        if let changeDate = self.changeDate as? String,  date = changeDate.dateFromServerDateString()
        {
            if date.lessThanDayAgo()
            {
                let timString = date.timeStringShortStyle()
                return timString
            }
            
            let dateString = date.dateStringShortStyle()
            return dateString
        }
        return nil
    }
    
    func creationDateReadableString(shouldEvaluateCurrentDay:Bool = true) -> String?
    {
        if let created = self.createDate as? String,  date = created.dateFromServerDateString(), readable = date.timeDateStringShortStyle() as? String
        {
            if shouldEvaluateCurrentDay
            {
                //TODO: create string like "2 days ago" , "3 months ago"
            }
            return readable
        }
        return nil
    }
    
    override var hash:Int
        {
            let integer = self.title!.hashValue ^ self.elementId!.hashValue
            return integer
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let lvElement = object as? Element
        {
            var titlesEqual = false
            var descriptionsEqual = false
            var elementIdIsEqual = false
            var typeIdsEqual = false
            var isSignalEqual = false
            var finishStateIsEqual = false
            
            if self.elementId != nil && lvElement.elementId != nil
            {
                if self.elementId!.isEqualToNumber( lvElement.elementId!)
                {
                     elementIdIsEqual = true
                }
            }
            
            if let aTitle = self.title as? String, objTitle = lvElement.title as? String
            {
                if aTitle == objTitle
                {
                    titlesEqual = true
                }
            }
            
            if let aDescription = self.details as? String , objDescription = lvElement.details as? String
            {
                if aDescription == objDescription
                {
                    descriptionsEqual = true
                }
            }
            
            if self.details == nil && lvElement.details == nil
            {
                descriptionsEqual = true
            }
            
            if self.typeId.isEqualToNumber(lvElement.typeId)
            {
                typeIdsEqual = true
            }
            
            if self.isSignal.isEqualToNumber(lvElement.isSignal)
            {
                isSignalEqual = true
            }
            
            if self.finishState.isEqualToNumber(lvElement.finishState)
            {
                finishStateIsEqual = true
            }
            
            
            let equal:Bool = elementIdIsEqual && titlesEqual && descriptionsEqual && typeIdsEqual && isSignalEqual && finishStateIsEqual
            return equal
            
        }
        
        return false
    }
}
