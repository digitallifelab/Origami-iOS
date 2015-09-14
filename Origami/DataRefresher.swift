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
        //println(" -->DataRefresher.loadElements() called")
        isInProgress = true
        
        serverRequester.loadAllElements { [weak self](objects, completionError) -> () in
            
            if let weakSelf = self
            {
                if weakSelf.cancelled
                {
                    println("Stopped refreshing elements")
                    return
                }
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
                    let unionSet = newSet.union(existingSet)
                    let comonElementsSetForExisting = existingSet.intersect(newSet)
                    let commonElementSetForNew = newSet.intersect(existingSet)
                    let existingMoreThanNewSet = existingSet.subtract(newSet)
                    
                    var elementsToDelete = existingSet.subtract(comonElementsSetForExisting)
                    if elementsToDelete.count > 0
                    {
                        var arrayToIterate = Array(elementsToDelete)
                        ObjectsConverter.sortElementsByDate(&arrayToIterate)
                        
                        var ints = [Int]()
                        for anElement in arrayToIterate
                        {
                            //println("Element to delete: \n \(anElement.toDictionary().description)")
                            if let aNumber = anElement.elementId
                            {
                                ints.append(aNumber.integerValue)
                            }
                        }
                        
                        DataSource.sharedInstance.deleteElementsLocked(ints)
                    }
                    
                    var elementsToInsert = newSet.subtract(commonElementSetForNew)
                    if elementsToInsert.count > 0
                    {
                        var arrayToIterate = Array(elementsToInsert)
                        ObjectsConverter.sortElementsByDate(&arrayToIterate)
                        
                        for anElement in arrayToIterate
                        {
                            //println("Element to insert: \n \(anElement.toDictionary().description)")
                        }
                        
                        DataSource.sharedInstance.addElementsLocked(arrayToIterate)
                    }
                    
                    let newMoreThanExisting = newSet.subtract(existingSet)
                    
                    if existingMoreThanNewSet.count > 0
                    {
                        //println("\n->> Some Elements were DELETED on server...")
                    }
                    
                    if newMoreThanExisting.count > 0
                    {
                        //println("\n->> Some Elements were ADDED on server...")
                    }
                }
            }
            
            if let weakSelf = self
            {
                weakSelf.isInProgress = false
                
                if weakSelf.refreshInterval > 0
                {
                    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(weakSelf.refreshInterval * Double(NSEC_PER_SEC)))
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
        }
    }
    
    func stopRefreshingElements()
    {
        self.cancelled = true
        self.refreshInterval = 0.0
    }
    
    
}//Class end