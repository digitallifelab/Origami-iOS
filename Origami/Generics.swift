//
//  Generics.swift
//  Origami
//
//  Created by CloudCraft on 14.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation
/**
A Generic function that compares two objects by dateCreated property
Copmares to dates of messages
returns true if left message`s date is greater than right message`s date
*/
func > <T where T:CreateDateComparable> (lhs:T, rhs:T) -> Bool
{
    if lhs.dateCreated != nil  && rhs.dateCreated != nil
    {
        if lhs.dateCreated!.compare(rhs.dateCreated!) == .OrderedDescending
        {
            //print("\(lhs.dateCreated!) > \(rhs.dateCreated!)")
            return true
        }
        return false
    }
    else if lhs.dateCreated != nil && rhs.dateCreated == nil
    {
        return true
    }
    else if rhs.dateCreated != nil && lhs.dateCreated == nil
    {
        return false
    }
    else
    {
        return false
    }
}

/**
A Generic function that compares two objects by *dateCreated* property
if *dateCreated* is nil in left or right object or in both objects - objects are still compared.
*/
func < <T where T:CreateDateComparable> (lhs:T, rhs:T) -> Bool
{
    if lhs.dateCreated != nil  && rhs.dateCreated != nil
    {
        if lhs.dateCreated!.compare(rhs.dateCreated!) == .OrderedAscending
        {
            //print("\(lhs.dateCreated!) < \(rhs.dateCreated!)")
            return true
        }
        return false
    }
    else if lhs.dateCreated != nil && rhs.dateCreated == nil
    {
        return false
    }
    else if rhs.dateCreated != nil && lhs.dateCreated == nil
    {
        return true
    }
    else
    {
        return false
    }
}