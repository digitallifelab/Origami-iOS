//
//  GlobalFunctions.swift
//  Origami
//
//  Created by CloudCraft on 22.10.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import Foundation


/**
    - Returns: global_queue with ptiority "`DISPATCH_QUEUE_PRIORITY_LOW`" or "`QOS_CLASS_UTILITY`"
*/
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

/**
 - Returns: global_queue with ptiority "Default"
 */
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

/**
 Creates background dispatch_queue with attribute "`DISPATCH_QUEUE_CONCURRENT`"
 */
func getBackgroundQueue_CONCURRENT() -> dispatch_queue_t
{
    return dispatch_queue_create("com.Origami.ConcurrentQueue", DISPATCH_QUEUE_CONCURRENT)
}

/**
 Creates background dispatch_queue with attribute "`DISPATCH_QUEUE_SERIAL`"
 */
func getBackgroundQueue_SERIAL() -> dispatch_queue_t
{
    return dispatch_queue_create("com.Origami.SerialBackgroundQueue", DISPATCH_QUEUE_SERIAL)
}