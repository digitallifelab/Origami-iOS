//
//  Country.swift
//  Origami
//
//  Created by CloudCraft on 12.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
class Country
{
    var countryId:NSNumber = NSNumber(integer: 0)
    var countryName:String = ""
    
    convenience init?(info:[String:AnyObject]?)
    {
        self.init()
        
        if info == nil
        {
            return nil
        }
        if info!.isEmpty
        {
            return nil
        }
        
        if info!.count > 0
        {
            if let lvId = info!["Id"] as? NSNumber
            {
                self.countryId = lvId
            }
            
            if let lvName = info!["Name"] as? String
            {
                self.countryName = lvName
            }
        }
    }
    
    func toDictionary() -> [String:AnyObject]
    {
        return ["Id":countryId, "Name":countryName]
    }
}
