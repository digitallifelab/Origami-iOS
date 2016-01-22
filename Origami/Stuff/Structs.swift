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

struct TypeAliasMessagesTuple {
    let messagesTuple:(chat:[Message], service:[Message])
}

struct ElementDetailsStruct
{
    var title:String
    var details:String?
    var messagesPreviewCell:Bool = false
    //var buttonsCell:Bool = false
    var attachesCell:Bool = false
    var subordinates:[ElementItemLayoutWidth]?
    
    var hiddenDetailsText = true {
        didSet{
            print(" - > elementStruct details visibility toggled! -- Visible = \(self.hiddenDetailsText)")
        }
    }
    
    mutating func toggleDetailsHidden()
    {
        self.hiddenDetailsText = !self.hiddenDetailsText
    }
    
    init(title:String, details:String?, messagesCell:Bool?, /*buttonsCell:Bool?,*/ attachesCell:Bool?, subordinateItems:[ElementItemLayoutWidth]?)
    {
        self.title = title
        self.details = details
        if messagesCell != nil
        {
            self.messagesPreviewCell = messagesCell!
        }
        
        if attachesCell != nil
        {
            self.attachesCell = attachesCell!
        }
        if subordinateItems != nil
        {
            if !subordinateItems!.isEmpty
            {
                self.subordinates = subordinateItems
            }
        }
        
        // print(" -> \n SimpleElementDashboardLayout  struct description:\n title: \"\(self.title)\",\n details :\" \(self.details) \",\n messagesContained: \(self.messagesPreviewCell), \n attaches: \(self.attachesCell),\n subordinates:  \(self.subordinates) <- \n")
    }
    
    func numberOfSections() -> Int
    {
        var sections = 1 // ("title /or/ dates" cell)
        if messagesPreviewCell
        {
            sections += 1
        }
        if let _ = self.details
        {
            sections += 1
        }
        if attachesCell
        {
            sections += 1
        }
        if let subitems = self.subordinates
        {
            if subitems.count > 0
            {
                sections += 1
            }
        }
        
        return sections
    }
}

struct DateDetailsStruct
{
    var dateCreated:NSDate?
    var dateChanged:NSDate?
    var dateArchived:NSDate?
    var dateFinished:NSDate?
    
    var responsibleName:String?
    var creatorName:String?
    var owned:Bool = false
}

struct ChatMessagePreviewStruct {
    var authorName:String?
    var messageBody:String = ""
    var messageDate:String = ""
    var authorAvatar:UIImage? = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
    
    init(name:String?, text:String?, date:String?, avatarPreview:UIImage?)
    {
        if let shortName = name{
            self.authorName = shortName
        }
        if let aMessageBody = text{
            self.messageBody = aMessageBody
        }
        if let aDateString = date
        {
            self.messageDate = aDateString
        }
        if let anImage = avatarPreview
        {
            self.authorAvatar = anImage
        }
    }
}

struct HomeLayoutStruct {
    
    var signals:[ElementItemLayoutWidth] = [ElementItemLayoutWidth.Normal]
    var favourites:[ElementItemLayoutWidth]?
    var other:[ElementItemLayoutWidth]?
    
    init(signalsCount:Int, favourites:[ElementItemLayoutWidth], other:[ElementItemLayoutWidth])
    {
        if signalsCount > 1
        {
            for var i = 1; i < signalsCount; i++
            {
                self.signals.append(ElementItemLayoutWidth.Normal)
            }
        }
        self.favourites = favourites
        self.other = other
    }
    
    mutating func setNewFavourites(favs:[ElementItemLayoutWidth])
    {
        self.favourites = favs.isEmpty ? nil : favs
    }
    
    mutating func setNewOther(newValue:[ElementItemLayoutWidth])
    {
        self.other = newValue.isEmpty ? nil : newValue
    }
}

