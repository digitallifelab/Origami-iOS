//
//  AttachFile.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class AttachFile :NSObject
{
    var attachID:NSNumber?
    var elementID:NSNumber?
    var creatorID:NSNumber?
    var fileSize:NSNumber?
    var fileName:String?
    var createDate:String?
    
    convenience init(info:[String:AnyObject])
    {
        self.init()
        
        if info.count > 0
        {
            if let lvCreator = info["CreatorId"] as? NSNumber
            {
                self.creatorID = lvCreator
            }
            
            if let lvID = info["Id"] as? NSNumber
            {
                self.attachID = lvID
            }
            
            if let lvElementId = info["ElementId"] as? NSNumber
            {
                self.elementID = lvElementId
            }
            
            if let lvFileSize = info["Size"] as? NSNumber
            {
                self.fileSize = lvFileSize
            }
            
            if let lvName = info["FileName"] as? NSString
            {
                self.fileName = lvName.stringByReplacingOccurrencesOfString("/", withString: "-")
            }
            
            if let lvDate = info["CreateDate"] as? String
            {
                self.createDate = lvDate
            }
        }
    }
    
    override func isEqual(object:AnyObject?) -> Bool
    {
        if let attachObject  = object as? AttachFile
        {
            return (self.attachID?.integerValue == attachObject.attachID?.integerValue && self.elementID?.integerValue == attachObject.elementID?.integerValue && self.fileSize?.integerValue == attachObject.fileSize?.integerValue)
        }
        else
        {
            return false
        }
    }
    
    override var hash:Int
        {
            return self.attachID!.hashValue ^ self.elementID!.hashValue
    }
}
