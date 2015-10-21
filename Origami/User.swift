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
    var password:String? //
    var lastSync:String? //
    var token:String? //
    var userId:Int? //
    
    
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
            if let password = info["Password"] as? String
            {
                self.password = password
            }
            if let userId = info["UserId"] as? Int
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
            if let lvRegDate = info["RegDate"] as? String
            {
                self.regDate = lvRegDate
            }
            if let lvSync = info["LastSync"] as? String
            {
                self.lastSync = lvSync
            }
            if let lvBirthDay = info["BirthDay"] as? String
            {
                self.birthDay = lvBirthDay
            }
            if let lvTel = info["PhoneNumber"] as? String
            {
                self.phone = lvTel
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
        if let password = info["Password"] as? String
        {
            self.password = password
        }
        if let userId = info["UserId"] as? Int
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
        if let lvRegDate = info["RegDate"] as? String
        {
            self.regDate = lvRegDate
        }
        if let lvSync = info["LastSync"] as? String
        {
            self.lastSync = lvSync
        }
        if let lvBirthDay = info["BirthDay"] as? String
        {
            if lvBirthDay == "/Date(0+0000)/"{
                self.birthDay = kWrongEmptyDate
            }
            else{
                self.birthDay = lvBirthDay
            }
        }
        if let lvTel = info["PhoneNumber"] as? String
        {
            self.phone = lvTel
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
        
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        var toReturn = [String:AnyObject]()
        toReturn["LoginName"]   = self.userName
        toReturn["Password"]    = self.password
        toReturn["State"]       = self.state.rawValue
        toReturn["UserId"]      = self.userId
        
        if let regDate = self.regDate
        {
            toReturn["RegDate"] = regDate
        }
        if let syncDate = self.lastSync
        {
            toReturn["LastSync"]  = syncDate
        }
        
        if let fName = self.firstName
        {
            toReturn["FirstName"] = fName
        }
        
        if let lName = self.lastName
        {
            toReturn["LastName"] = lName
        }
        
        if let token = self.token
        {
            toReturn["Token"] = token
        }
        
        if let mood = self.mood
        {
            toReturn["Mood"]  = mood
        }
       
        if let sex = self.sex
        {
            toReturn["Sex"] = sex
        }
        
        if let phoneNumber = self.phone
        {
            toReturn["PhoneNumber"] = phoneNumber
        }
        
        if let stringBDay = self.birthDay
        {
            toReturn["BirthDay"] = stringBDay
        }
        
        if let aCountry = self.country
        {
            toReturn["Country"] = aCountry
        }

        if let cId = self.countryId
        {
            toReturn["CountryId"]  = cId
        }
        
        if let lang = self.language
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
