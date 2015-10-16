//
//  User.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class User:Person
{
    var birthDay:NSString? //
    var phone:NSString? //
    var country:NSString? //
    var countryId:NSNumber? //
    var language:NSString? //
    var languageId:NSNumber? //
 
    var sex:NSNumber? //
    var regDate:NSString? //
    var photo:NSData? //
    var password:NSString? //
    var lastSync:NSString? //
    var token:String? //
    var userId:NSNumber? //
    
    
    convenience init(info:[String:AnyObject])
    {
        self.init()
        
        if info.count > 0
        {
            if let userName = info["LoginName"] as? String
            {
                self.userName = userName
            }
            if let lastName = info["LastName"] as? String
            {
                self.lastName = lastName
            }
            if let firstName = info["FirstName"] as? String
            {
                self.firstName = firstName
            }
            if let token = info["Token"] as? String
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
            if let mood = info["Mood"] as? String
            {
                self.mood = mood
            }
            if let lvSex = info["Sex"] as? NSNumber
            {
                self.sex = lvSex
            }
            if let state = info["State"] as? Int, userState = PersonAuthorisationState(rawValue: state)
            {
                self.state = userState
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
    
    func setInfo(info:[String:AnyObject]) throws
    {
        if info.isEmpty{
            throw InternalDiagnosticError.EmptyValuePassed(value: info)
        }
        
        if let userName = info["LoginName"] as? String
        {
            self.userName = userName
        }
        if let lastName = info["LastName"] as? String
        {
            self.lastName = lastName
        }
        if let firstName = info["FirstName"] as? String
        {
            self.firstName = firstName
        }
        if let token = info["Token"] as? String
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
        if let mood = info["Mood"] as? String
        {
            self.mood = mood
        }
        if let lvSex = info["Sex"] as? NSNumber
        {
            self.sex = lvSex
        }
        if let state = info["State"] as? Int, userState = PersonAuthorisationState(rawValue: state)
        {
            self.state = userState
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
    
    func toDictionary() -> [String:AnyObject]
    {
        var toReturn = [String:AnyObject]()
        toReturn["LoginName"]   = self.userName
        toReturn["Password"]    = self.password
        if let regDate = self.regDate as? String
        {
            toReturn["RegDate"] = regDate
        }
        if let syncDate = self.lastSync as? String
        {
            toReturn["LastSync"]  = syncDate
        }
        
        if let fName = self.firstName// as? String
        {
            toReturn["FirstName"] = fName
        }
        
        if let lName = self.lastName// as? String
        {
            toReturn["LastName"] = lName
        }
        
        if let token = self.token //as? String
        {
            toReturn["Token"] = token
        }
        toReturn["UserId"] = self.userId //?? NSNull()
        
        if let mood = self.mood
        {
            toReturn["Mood"]  = mood //?? NSNull()
        }
        //if let state = self.state
        //{
            toReturn["State"] = self.state.rawValue// state //?? NSNull()
        //}
        
        if let sex = self.sex
        {
            toReturn["Sex"] = sex  //?? NSNull()
        }
        
        if let phoneNumber = self.phone as? String
        {
            toReturn["PhoneNumber"] = phoneNumber
        }
        
        if let stringBDay = self.birthDay as? String
        {
            toReturn["BirthDay"] = stringBDay
        }
        
        if let aCountry = self.country as? String
        {
            toReturn["Country"] = aCountry
        }

        if let cId = self.countryId //as? NSNumber
        {
            toReturn["CountryId"]  = cId
        }
        
        if let lang = self.language as? String
        {
            toReturn["Language"] = lang
        }
        
        if let langId = self.languageId
        {
            toReturn["LanguageId"] = langId
        }
        
        
        // photo we neither store in User object nor Send it to server as paramater of User
        
        
        return toReturn
    }
    
    func localizedSexString() -> String
    {
        if let sexNumber = self.sex
        {
            if sexNumber.integerValue == 0
            {
                return "male".localizedWithComment("")
            }
            if sexNumber.integerValue == 1
            {
                return "female".localizedWithComment("")
            }
        }
        return ""
    }
}
