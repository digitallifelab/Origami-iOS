//
//  MessagesLoader.swift
//  Origami
//
//  Created by CloudCraft on 18.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class MessagesLoader:NSObject
{
  
    var dispatchSource:dispatch_source_t?
    
    override init() {
        super.init()
        print("... MessagesLoader initialized ...")
    }
    
    deinit
    {
        //print("... MessagesLoader deinit ...")
    }
    
    func startRefreshingLastMessages()
    {
        // Create a dispatch source that'll act as a timer on the concurrent queue
        // You'll need to store this somewhere so you can suspend and remove it later on
 
        if let source = self.dispatchSource
        {
            
        }
        else
        {
            self.createDispatch_source()
        }
   
        if let source = self.dispatchSource
        {
            // Attach the block you want to run on the timer fire
            dispatch_source_set_event_handler(source, {[weak self] () -> Void in
                if let weakSelf = self
                {
                    print("Fired a timer.")
                    if let source = weakSelf.dispatchSource
                    {
                        dispatch_suspend(source)
                    }
                    DataSource.sharedInstance.loadLastMessages({[weak self] (success, error) -> () in
                        
                        if let anError = error
                        {
                            print("Error loading last messages:")
                        }
                        if let weakerSelf = self
                        {
                            if let source = weakerSelf.dispatchSource
                            {
                                dispatch_resume(source)
                            }
                        }
                    })
                }
            })
            
            dispatch_source_set_cancel_handler(source, {[weak self] () -> Void in
                print(" -> MessagesLoader -> cancellation handler called...")
                
                //typically this is never executed, because of cancelDispatchSource() call->
                if let weakSelf = self
                {
                    weakSelf.dispatchSource = nil
                    print("deleted dispatch source by cancel_handler...")
                }
            })
            // Start the timer
            dispatch_resume(dispatchSource!)
        }
    }
    
    func createDispatch_source()
    {
         let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
        
            self.dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue)
                // Setup params for creation of a recurring timer
            let interval:Double = 5.0
            let intervalTime = UInt64(interval * Double(NSEC_PER_SEC))
            let startTime = dispatch_time(DISPATCH_TIME_NOW, 0)
        
        dispatch_source_set_timer(dispatchSource!, startTime, intervalTime, 0)
    }
    
    func stopRefreshingLastMessages()
    {
        if let source = self.dispatchSource
        {
            //dispatch_suspend(source)
            dispatch_source_cancel(source)
        }
    }
    func cancelDispatchSource()
    {
        if let source = self.dispatchSource
        {
           self.dispatchSource = nil
            print(" -> MessagesLoader -> removed dispatch source...")
        }
    }
}