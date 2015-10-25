//
//  DBPerson.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData

class DBPerson: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

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
