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
    var creatorId:Int = 0
    
    init?(type:FileType, fileData:NSData?, fileName:String?, creator:Int?)
    {
        if fileData == nil || fileName == nil || creator == nil
        {
            return nil
        }
        
        self.type = type
        self.data = fileData!
        self.name = fileName!
        self.creatorId = creator!
    }
}



struct ElementCellsOptions
{
    var cellTypes:Set<ElementCellType>
    
    init()
    {
        self.cellTypes = Set([.Title])//, .Buttons]) //default value
    }
    
    init(types:Set<ElementCellType>)
    {
        self.cellTypes = types
    }
    
    mutating func setTypes(types:Set<ElementCellType>)
    {
        self.cellTypes = types
    }
    
    mutating func addOptions(types:Set<ElementCellType>)
    {
        self.cellTypes.unionInPlace(types)
    }
    
    var countOptions:Int {
        return self.cellTypes.count
    }
    
    var orderedOptions:[ElementCellType] {
        
        var options = Array(cellTypes)
        options.sortInPlace { (option1, option2) -> Bool in
            return option1.rawValue < option2.rawValue
        }
        return options
    }
}