//
//  User.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
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
            if let userName = info["LoginName"] as? NSString
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
    
    func toDictionary() -> [NSObject:AnyObject]
    {
        var toReturn = [NSObject:AnyObject]()
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
