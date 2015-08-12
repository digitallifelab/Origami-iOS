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
    var countryId:NSNumber?
    var countryName:String?
    
    init(info:[String:AnyObject])
    {
        if info.count > 0
        {
            if let lvId = info["Id"] as? NSNumber
            {
                self.countryId = lvId
            }
            
            if let lvName = info["Name"] as? String
            {
                self.countryName = lvName
            }
        }
    }
}