//
//  Contact.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Contact:Person, Hashable
{
    var lastSync:String?
    var contactId:Int = 0
    
    var isFavourite:NSNumber = NSNumber(bool: false)
    var elementId:Int?
    var isOnline:NSNumber?
    
    convenience init(info:Dictionary<String, AnyObject>)
    {
        self.init()
        
        if let name = info["FirstName"] as? String
        {
            let fixedName = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            self.firstName = fixedName
        }
        if let last = info["LastName"] as? String
        {
            let fixedSurname = last.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            self.lastName = fixedSurname
        }
        if let uName = info["LoginName"] as? String
        {
            let fixedUserName = uName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            self.userName = fixedUserName
        }
        if let element = info["ElementId"] as? Int
        {
            self.elementId = element
        }
        if let lvContactId = info["ContactId"] as? Int
        {
            self.contactId = lvContactId
        }
        if let fav = info["IsFavorite"] as? NSNumber
        {
            self.isFavourite = fav
        }
        
        if let lvState = info["State"] as? Int, contactState = PersonAuthorisationState(rawValue: lvState)
        {
            self.state = contactState
        }
        if let reg = info["RegDate"] as? String
        {
            self.regDate = reg.timeDateStringFromServerDateString()
        }
        if let birth = info["BirthDate"] as? String
        {
            self.birthDay = birth.timeDateStringFromServerDateString()
        }
        if let sync = info["LastSync"] as? String
        {
            self.lastSync = sync.timeDateStringFromServerDateString()
        }
        if let lvSex = info["Sex"] as? NSNumber
        {
            self.sex = lvSex
        }
        if let lvMood = info["Mood"] as? String
        {
            self.mood = lvMood
        }
        if let tel = info["PhoneNUmber"] as? String
        {
            self.phone = tel
        }
        if let lvCountry = info["Country"] as? String
        {
            self.country = lvCountry
        }
        if let lvCountryId = info["CountryId"] as? Int
        {
            self.countryId = lvCountryId
        }
        if let lvLanguage = info["Language"] as? String
        {
            self.language = lvLanguage
        }
        if let lvLangId = info["LanguageId"] as? Int
        {
            self.languageId = lvLangId
        }
        if let photoData = info["Photo"] as? NSData
        {
            self.photo = photoData
        }
    }
    
    func toDictionary() -> [NSObject:AnyObject]
    {
        var toReturn = [NSObject:AnyObject]()
        
        toReturn["LoginName"]   = self.userName //?? NSNull()
        
        toReturn["FirstName"]   = self.firstName //?? NSNull()
        toReturn["LastName"]    = self.lastName // ?? NSNull()
        toReturn["ContactId"]   = self.contactId
        
        toReturn["Mood"]        = self.mood //?? NSNull()
        toReturn["State"]       = self.state.rawValue //?? NSNull()
        toReturn["Sex"]         = self.sex  //?? NSNull()
        if let phoneNumber = self.phone
        {
            toReturn["PhoneNumber"] = phoneNumber
        }
        if let birthDate = self.birthDay
        {
            toReturn["BirthDay"]  = birthDate
        }
      
        if let regDate = self.regDate
        {
            toReturn["RegDate"] = regDate
        }

        toReturn["LastSync"]    = self.lastSync// ?? NSNull()
        
        toReturn["Country"]     = self.country
        toReturn["CountryId"]   = self.countryId
        toReturn["Language"]    = self.language
        toReturn["LanguageId"]  = self.languageId
        
        toReturn["IsFavorite"] = self.isFavourite
        toReturn["isOnline"]    = self.isOnline
        
        
        return toReturn
    }
    
    func birthdayString() -> String?
    {
        if let birhday = self.birthDay
        {
            if let date = birhday.dateFromServerDateString()
            {
                if let birthDateString = date.dateStringMediumStyle()
                {
                    return birthDateString
                }
            }
        }
        return nil
    }

    var hashValue:Int
    {
        return self.userName.hashValue ^ self.contactId.hashValue
    }
    
}

func == (lhs:Contact,rhs:Contact) -> Bool {
    
    return lhs.contactId == rhs.contactId
}
