//
//  ObjectsConverter.swift
//  Origami
//
//  Created by CloudCraft on 02.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class ObjectsConverter {
    
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