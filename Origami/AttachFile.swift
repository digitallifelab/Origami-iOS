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
    var attachID:Int = 0
    var elementID:Int = 0
    var creatorID:Int = 0
    var fileSize:Int = 0
    var fileName:String?
    var createDate:String?
    
    convenience init(info:[String:AnyObject])
    {
        self.init()
        
        if info.count > 0
        {
            if let lvCreator = info["CreatorId"] as? Int
            {
                self.creatorID = lvCreator
            }
            
            if let lvID = info["Id"] as? Int
            {
                self.attachID = lvID
            }
            
            if let lvElementId = info["ElementId"] as? Int
            {
                self.elementID = lvElementId
            }
            
            if let lvFileSize = info["Size"] as? Int
            {
                self.fileSize = lvFileSize
            }
            
            if let lvName = info["FileName"] as? String
            {
                self.fileName = lvName
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
            return (self.attachID == attachObject.attachID && self.fileSize == attachObject.fileSize)
        }
        
        return false
    }
    
    override var hash:Int {
        
            return self.attachID.hashValue ^ self.elementID.hashValue
    }
}
