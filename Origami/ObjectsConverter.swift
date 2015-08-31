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
        
        return languages
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
        
        countries.sort { (c1, c2) -> Bool in
            return c1.countryName > c2.countryName
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
            let attach = AttachFile(info: lvDict)
            attaches.append(attach)
        }
        return attaches
    }
    
    class func convertToContacts(array:[[String:AnyObject]]) -> [Contact]
    {
        var contacts = [Contact]()
        for lvDict in array
        {
            let contact = Contact(info: lvDict)
            
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
            //println(lvDictionary)
            if lvNewMessage.textBody == "User invited you!"
            {
                continue
            }
            toReturn.append(lvNewMessage)
        }
        
        toReturn.sort { (message1, message2) -> Bool in
            return message1.elementId!.integerValue < message2.elementId!.integerValue
        }
        return toReturn
    }
    
    class func sortElementsByDate(inout elements:[Element])
    {
        if elements.count > 1
        {
            elements.sort({ (element1, element2) -> Bool in
                if element1.changeDate != nil && element2.changeDate != nil
                {
                    
                    let  date1 = element1.createDate!.dateFromServerDateString()
                    let  date2 = element2.createDate!.dateFromServerDateString()
                    if date1 != nil && date2 != nil
                    {
                        let result = date1!.compare(date2!)
                        if result == NSComparisonResult.OrderedDescending
                        {
                            return true
                        }
                        return false
                        
                    }
                }
                return false
            })
        }
    }
    
    class func sortMessagesByDate(inout messages:[Message])
    {
        if messages.count > 1
        {
            messages.sort { (message1, message2) -> Bool in
                
                return (message1.compareToAnotherMessage(message2) == .OrderedAscending)
            }
        }
    }
    
}