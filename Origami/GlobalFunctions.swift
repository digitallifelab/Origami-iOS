//
//  GlobalFunctions.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation



func getBackgroundQueue_UTILITY() -> dispatch_queue_t
{
    if #available (iOS 8.0, *)
    {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }
    else
    {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    }
}

func getBackgroundQueue_DEFAULT() -> dispatch_queue_t
{
    if #available (iOS 8.0, *)
    {
        return dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    }
    else
    {
        return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }
}

func getBackgroundQueue_CONCURRENT() -> dispatch_queue_t
{
        return dispatch_queue_create("com.Origami.ConcurrentQueue", DISPATCH_QUEUE_CONCURRENT)
}