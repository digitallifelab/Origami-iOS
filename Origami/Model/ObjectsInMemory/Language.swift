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
    var languageId:Int = 0
    var languageName:String = ""
    
    convenience init?(info:[String:AnyObject]?)
    {
        self.init()
        if info == nil
        {
            return nil
        }
        
        if info!.count > 0
        {
            if let lvId = info!["Id"] as? Int
            {
                self.languageId = lvId
            }
            if let lvName = info!["Name"] as? String
            {
                self.languageName = lvName
            }
        }
        else
        {
            return nil
        }
    }
    
    func toDictionary() -> Dictionary<String, AnyObject>
    {
        var dict = [String:AnyObject]()
        
        dict["Id"] = self.languageId
        dict["Name"] = self.languageName
        
        return dict
    }
}