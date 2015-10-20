//
//  Element.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Element:Hashable, CreateDateComparable
{
    var elementId:Int?
    var rootElementId:Int = 0
    var typeId:Int = 0
    var title:String?
    var details:String?
    var attachIDs:[NSNumber] = [NSNumber]()
    var responsible:Int = 0
    var passWhomIDs:[Int] = [Int]()
    var isSignal:Bool = false
    var isFavourite:Bool = false
    var hasAttaches:Bool = false
    var finishState:Int = 10
    var finishDate:NSDate?
    var remindDate:NSDate?
    var creatorId:Int = 0
    var createDate:String = kWrongEmptyDate
    var changerId:Int?
    var changeDate:String?
    
    var archiveDate:String?
     
    
    //MARK: - CreateDateComparable conformance
    var dateCreated:NSDate? {
        get{
            return self.createDate.dateFromServerDateString()
        }
        set(newDate){
            if let newStringDate = newDate?.dateForServer()
            {
                self.createDate = newStringDate
            }
        }
    }
    //MARK: -
    
    convenience init(info:[String:AnyObject])
    {
        self.init()
        self.setInfo(info)
    }
    
    func setInfo(info:[String:AnyObject])
    {
        if let attachFiles = info["Attaches"] as? [NSNumber]
        {
            self.attachIDs = attachFiles
        }
        if let presentAttaches = info["HasAttaches"] as? NSNumber
        {
            self.hasAttaches = presentAttaches.boolValue
        }
        if let fav = info["IsFavorite"] as? NSNumber
        {
            self.isFavourite = fav.boolValue
        }
        if let signal = info["IsSignal"] as? NSNumber
        {
            self.isSignal = signal.boolValue
        }
        if let lvTitle = info["Title"] as? String
        {
            self.title = lvTitle
        }
        if let lvDescription = info["Description"] as? String
        {
            self.details = lvDescription
        }
        if let lvId = info["ElementId"] as? Int
        {
            self.elementId = lvId
        }
        if let rootId = info["RootElementId"] as? Int
        {
            self.rootElementId = rootId
        }
        if let type = info["TypeId"] as? Int
        {
            self.typeId = type
        }
        if let finish = info["FinishState"] as? Int
        {
            self.finishState = finish
        }
        if let finishDate = info["FinishDate"] as? String
        {
            if let date = finishDate.dateFromServerDateString() //still optional
            {
                self.finishDate = date
                //print("elId: \(self.elementId!), finDate: \(finishDate)")
            }
        }
        
        if let remind = info["RemindDate"] as? String
        {
            self.remindDate = remind.dateFromServerDateString()
        }
        if let creator = info["CreatorId"] as? Int
        {
            self.creatorId = creator
        }
        if let responsibleID = info["Responsible"] as? Int
        {
            self.responsible = responsibleID
        }
        if let creationDate = info["CreateDate"] as? String
        {
            self.createDate = creationDate
        }
        if let changer = info["ChangerId"] as? Int
        {
            self.changerId = changer
        }
        if let lvChangeDate = info["ChangeDate"] as? String
        {
            self.changeDate = lvChangeDate
        }
        if let archDate = info["ArchDate"] as? String
        {
            self.archiveDate = archDate
        }
       
        if let passIDs = info["PassWhomIds"] as? [Int]
        {
            self.passWhomIDs = passIDs
        }
        
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        var toReturn = [String:AnyObject]()
        toReturn["Responsible"] = self.responsible
        toReturn["ElementId"] = self.elementId
        toReturn["RootElementId"] = self.rootElementId
        toReturn["TypeId"] = self.typeId
        toReturn["Title"] = self.title
        toReturn["Description"] = self.details
        toReturn["Attaches"] = self.attachIDs
        toReturn["HasAttaches"] = self.hasAttaches
        toReturn["PassWhomIds"] = self.passWhomIDs
        toReturn["IsSignal"] = NSNumber(bool:self.isSignal)
        toReturn["IsFavorite"] = NSNumber(bool:self.isFavourite)
        toReturn["FinishState"] = self.finishState 
        toReturn["FinishDate"] = self.finishDate?.dateForServer()// ?? NSDate.dummyDate() //extension on NSDate
        print("self.remindDate = ")
        print(self.remindDate)
        toReturn["RemindDate"] = self.remindDate?.dateForServer()// ?? NSDate.dummyDate()
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
        if let archiveDateString = self.archiveDate, let _ = archiveDateString.dateFromServerDateString()
        {
            return true
        }
        return false
    }
    
    func isOwnedByCurrentUser() -> Bool
    {
        if let userId = DataSource.sharedInstance.user?.userId
        {
            if userId == self.creatorId
            {
                return true
            }
        }
        return false
    }
    
    func isTaskForCurrentUser() -> Bool
    {
        if let userId = DataSource.sharedInstance.user?.userId
        {
            if userId == self.responsible
            {
                return true
            }
        }
        return false
    }
    
    func isFinished() -> Bool
    {
        if let _ = self.finishDate
        {
            return true
        }
        return false
    }
    
    func lastChangeDateReadableString() -> String?
    {
        //let todayDate = NSDate()
        //let yesterday = todayDate.dateByAddingTimeInterval(-1.days)
        
        if let changeDate = self.changeDate,  date = changeDate.dateFromServerDateString()
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
    
    func creationDateReadableString(shouldEvaluateCurrentDay shouldEvaluateCurrentDay:Bool = true) -> String?
    {
        if let date = self.createDate.dateFromServerDateString()
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
    
    //MARK: Hashable conformance
    var hashValue:Int {
        return self.title!.hashValue ^ self.elementId!.hashValue
    }

}



func == (lhs:Element, rhs:Element) -> Bool {

    var titlesEqual = false
    var descriptionsEqual = false
    var elementIdIsEqual = false
    var isSignalEqual = false
    //task especially
    var typeIdsEqual = false
    var finishStateIsEqual = false
    var responsiblesAreEqual = false
    
    if lhs.elementId != nil && rhs.elementId != nil
    {
        if lhs.elementId! ==  rhs.elementId!
        {
             elementIdIsEqual = true
        }
    }

    if let aTitle = lhs.title, objTitle = rhs.title
    {
        if aTitle == objTitle
        {
            titlesEqual = true
        }
    }

    if let aDescription = lhs.details, objDescription = rhs.details
    {
        if aDescription == objDescription
        {
            descriptionsEqual = true
        }
    }

    if lhs.details == nil && rhs.details == nil
    {
        descriptionsEqual = true
    }

    if lhs.typeId == rhs.typeId
    {
        typeIdsEqual = true
    }

    if lhs.isSignal == rhs.isSignal
    {
        isSignalEqual = true
    }

    if lhs.finishState == rhs.finishState
    {
        finishStateIsEqual = true
    }

    if lhs.responsible == rhs.responsible
    {
        responsiblesAreEqual = true
    }


    let equal:Bool = elementIdIsEqual && titlesEqual && descriptionsEqual && typeIdsEqual && isSignalEqual && finishStateIsEqual && responsiblesAreEqual
    
    //debug
    if !equal
    {
        if lhs.elementId! == rhs.elementId!
        {
            print("\n -> Elements Not Equal: ")
            print("title: \(titlesEqual), \ndescription: \(descriptionsEqual), \n elementId self:\(lhs.elementId), elementId object: \(rhs.elementId), \n typeIDs:\(lhs.typeId) - \(rhs.typeId), \n signals: \(lhs.isSignal) - \(rhs.isSignal),\n finishState: \(lhs.finishState) - \(rhs.finishState) -> \n")
        }
    }
    
    return equal
}
