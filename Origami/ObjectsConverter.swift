//
//  ObjectsConverter.swift
//  Origami
//
//  Created by CloudCraft on 02.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class ObjectsConverter {
    
    class func convertToLanguages(dictionariesArray:[[String:AnyObject]]) -> [Language]?
    {
        var languages = [Language]()
        for aDict in dictionariesArray
        {
            if let aLang = Language(info: aDict)
            {
                languages.append(aLang)
            }
        }
        
        if languages.isEmpty
        {
            return nil
        }
        
        languages.sortInPlace { (lang1, lang2) -> Bool in
            return lang1.languageName < lang2.languageName
        }
        
        return languages
    }
    
    class func convertLanguagesToPlistArray(languages:[Language]) -> [AnyObject]?
    {
        var array = [[String:AnyObject]]()
        
        for aLanguage in languages
        {
            array.append(aLanguage.toDictionary())
        }
        
        if array.isEmpty
        {
            return nil
        }
        return array
    }
    
    class func convertToCountries(dictionariesArray:[[String:AnyObject]]) -> [Country]?
    {
        var countries = [Country]()
        for aDict in dictionariesArray
        {
            if let aCountry = Country(info: aDict)
            {
                countries.append(aCountry)
            }
        }
        
        if countries.isEmpty
        {
            return nil
        }
        
        countries.sortInPlace { (c1, c2) -> Bool in
            return c1.countryName < c2.countryName
        }
        return countries
    }
    
    class func convertCountriesToPlistArray(countries:[Country]) -> [AnyObject]?
    {
        var array = [[String:AnyObject]]()
        
        for aCountry in countries
        {
            array.append(aCountry.toDictionary())
        }
        
        if array.isEmpty
        {
            return nil
        }
        return array
    }
    
    
    class func converttoAttaches(dictionaries:[[String:AnyObject]]) -> [AttachFile]?
    {
        if dictionaries.isEmpty
        {
            return nil
        }
        var attaches = [AttachFile]()
        //let lvDicts = dictionaries
        for lvDict in dictionaries
        {
            let lvAttachFile = AttachFile(info: lvDict)
            attaches.append(lvAttachFile)
        }
        return attaches
    }
    
    class func convertToContacts(array:[[String:AnyObject]]) -> [Contact]
    {
        var contacts = [Contact]()
        for lvDict in array
        {
            var newDict = lvDict
            var avatarDataToSave:NSData?
            if let arrayOfInts = newDict.removeValueForKey("Photo") as? [Int], avatarData = NSData.dataFromIntegersArray(arrayOfInts)
            {
                avatarDataToSave = avatarData
            }
            
            if let contactAvatarData = avatarDataToSave
            {
                newDict["Photo"] = contactAvatarData
            }
            
            let contact = Contact(info: newDict)
            
            contacts.append(contact)
        }
        return contacts
    }
    
    class func convertToMessages(dictionaries:[[String:AnyObject]]) -> [Message]?
    {
        if dictionaries.isEmpty{
            return nil
        }
        
        var toReturn = [Message]()
        for lvDictionary in dictionaries
        {
            let lvNewMessage = Message(info: lvDictionary)
            //print(lvDictionary)
            if lvNewMessage.textBody == "User invited you!"
            {
                continue
            }
            
            /*
            12 - changed user info,
            13 - changed user photo
            */
            
            switch lvNewMessage.typeId
            {
            case 0:
                break//print(" - Chat message: \" \(lvNewMessage.textBody) \"")
            case 1:
                print(" - Service Message - invitation: \" \(lvNewMessage.textBody) \"")
            case 12:
                print(" - service message - changed user info. \" \(lvNewMessage.textBody) \"")
            case 13:
                print(" - Sevrice Message - changed user photo. \" \(lvNewMessage.textBody) \".")
            default:
                break
            }
            toReturn.append(lvNewMessage)
        }
        
        toReturn.sortInPlace { (message1, message2) -> Bool in
            return message1.elementId!.integerValue < message2.elementId!.integerValue
        }
        return toReturn
    }
    
    class func sortElementsByDate(inout elements:[Element])
    {
        if elements.count > 1
        {
            elements.sortInPlace({ (element1, element2) -> Bool in
                if let changed1 = element1.changeDate , changed2 =  element2.changeDate
                {
                    let  date1 = changed1.dateFromServerDateString()
                    let  date2 = changed2.dateFromServerDateString()
                    if date1 != nil && date2 != nil
                    {
                        let result = date1!.compare(date2!)
                        if result == NSComparisonResult.OrderedDescending
                        {
                            //print("\n date1: \(date1) is older than date2: \(date2) ")
                            return true
                        }
                        //print("date1: \(date1) is earlier than date2: \(date2) ")
                        return false
                        
                    }
                }
                else if let created1 = element1.createDate, created2 = element2.createDate
                {
                    let  date1 = created1.dateFromServerDateString()
                    let  date2 = created2.dateFromServerDateString()
                    if date1 != nil && date2 != nil
                    {
                        let result = date1!.compare(date2!)
                        if result == NSComparisonResult.OrderedDescending
                        {
                            //print("\n date1: \(date1) is older than date2: \(date2) ")
                            return true
                        }
                        //print("date1: \(date1) is earlier than date2: \(date2) ")
                        return false
                        
                    }
                }
                
                return false
            })
        }
    }
    
    class func filterArchiveElements(archive:Bool, elements:[Element]) -> [Element]
    {
        var newElements = [Element]()
        for anElement in elements
        {
            if archive
            {
                if anElement.isArchived()
                {
                    newElements.append(anElement)
                }
                continue
            }
            else
            {// non archive
                if anElement.isArchived()
                {
                    continue
                }
                newElements.append(anElement)
            }
        }
        
        return newElements
    }
    
    class func sortMessagesByDate(inout messages:[Message])
    {
        if messages.count > 1
        {
            messages.sortInPlace { (message1, message2) -> Bool in
                
                return (message1.compareToAnotherMessage(message2) == .OrderedAscending)
            }
            print("\n -> sorting  Messages by date finished: ---->")
//            for aMessage in messages
//            {
//                print(aMessage.elementId, aMessage.messageId, aMessage.dateCreated)
//            }
        }
    }
    
    
    class func sortMessagesByMessageId(messages:[Message]) -> [Message]
    {
        if messages.count > 1
        {
            return messages.sort({ (message1, message2) -> Bool in
                return message1.messageId < message2.messageId
            })
        }
        return messages
    }
    
}