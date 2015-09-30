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
    
    
    var isCancelled:Bool {
        return self.cancelled
    }
    
    func startRefreshingElementsWithTimeoutInterval(timeout:NSTimeInterval)
    {
        refreshInterval = timeout
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {[weak self] () -> Void in
            if let weakSelf = self
            {
                weakSelf.loadElements()
            }
        })
    }
    
    func loadElements()
    {
        isInProgress = true
        
        serverRequester.loadAllElements { [weak self](objects, completionError) -> () in
            
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
                var sortedElements = recievedElements
                ObjectsConverter.sortElementsByDate(&sortedElements)
                
                //let currentElementsCount = DataSource.sharedInstance.countExistingElements()
                let newElementsCount = sortedElements.count
                
                if let allCurrentElements = DataSource.sharedInstance.getAllElementsLocked()
                {
                    
                    let existingSet = Set(allCurrentElements)
                    let newSet = Set(sortedElements)
        
                    let comonElementsSetForExisting = existingSet.intersect(newSet)
                    let commonElementSetForNew = newSet.intersect(existingSet)
                    
                    if existingSet.count == newSet.count
                    {
                        if existingSet.isSubsetOf(newSet)
                        {
                            if let weakSelf = self
                            {
                                if !weakSelf.cancelled
                                {
                                    weakSelf.startNewRefreshLoop()
                                    return
                                }
                                else
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
                        }
                        else
                        {
                            let changedElementsSet = newSet.subtract(existingSet)
                            
                            for changedOne in changedElementsSet
                            {
                                if let existingElement = DataSource.sharedInstance.getElementById(changedOne.elementId!.integerValue)
                                {
                                    existingElement.isSignal = changedOne.isSignal
                                    existingElement.details = changedOne.details
                                    existingElement.title = changedOne.title
                                    existingElement.typeId = changedOne.typeId
                                    existingElement.changeDate = NSDate().dateForServer()
                                    if let rootElements = DataSource.sharedInstance.getRootElementTreeForElement(existingElement)
                                    {
                                        for aRoot in rootElements
                                        {
                                            aRoot.changeDate = existingElement.changeDate
                                        }
                                    }
                                    DataSource.sharedInstance.shouldReloadAfterElementChanged = true
                                }
                            }
                            
                            if DataSource.sharedInstance.shouldReloadAfterElementChanged
                            {
                                NSNotificationCenter.defaultCenter().postNotificationName(kNewElementsAddedNotification, object: nil)
                            }
                            else
                            {
                                var newTotalElementsArray = Array(newSet)
                                ObjectsConverter.sortElementsByDate(&newTotalElementsArray)
                                
                                DataSource.sharedInstance.replaceAllElementsToNew(newTotalElementsArray)
                            }
                            
                            
                            
                            if let weakSelf = self
                            {
                                if !weakSelf.cancelled
                                {
                                    weakSelf.startNewRefreshLoop()
                                    return
                                }
                                else
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
                        }
                    }
                    
                    ///////-----/////
                    var elementsToDelete = existingSet.subtract(comonElementsSetForExisting)
                    if elementsToDelete.count > 0
                    {
                        var arrayToIterate = Array(elementsToDelete)
                        ObjectsConverter.sortElementsByDate(&arrayToIterate)
                        
                        var ints = [Int]()
                        for anElement in arrayToIterate
                        {
                            
                            if let aNumber = anElement.elementId
                            {
                                ints.append(aNumber.integerValue)
                            }
                        }
                        
                        DataSource.sharedInstance.deleteElementsLocked(ints)
                    }
                    
                    ///////-----/////
                    var elementsToInsert = newSet.subtract(commonElementSetForNew)
                    if elementsToInsert.count > 0
                    {
                        var arrayToIterate = Array(elementsToInsert)
                        ObjectsConverter.sortElementsByDate(&arrayToIterate)
                        
                        
                        DataSource.sharedInstance.addElementsLocked(arrayToIterate)
                    }
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
    func startNewRefreshLoop()
    {
        self.isInProgress = false
        
        if self.refreshInterval > 0
        {
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.refreshInterval * Double(NSEC_PER_SEC)))
            let globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
            dispatch_after(when, globalQueue, {[weak self] () -> Void in
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
    func stopRefreshingElements()
    {
        self.cancelled = true
        self.refreshInterval = 0.0
    }
    
    
}//Class end