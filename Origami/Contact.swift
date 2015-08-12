//
//  Contact.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
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
    var contactId:NSNumber?
    
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
        if let lvContactId = info["ContactId"] as? NSNumber
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
