//
//  DataRefresher.swift
//  Origami
//
//  Created by CloudCraft on 04.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

class DataRefresher
{
    private var loadedElements:[Element]?
    private var serverRequester = ServerRequester()
    private var refreshInterval:NSTimeInterval = 0.0
    
    private var cancelled = false
    var isInProgress = false
    
    init() {
        print("DataRefresher Initialized.")
    }
    
    deinit{
        print("DataRefresher DeInitialized.")
    }
    
    var isCancelled:Bool {
        return self.cancelled
    }
    
    func startRefreshingElementsWithTimeoutInterval(timeout:NSTimeInterval)
    {
        self.cancelled = false
        
        guard let _ = DataSource.sharedInstance.user?.userId else
        {
            self.loadedElements = nil
            self.refreshInterval = 0.0
            return
        }
        
        refreshInterval = timeout
        if #available (iOS 8.0, *)
        {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { [weak self]() -> Void in
                if let weakSelf = self
                {
                    weakSelf.loadElements()
                }
            })
        }
        else
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.loadElements()
                }
            })
        }
        
    }
    
    func loadElements()
    {
        if !self.cancelled
        {
            print("DataRefresher did Start refreshing elements with interval.")
            isInProgress = true
            
            self.serverRequester.loadAllElements { [weak self](objects, completionError) -> () in
              UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let weakSelf = self
                {
                    if weakSelf.cancelled
                    {
                        print("Stopped refreshing elements : SELF.cancelled")
                        return
                    }
                }
                else
                {
                    print("Stopped refreshing elements : no SELF")
                    return
                }
                
                if let recievedElements = objects as? [Element]
                {
                    //var sortedElements = recievedElements
                    //ObjectsConverter.sortElementsByDate(&sortedElements)

                    guard let dataBaseHandler = DataSource.sharedInstance.localDatadaseHandler else
                    {
                        print("")
                        return
                    }
                    
                    do
                    {
                        let currentIds = try dataBaseHandler.readAllElementIDs()
                        
                        //start refreshing and deleting elements if needed
                        var currentRecievedElementIDsFromServer = Set<Int>()
                        for anElementFromServer in recievedElements where anElementFromServer.elementId != nil
                        {
                            currentRecievedElementIDsFromServer.insert(anElementFromServer.elementId!)
                        }
                        
                        let elementIdsToDelete = currentRecievedElementIDsFromServer.subtract(currentIds)
                        
                        if !elementIdsToDelete.isEmpty
                        {
                            dataBaseHandler.deleteElementsByIds(elementIdsToDelete)
                        }
                        
                        dataBaseHandler.saveElementsToLocalDatabase(recievedElements, completion: { (didSave, error) -> () in
                            DataSource.sharedInstance.localDatadaseHandler?.performMessagesAndElementsPairing({ () -> () in
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    NSNotificationCenter.defaultCenter().postNotificationName(kElementWasChangedNotification, object: nil)
                                })
                                
                            })
                        })
                        
                    }
                    catch// let error
                    {
                        //insert all elements as NEW in database
                        DataSource.sharedInstance.localDatadaseHandler?.saveElementsToLocalDatabase(recievedElements, completion: { (didSave, error) -> () in
                            
                            DataSource.sharedInstance.localDatadaseHandler?.performMessagesAndElementsPairing({ () -> () in
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    NSNotificationCenter.defaultCenter().postNotificationName(kElementWasChangedNotification, object: nil)
                                })
                            })
                        })
                    }
                }
                
                if let weakSelf = self
                {
                    if weakSelf.cancelled
                    {
                        print("Stopped refreshing elements : SELF.cancelled")
                        return
                    }
                    else
                    {
                        weakSelf.startNewRefreshLoop()
                    }
                }
                else
                {
                    print("Stopped refreshing elements : no SELF")
                    return
                }
            }
        }
        else
        {
            print("\n  Oops \(self)  is Cancelled. will not start loadnig all elements again.")
        }
    }
    
    func startNewRefreshLoop()
    {
       // self.isInProgress = false
        
        if self.refreshInterval > 0
        {
            
            var globalQueue:dispatch_queue_t?
            
            if #available (iOS 8.0, *)
            {
                globalQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
            }
            else
            {
                globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
            }
            
            if let aQueue = globalQueue
            {
                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(refreshInterval * Double(NSEC_PER_SEC)))
                dispatch_after(when, aQueue, {[weak self] () -> Void in
                if let aSelf = self
                {
                    if !aSelf.cancelled
                    {
                        aSelf.loadElements()
                    }
                }
                })
            }
        }

    }
    
    func stopRefreshingElements()
    {
        self.cancelled = true
        self.refreshInterval = 0.0
        self.isInProgress = false
        
        
        print("DataRefresher did stop refreshing elements with interval.")
    }
    
    
}//Class end