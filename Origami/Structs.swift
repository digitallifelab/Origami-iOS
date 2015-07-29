//
//  Structs.swift
//  Origami
//
//  Created by CloudCraft on 29.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

struct AttachToDisplay {
    
    var type:FileType
    var data:NSData
    var name:String
    
    init?(type:FileType, fileData:NSData?, fileName:String?)
    {
        if fileData == nil || fileName == nil
        {
            return nil
        }
        
        self.type = type
        self.data = fileData!
        self.name = fileName!
    }
}