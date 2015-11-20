//
//  MessagesLoader.swift
//  Origami
//
//  Created by CloudCraft on 18.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class MessagesLoader
{
    private var refrequestInterval:Double = Double(kMessagesRefreshIntervalIdle)
    
    var dispatchSource:dispatch_source_t?
    
    init() {
        print("\n... MessagesLoader initialized ...")
    }
    
    /**
     - Returns: Current refresh interval in seconds
    */
    func currentRefreshInterval() -> Int
    {
        return Int(self.refrequestInterval)
    }
    /**
     Sets refreshInterval in seconds between 0 (zero) and 60 seconds
     - Note: if value more than 60 seconds is passed, timeout sets to be 60 seconds, if value less than zero passed, timeout is set to zero and no refresh will be started in next time timer fires.
     */
    func setRefreshInterval(interval:Int)
    {
        self.refrequestInterval = Double(max(min(60, interval),0))
        self.setTimerWithInterval(self.refrequestInterval)
    }
    
    func startRefreshingLastMessages()
    {
        // Create a dispatch source that'll act as a timer on the concurrent queue
        // You'll need to store this somewhere so you can suspend and remove it later on
 
        if  self.dispatchSource == nil
        {
            self.createDispatch_source()
        }
   
        if let source = self.dispatchSource
        {
            dispatch_source_set_cancel_handler(source) {[weak self] in
                print(" -> MessagesLoader -> cancellation handler called...")
                
                if let weakSelf = self
                {
                    weakSelf.dispatchSource = nil
                    print("\n deleted dispatch source by cancel_handler...")
                }
            }
            
            
            // Attach the block you want to run on the timer fire
            dispatch_source_set_event_handler(source) {[weak self] in
                if let weakSelf = self
                {
                    print(" -> Fired a timer for messages.")
                    if let source = weakSelf.dispatchSource
                    {
                        dispatch_suspend(source)
                    }
                    
                    DataSource.sharedInstance.loadLastMessages() {[weak self] (success, error) -> () in
                        
                        if let anError = error
                        {
                            print("\n -> MessagesLoader. Error loading last messages:\n\(anError)\n")
                            if anError.code == -55 //(no user token error because token has expired and thus deleted locally)
                            {
                                DataSource.sharedInstance.user = nil
                                DataSource.sharedInstance.performLogout(nil)
                                if let rootVC = UIApplication.sharedApplication().windows.first!.rootViewController as? RootViewController
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        rootVC.showLoginScreenWithReloginPrompt(true)
                                    })
                                    return
                                }
                            }
                        }
                        if let weakerSelf = self
                        {
                            if let source = weakerSelf.dispatchSource
                            {
                                dispatch_resume(source)
                                
                            }
                        }
                    }
                }
            }
            
            
            // Start the timer
            guard let source = self.dispatchSource else
            {
                print("ERROR -> No dispatch source timer found for MessagesLoader.  Will not start refreshing messages.")
                return
            }
            
            //dispatch_suspend(source)
            
            self.setTimerWithInterval(self.refrequestInterval)
            
            dispatch_resume(source)
        }
    }
    
    func createDispatch_source()
    {
        guard refrequestInterval > 0 else
        {
            print(" - MessagesLoader: refreshIntegrval = \(refrequestInterval)")
            print(" - Will not start refreshing messages.")
            stopRefreshingLastMessages()
            return
        }
        
        
        let globalQueue = getBackgroundQueue_UTILITY()
        
        self.dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue)
        
    }
    
    private func setTimerWithInterval(interval:Double)
    {
        guard let dispatchSource = self.dispatchSource else
        {
            print("\n - MessagesLoader setTimerWithInterval .  ERROR: No dispatchSource in SELF.\n")
            return
        }
        
        guard refrequestInterval > 0 else
        {
            stopRefreshingLastMessages()
            return
        }
        // Setup params for creation of a recurring timer
        let intervalTime = UInt64(refrequestInterval * Double(NSEC_PER_SEC))
        let startTime = dispatch_time(DISPATCH_TIME_NOW, 0)
        
        dispatch_source_set_timer(dispatchSource, startTime, intervalTime, 0)
    }
    
    func stopRefreshingLastMessages()
    {
        if let source = self.dispatchSource
        {
            //dispatch_suspend(source)
            dispatch_source_cancel(source)
        }
    }
    
    
}// class end