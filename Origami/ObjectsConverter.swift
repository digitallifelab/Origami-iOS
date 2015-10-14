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
        
    class func convertToAttaches(dictionaries:[[String:AnyObject]]) -> [AttachFile]? //somehow  xCode Instruments say there is a memory leak
    {
        if dictionaries.isEmpty
        {
            return nil
        }
        
        var attaches = [AttachFile]()
        for lvDict in dictionaries
        {
            if let lvAttachFile = AttachFile(info: lvDict)
            {
                attaches.append(lvAttachFile)
            }
        }
        //print("ObjectsConverter : Attaches: \(attaches.count)")
        
        if attaches.isEmpty{
            return nil
        }
        return attaches
    }
    
    class func convertSingleAttachInfoToAttach(info:[String:AnyObject]) -> AttachFile?
    {
        if info.isEmpty{
            return nil
        }
        return AttachFile(info: info)
    }
    
    class func sortAttachesByAttachId(inout attachesToSort:[AttachFile])
    {
        attachesToSort.sortInPlace { (attach1, attach2) -> Bool in
            
            return attach1.attachID < attach2.attachID
        }
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
            TypeId = 65535 - user was blocked
            TypeId = 65534 - user was unBlocked
            */
            //var shouldStoreMessage = true
            
            switch lvNewMessage.type
            {
                case .Undefined:
                    print("")
                    assert(false, "Undefined message detected. Please debug client-server communication")
                case .ChatMessage:
                    break//print(" - Chat message: \" \(lvNewMessage.textBody) \"")
                case .Invitation:
                    print(" - Service Message - invitation: \" \(lvNewMessage.textBody) \"")
                case .UserInfoUpdated:
                    print(" - service message - changed user info. \" \(lvNewMessage.textBody) \"")
                    //shouldStoreMessage = false
                case .UserPhotoUpdated:
                    print(" - Sevrice Message - changed user photo. \" \(lvNewMessage.textBody) \".")
                   // shouldStoreMessage = false
                case .UserBlocked:
                    print("\n-> User Was Blocked: userID = \(lvNewMessage.textBody!) \n")
                    //shouldStoreMessage = false
                case .UserUnblocked:
                    print("\n-> User Was UnBlosked: userID = \(lvNewMessage.textBody!) \n")
                    //shouldStoreMessage = false
    //            default:
    //                break
            }
            
            //if shouldStoreMessage{
                toReturn.append(lvNewMessage)
            //}
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
                else if let
                    date1 = element1.createDate.dateFromServerDateString(),
                    date2 = element2.createDate.dateFromServerDateString()
                {
                    let result = date1.compare(date2)
                    if result == NSComparisonResult.OrderedDescending
                    {
                        //print("\n date1: \(date1) is older than date2: \(date2) ")
                        return true
                    }
                    //print("date1: \(date1) is earlier than date2: \(date2) ")
                    return false
                }
                
                return false
            })
        }
    }
    
    class func sortElementsByElementId(inout elements:[Element])
    {
        if elements.count > 1
        {
            elements.sortInPlace({ (element1, element2) -> Bool in
                if let elementIdInt1 = element1.elementId?.integerValue, elementIdInt2 = element2.elementId?.integerValue
                {
                    return elementIdInt1 <= elementIdInt2
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
    
    class func sortMessagesByDate(inout messages:[Message],  _ sortingFunction:((Message, Message)->Bool))
    {
        if messages.count > 1
        {
            messages.sortInPlace { (message1, message2) -> Bool in  return sortingFunction(message1, message2) }
            print("\n -> sorting  Messages by date finished: ---->")
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