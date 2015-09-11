//
//  ElementsSortedByUserVC.swift
//  Origami
//
//  Created by CloudCraft on 11.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementsSortedByUserVC: RecentActivityTableVC {

    var elementsCreatedByUser:[Element]?
    var elementsUserParticipatesIn:[Element]?
    var selectedUserId:NSNumber = NSNumber(integer: 0)
    override func viewDidLoad() {
        super.viewDidLoad()

        if let userId = DataSource.sharedInstance.user?.userId
        {
            selectedUserId = NSNumber(integer: userId.integerValue)
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.removeGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        super.viewWillDisappear(animated)
        
    }
    
    override func startLoadingElementsByActivity() {
        DataSource.sharedInstance.getAllElementsSortedByActivity { [weak self] (elements) -> () in
            if let weakSelf = self
            {
                let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                dispatch_async(bgQueue, {[weak self] () -> Void in
                    if let weakerSelf = self
                    {
                        weakerSelf.elements = elements
                        if weakerSelf.selectedUserId.integerValue > 0  //sort elements by currently selected user
                        {
                            if let allElements = weakerSelf.elements
                            {
                                let userIDFromDataSource = DataSource.sharedInstance.user?.userId
                                
                                var toSortMyElements = Set<Element>()
                                var toSortParticipatingElements = Set<Element>()
                                for anElement in allElements
                                {
                                    //println("Element`s pass whom IDs: \(anElement.passWhomIDs)")
                                    if anElement.creatorId.isEqualToNumber( weakerSelf.selectedUserId)
                                    {
                                        toSortMyElements.insert(anElement)
                                    }
                                    else
                                    {
                                        if userIDFromDataSource != nil
                                        {
                                            if userIDFromDataSource!.isEqualToNumber(weakerSelf.selectedUserId)
                                            {
                                                toSortParticipatingElements.insert(anElement)
                                            }
                                            else if anElement.passWhomIDs.count > 0
                                            {
                                                let passIDsSet = Set(anElement.passWhomIDs)
                                                
                                                if passIDsSet.contains(weakerSelf.selectedUserId)
                                                {
                                                    toSortParticipatingElements.insert(anElement)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                var sortedMyElements = Array(toSortMyElements)
                                ObjectsConverter.sortElementsByDate(&sortedMyElements)
                                
                                var sortedParticipatingElements = Array(toSortParticipatingElements)
                                ObjectsConverter.sortElementsByDate(&sortedParticipatingElements)
                                
                                if sortedMyElements.count > 0
                                {
                                    weakerSelf.elementsCreatedByUser = sortedMyElements
                                }
                                if sortedParticipatingElements.count > 0
                                {
                                    weakerSelf.elementsUserParticipatesIn = sortedParticipatingElements
                                }
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if !weakSelf.isReloadingTable
                        {
                            weakSelf.reloadTableView()
                        }
                    })//end of main_queue
                }) //end of bgQueue
            }
        }

    }
    
    override func configureNavigationControllerToolbarItems() {
        super.configureNavigationControllerToolbarItems()
        configureNavigationControllerNavigationBarButtonItems()
    }
    
    
    func configureNavigationControllerNavigationBarButtonItems()
    {
//        func configureLeftBarButtonItem()
//        {
            var leftButton = UIButton.buttonWithType(.System) as! UIButton
            leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
            leftButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
            leftButton.setImage(UIImage(named: "icon-options")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
            leftButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
            
            var leftBarButton = UIBarButtonItem(customView: leftButton)
            
            self.navigationItem.leftBarButtonItem = leftBarButton
//        }
    }
    
    //MARK: ------ menu displaying
    func menuButtonTapped(sender:AnyObject)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    
    
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var number:Int = 0
        if let elementsByUser = elementsCreatedByUser
        {
            if !elementsByUser.isEmpty
            {
                number += 1
            }
        }
        
        if let participatingElements = elementsUserParticipatesIn
        {
            if !participatingElements.isEmpty
            {
                number += 1
            }
        }
        
        return number
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section
        {
        case 0:
            if let elementsByUser = elementsCreatedByUser
            {
                return elementsByUser.count
            }
            else if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating.count
            }
            else
            {
                return 0
            }
        case 1:
            if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating.count
            }
            else
            {
                return 0
            }
            
        default:
            return 0
        }
    }
    
    override func elementForIndexPath(indexPath: NSIndexPath) -> Element? {
        switch indexPath.section
        {
        case 0:
            if let elementsByUser = elementsCreatedByUser
            {
                return elementsByUser[indexPath.row]
            }
            else if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating[indexPath.row]
            }
            else
            {
                return nil
            }
        case 1:
            if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating[indexPath.row]
            }
            else
            {
                return nil
            }
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section
        {
        case 0:
            if let elementsByUser = elementsCreatedByUser
            {
                return "Creator of".localizedWithComment("")
            }
            else if let elementsParticipating = elementsUserParticipatesIn
            {
                return "Participant of".localizedWithComment("")
            }
        case 1:
            if let elementsParticipating = elementsUserParticipatesIn
            {
                return "Participant of".localizedWithComment("")
            }
        default:
            break
        }
        return nil
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section < 2
        {
            return 50.0
        }
        return 0.0
    }

}
