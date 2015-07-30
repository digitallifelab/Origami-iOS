//
//  HandledObjects.swift
//  Origami
//
//  Created by CloudCraft on 02.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class User
{
    var birthDay:NSString? //
    var phone:NSString? //
    var country:NSString? //
    var countryId:NSNumber? //
    var language:NSString? //
    var languageId:NSNumber? //
    
    var firstName:NSString? //
    var lastName:NSString? //
    var userName:NSString? //
    var password:NSString? //
    var lastSync:NSString? //
    var token:NSString? //
    var userId:NSNumber? //
    
    var mood:NSString? //
    var state:NSNumber? //
    var sex:NSNumber? //
    var regDate:NSString? //
    var photo:NSData? //
    
    convenience init(info:[String:AnyObject])
    {
        self.init()
        
        if info.count > 0
        {
            if let userName = info["UserName"] as? NSString
            {
                self.userName = userName
            }
            if let lastName = info["LastName"] as? NSString
            {
                self.lastName = lastName
            }
            if let firstName = info["FirstName"] as? NSString
            {
                self.firstName = firstName
            }
            if let token = info["Token"] as? NSString
            {
                self.token = token
            }
            if let password = info["Password"] as? NSString
            {
                self.password = password
            }
            if let userId = info["UserId"] as? NSNumber
            {
                self.userId = userId
            }
            if let mood = info["Mood"] as? NSString
            {
                self.mood = mood
            }
            if let lvSex = info["Sex"] as? NSNumber
            {
                self.sex = lvSex
            }
            if let state = info["State"] as? NSNumber
            {
                self.state = state
            }
            if let lvPhoto = info["Photo"] as? NSData
            {
                self.photo = lvPhoto
            }
            if let lvRegDate = info["RegDate"] as? NSString
            {
                self.regDate = lvRegDate
            }
            if let lvSync = info["LastSync"] as? NSString
            {
                self.lastSync = lvSync
            }
            if let lvBirthDay = info["BirthDay"] as? NSString
            {
                self.birthDay = lvBirthDay
            }
            if let lvTel = info["PhoneNumber"] as? NSString
            {
                self.phone = lvTel
            }
            if let lvCountry = info["Country"] as? NSString
            {
                self.country = lvCountry
            }
            if let lvCountryId = info["CountryId"] as? NSNumber
            {
                self.countryId = lvCountryId
            }
            if let lvLanguage = info["Language"] as? NSString
            {
                self.language = lvLanguage
            }
            if let lvLangId = info["LanguageId"] as? NSNumber
            {
                self.languageId = lvLangId
            }
        }
    }
    
    func toDictionary() -> NSDictionary
    {
        var toReturn = NSMutableDictionary(capacity: 10)
        toReturn["LoginName"]   = self.userName //?? NSNull()
        toReturn["Password"]    = self.password //?? NSNull()
        
        toReturn["FirstName"]   = self.firstName //?? NSNull()
        toReturn["LastName"]    = self.lastName // ?? NSNull()
        
        toReturn["Token"]       = self.token //?? NSNull()
        toReturn["UserId"]      = self.userId //?? NSNull()
        
        toReturn["Mood"]        = self.mood //?? NSNull()
        toReturn["State"]       = self.state //?? NSNull()
        toReturn["Sex"]         = self.sex  //?? NSNull()
        toReturn["PhoneNumber"] = self.phone  //?? NSNull()
        toReturn["BirthDay"]    = self.birthDay // ?? NSNull()
        toReturn["RegDate"]     = self.regDate //?? NSNull()
        toReturn["LastSync"]    = self.lastSync// ?? NSNull()
        
        toReturn["Country"]     = self.country
        toReturn["CountryId"]   = self.countryId
        toReturn["Language"]    = self.language
        toReturn["LanguageId"]  = self.languageId
        
        // photo we neither store in USer object nor Send it to server as paramater of User
        
        
        return toReturn
    }
    
}

class Contact:NSObject
{
    var birthDay:NSString?
    var phone:NSString?
    var country:NSString?
    var countryId:NSNumber?
    var language:NSString?
    var languageId:NSNumber?
    
    var firstName:NSString?
    var lastName:NSString?
    var userName:NSString?
  
    var lastSync:NSString?
    var contactId:Int?
    
    var mood:NSString?
    var state:NSNumber?
    var sex:NSNumber?
    var regDate:NSString?
    var photo:NSData?
    
    var isFavourite:NSNumber?
    var elementId:NSNumber?
    var isOnline:NSNumber?
    
    convenience init(info:Dictionary<String, AnyObject>)
    {
        self.init()
        
        if let name = info["FirstName"] as? NSString
        {
            self.firstName = name
        }
        if let last = info["LastName"] as? NSString
        {
            self.lastName = last
        }
        if let uName = info["LoginName"] as? NSString
        {
            self.userName = uName
        }
        if let element = info["ElementId"] as? NSNumber
        {
            self.elementId = element
        }
        if let lvContactId = info["ContactId"] as? Int
        {
            self.contactId = lvContactId
        }
        if let fav = info["IsFavourite"] as? NSNumber
        {
            self.isFavourite = fav
        }
        if let lvState = info["State"] as? NSNumber
        {
            self.state = lvState
        }
        if let reg = info["RegDate"] as? NSString
        {
            self.regDate = reg.timeDateStringFromServerDateString()
        }
        if let birth = info["BirthDate"] as? NSString
        {
            self.birthDay = birth.timeDateStringFromServerDateString()
        }
        if let sync = info["LastSync"] as? NSString
        {
            self.lastSync = sync.timeDateStringFromServerDateString()
        }
        if let lvSex = info["Sex"] as? NSNumber
        {
            self.sex = lvSex
        }
        if let lvMood = info["Mood"] as? NSString
        {
            self.mood = lvMood
        }
        if let tel = info["PhoneNUmber"] as? NSString
        {
            self.phone = tel
        }
        if let lvCountry = info["Country"] as? NSString
        {
            self.country = lvCountry
        }
        if let lvCountryId = info["CountryId"] as? NSNumber
        {
            self.countryId = lvCountryId
        }
        if let lvLanguage = info["Language"] as? NSString
        {
            self.language = lvLanguage
        }
        if let lvLangId = info["LanguageId"] as? NSNumber
        {
            self.languageId = lvLangId
        }
        if let photoData = info["Photo"] as? NSData
        {
            self.photo = photoData
        }
    }
    
    func toDictionary() -> NSDictionary
    {
        var toReturn = NSMutableDictionary(capacity: 10)
        
        toReturn["LoginName"]   = self.userName //?? NSNull()
        
        toReturn["FirstName"]   = self.firstName //?? NSNull()
        toReturn["LastName"]    = self.lastName // ?? NSNull()
        toReturn["ContactId"]   = self.contactId
        
        toReturn["Mood"]        = self.mood //?? NSNull()
        toReturn["State"]       = self.state //?? NSNull()
        toReturn["Sex"]         = self.sex  //?? NSNull()
        toReturn["PhoneNumber"] = self.phone  //?? NSNull()
        toReturn["BirthDay"]    = self.birthDay // ?? NSNull()
        toReturn["RegDate"]     = self.regDate //?? NSNull()
        toReturn["LastSync"]    = self.lastSync// ?? NSNull()
        
        toReturn["Country"]     = self.country
        toReturn["CountryId"]   = self.countryId
        toReturn["Language"]    = self.language
        toReturn["LanguageId"]  = self.languageId
        
        toReturn["IsFavourite"] = self.isFavourite
        toReturn["isOnline"]    = self.isOnline
        
        
        return toReturn
    }
    
    override func isEqual(contact:AnyObject?)->Bool
    {
        if let object = contact as? Contact
        {
            if let selfContactId = self.contactId, let objectContactId = object.contactId
            {
                if selfContactId == objectContactId
                {
                    return true
                }
            }
        }
        
        return false
    }
    
    override var hash:Int
    {
        return self.userName!.hashValue ^ self.contactId!.hashValue
    }
    
}

class Element:NSObject
{
    var elementId:Int?
    var rootElementId:Int?
    var typeId:NSNumber?
    var title:NSString?
    var details:NSString?
    var attachIDs:[NSNumber]?
    var passWhomIDs:[Int]?
    var isSignal:Bool?
    var isFavourite:Bool?
    var hasAttaches:NSNumber?
    var finishState:NSNumber?
    var finishDate:NSDate?
    var remindDate:NSDate?
    var creatorId:NSNumber?
    var createDate:NSString?
    var changerId:NSNumber?
    var changeDate:NSString?
    var archiveDate:NSString?
    
    
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
        if let lvId = info["ElementId"] as? Int
        {
            self.elementId = lvId
        }
        if let rootId = info["RootElementId"] as? Int
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
        if let finishDate = info["FinishDate"] as? NSString
        {
            self.finishDate = finishDate.dateFromServerDateString() //still optional
        }
        if let remind = info["RemindDate"] as? NSString
        {
            self.remindDate = remind.dateFromServerDateString()
        }
        if let creator = info["CreatorId"] as? NSNumber
        {
            self.creatorId = creator
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
        if let archDate = info["ArchDate"] as? NSString
        {
            self.archiveDate = archDate
        }
        if let passIDsValue = info["PassWhomIds"]
        {
            if let passIDs = passIDsValue as? [Int]
            {
                self.passWhomIDs = passIDs
                println(" -> \(passIDs) for element \(self.elementId)")
            }
            else
            {
                println("->Null passWhomIDs for element \(self.elementId)")
            }
        }
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        var toReturn = [String:AnyObject]()
        
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
        toReturn["FinishDate"] = self.finishDate?.dateForServer() //?? NSDate.dummyDate() //extension on NSDate
        toReturn["RemindDate"] = self.remindDate?.dateForServer() //?? NSDate.dummyDate()
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
    
    override var hash:Int
        {
            let integer = self.title!.hashValue ^ self.elementId!.hashValue
        return integer
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let lvElement = object as? Element
        {
            if self.elementId != nil && lvElement.elementId != nil
            {
                if self.elementId! == lvElement.elementId!
                {
                    return true
                }
            }
        }
        
        return false
    }
}

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
    
    func toDictionary() ->NSDictionary
    {
        var toReturn = NSMutableDictionary(capacity:7)
        if textBody != nil
        {
            toReturn["Msg"] = textBody
        }
        if messageId != nil
        {
            toReturn["MessageId"] = messageId
        }
        if elementId != nil
        {
            toReturn["ElementId"] = elementId
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

class AttachFile :NSObject
{
    var attachID:NSNumber?
    var elementID:NSNumber?
    var creatorID:NSNumber?
    var fileSize:NSNumber?
    var fileName:String?
    var createDate:String?
    
    convenience init(info:Dictionary<String,AnyObject>)
    {
        self.init()
        
        if info.count > 0
        {
            if let lvCreator = info["CreatorId"] as? NSNumber
            {
                self.creatorID = lvCreator
            }
            
            if let lvID = info["Id"] as? NSNumber
            {
                self.attachID = lvID
            }
            
            if let lvElementId = info["ElementId"] as? NSNumber
            {
                self.elementID = lvElementId
            }
            
            if let lvFileSize = info["Size"] as? NSNumber
            {
                self.fileSize = lvFileSize
            }
            
            if let lvName = info["FileName"] as? NSString
            {
                let name = lvName.stringByReplacingOccurrencesOfString("/", withString: "-")
                self.fileName = name
            }
            
            if let lvDate = info["CreateDate"] as? String
            {
                self.createDate = lvDate
            }
        }
    }
    
    override func isEqual(object:AnyObject?) -> Bool
    {
        if let attachObject  = object as? AttachFile
        {
            return (self.attachID?.integerValue == attachObject.attachID?.integerValue && self.elementID?.integerValue == attachObject.elementID?.integerValue && self.fileSize?.integerValue == attachObject.fileSize?.integerValue)
        }
        else
        {
            return false
        }
    }
    
    override var hash:Int
        {
        return self.attachID!.hashValue ^ self.elementID!.hashValue
    }
}

class Country
{
    var countryId:NSNumber?
    var countryName:String?
    
    init(info:[String:AnyObject])
    {
        if info.count > 0
        {
            if let lvId = info["Id"] as? NSNumber
            {
                self.countryId = lvId
            }
            
            if let lvName = info["Name"] as? String
            {
                self.countryName = lvName
            }
        }
    }
}

class Language
{
    var languageId:NSNumber?
    var languageName:String?
    
    init(info:Dictionary<String,AnyObject>)
    {
        if info.count > 0
        {
            if let lvId = info["Id"] as? NSNumber
            {
                self.languageId = lvId
            }
            if let lvName = info["Name"] as? String
            {
                self.languageName = lvName
            }
        }
    }
    
    func toDictionary() -> Dictionary<String, AnyObject>
    {
        var dict = [String:AnyObject]()
        
        dict["Id"] = self.languageId
        dict["name"] = self.languageName
        
        return dict
    }
}

