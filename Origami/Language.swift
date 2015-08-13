//
//  Language.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Language
{
    var languageId:NSNumber?
    var languageName:String?
    
    init(info:Dictionary<String,AnyObject>)
    {
        if info.count > 0
        {
            if let lvId = info["Id"] as? NSNumber
            {
                self.languageId = lvId
            }
            if let lvName = info["Name"] as? String
            {
                self.languageName = lvName
            }
        }
    }
    
    func toDictionary() -> Dictionary<String, AnyObject>
    {
        var dict = [String:AnyObject]()
        
        dict["Id"] = self.languageId
        dict["name"] = self.languageName
        
        return dict
    }
}