//
//  DBContact.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class DBContact: DBPerson {

// Insert code here to add functionality to your managed object subclass

    func fillInfoFromContact(contact:Contact)
    {
        self.contactId = NSNumber(integer: contact.contactId)
        
        if self.firstName != contact.firstName
        {
            self.firstName = contact.firstName
            print("Did set new contact First Name: \(self.firstName!)")
        }
        
        if self.lastName != contact.lastName
        {
            self.lastName = contact.lastName
            print("Did set new contact Last Name: \(self.lastName!)")
        }
        
        if self.userName != contact.userName
        {
            self.userName = contact.userName
            print("Did set new contact UserName: \(self.userName!)")
        }
        
        if self.mood != contact.mood
        {
            self.mood = contact.mood
            print("Did set new contact mood")
        }
        
        if self.favorite?.boolValue != contact.isFavourite.boolValue
        {
            self.favorite = contact.isFavourite
            print("Did set new contact Favourite")
        }
        
        if self.sex?.integerValue != contact.sex!.integerValue
        {
            self.sex = contact.sex
            //print("Did set new contact Sex value")
        }
        
        if self.birthDay != contact.birthDay?.dateFromServerDateString()
        {
            self.birthDay = contact.birthDay?.dateFromServerDateString()
            //print("Did set new contact birth day")
        }
        
        if let countryIdSelf = self.country?.integerValue, countryId = contact.countryId
        {
            if countryIdSelf != countryId
            {
                self.country = NSNumber(integer:countryId)
                print("Did set new contact Country Id")
            }
        }
        else if let countryId = contact.countryId
        {
            self.country = NSNumber(integer:countryId)
            print("Did set new contact Country Id")
        }
        
        
        if let langIdSelf = self.language?.integerValue, let langId = contact.languageId
        {
            if langIdSelf != langId
            {
                self.language = NSNumber(integer:langId)
                print("Did set new contact Country Id")
            }
        }
        else if let langId = contact.languageId
        {
            self.language = NSNumber(integer:langId)
            print("Did set new contact Country Id")
        }
        
    }
}
