//
//  Person.swift
//  Origami
//
//  Created by CloudCraft on 07.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
class Person //: NSObject
{
    var firstName:String?
    var lastName:String?
    var userName:String = ""
    var mood:String?
    var birthDay:String?
    var phone:String?
    var country:String? //
    var countryId:Int? //
    var language:String? //
    var languageId:Int? //
    var photo:NSData?
    var sex:NSNumber? //
    var regDate:String? //
    var state:PersonAuthorisationState = .Undefined
    
    func nameAndLastNameSpacedString() -> String?
    {
        var nameString = ""
        if let firstName = self.firstName
        {
            nameString += firstName
        }
        if let lastName = self.lastName
        {
            if nameString.isEmpty
            {
                nameString = lastName
            }
            else
            {
                nameString += (" " + lastName)
            }
        }
        
        if nameString.isEmpty
        {
            return nil
        }
        return nameString
    }
    
    func initialsString() -> String?
    {
        if let fullnameString = self.nameAndLastNameSpacedString()
        {
            var stringToReturn = ""
            let array = fullnameString.componentsSeparatedByString(" ")
            for aString in array
            {
                if let firstCharacter = aString.characters.first
                {
                    stringToReturn.append(firstCharacter)
                    stringToReturn += ". "
                }
            }
            if !stringToReturn.isEmpty
            {
                return stringToReturn
            }
        }
        return nil
    }
}