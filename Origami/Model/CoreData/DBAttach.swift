//
//  DBAttach.swift
//  Origami
//
//  Created by CloudCraft on 29.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
import CoreData


class DBAttach: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    func fillInfoFromInMemoryAttach(attach:AttachFile)
    {
        /*
        var attachID:Int = 0
        var elementID:Int = 0
        var creatorID:Int = 0
        var fileSize:Int = 0
        var fileName:String?
        var createDate:String?
        */
        
        self.attachId = NSNumber(integer: attach.attachID)
        self.fileSize = NSNumber(integer: attach.fileSize)
        if let fileName = attach.fileName
        {
            self.fileName = fileName
        }
        self.creatorId = NSNumber(integer: attach.creatorID)
        self.dateCreated = attach.createDate?.dateFromServerDateString()
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if let name = self.fileName
        {
            let filer = FileHandler()
            filer.eraseFileNamed(name, completion: nil)
        }
    }
}
