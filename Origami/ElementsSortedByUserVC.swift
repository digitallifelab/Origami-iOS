//
//  ElementsSortedByUserVC.swift
//  Origami
//
//  Created by CloudCraft on 11.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementsSortedByUserVC: RecentActivityTableVC, TableItemPickerDelegate {

    @IBOutlet weak var filterButtonsHolderView:UIView?
    /*
    //for showing current selected user 
    
    is subject to change if subclassing
    */
    var currentTopRightButton:UIButton?
    var currentSelectedUserAvatar:UIImage? = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
    var elementsCreatedByUser:[Element]?
    var elementsUserParticipatesIn:[Element]?
    var selectedUserId:NSNumber = NSNumber(integer: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureCurrentRightTopButton()
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
        
        if DataSource.sharedInstance.shouldReloadAfterElementChanged || self.elements == nil
        {
            isReloadingTable = true
            println(" -> Getting all elements By Activity from DataSource... ")
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
                                println(" -> Sorting all elements - sortCurrentElementsForNewUserId()")
                                weakSelf.sortCurrentElementsForNewUserId()
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if !weakSelf.isReloadingTable
                            {
                                //println(" -> reloading tableView.")
                                weakSelf.reloadTableView()
                            }
                        })//end of main_queue
                        }) //end of bgQueue
                }
            }
        }
    }
    
    func sortCurrentElementsForNewUserId()
    {
        let numberOfSectionsBeforeDeleting = self.numberOfSectionsInTableView(self.tableView!)
        
        self.elementsCreatedByUser?.removeAll(keepCapacity: false)
        self.elementsUserParticipatesIn?.removeAll(keepCapacity: false)
        self.elementsCreatedByUser = nil
        self.elementsUserParticipatesIn = nil
        println(" -> Reloading tableview..")
        self.tableView?.deleteSections(NSIndexSet(indexesInRange: NSMakeRange(0, numberOfSectionsBeforeDeleting)), withRowAnimation: .None)
        
        if let allElements = self.elements
        {
            let userIDFromDataSource = DataSource.sharedInstance.user?.userId
            
            var toSortMyElements = Set<Element>()
            var toSortParticipatingElements = Set<Element>()
            
            for anElement in allElements
            {
                //println("Element`s pass whom IDs: \(anElement.passWhomIDs)")
                
                if anElement.creatorId.isEqualToNumber( self.selectedUserId)
                {
                    toSortMyElements.insert(anElement)
                }
                else
                {
                    if userIDFromDataSource != nil
                    {
                        if userIDFromDataSource!.isEqualToNumber(self.selectedUserId)
                        {
                            toSortParticipatingElements.insert(anElement)
                        }
                        else if anElement.passWhomIDs.count > 0
                        {
                            let passIDsSet = Set(anElement.passWhomIDs)
                            
                            if passIDsSet.contains(self.selectedUserId)
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
                //self.elementsCreatedByUser?.removeAll(keepCapacity: true)
                self.elementsCreatedByUser = sortedMyElements
            }
            if sortedParticipatingElements.count > 0
            {
                //self.elementsUserParticipatesIn?.removeAll(keepCapacity: true)
                self.elementsUserParticipatesIn = sortedParticipatingElements
            }
        }
        
        isReloadingTable = false
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
    
    override func reloadTableView()
    {
        if isReloadingTable == true
        {
            return
        }
        
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.reloadData()
        let length = self.numberOfSectionsInTableView(self.tableView!)
        
        self.tableView?.reloadSections(NSIndexSet(indexesInRange: NSMakeRange(0, length)), withRowAnimation: .Top)
        isReloadingTable = false
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

    
    func configureCurrentRightTopButton()
    {
        if let rightButton = UIButton.buttonWithType(.System) as? UIButton
        {
            var rightButton = UIButton.buttonWithType(.System) as! UIButton
            rightButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
            rightButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
            rightButton.setImage(self.currentSelectedUserAvatar, forState: .Normal)
            rightButton.addTarget(self, action: "selectElementsOwnerTapped:", forControlEvents: .TouchUpInside)
            rightButton.imageView?.contentMode = .ScaleAspectFit
            self.currentTopRightButton = rightButton
            
            var rightBarButton = UIBarButtonItem(customView: self.currentTopRightButton!)
            
            self.navigationItem.rightBarButtonItem = rightBarButton
            
            configureCurrentRightButtonImage()
        }
    }
    
    func configureCurrentRightButtonImage()
    {
        if selectedUserId.integerValue == 0
        {
            if let userId = DataSource.sharedInstance.user?.userId
            {
                selectedUserId = NSNumber(integer: userId.integerValue)
            }
        }
        else
        {
            var currentUserName:String?
            if selectedUserId.isEqualToNumber(DataSource.sharedInstance.user!.userId!)
            {
                currentUserName = DataSource.sharedInstance.user?.userName as? String
            }
            else
            {
                let aSet = Set([selectedUserId.integerValue])
                if let contacts = DataSource.sharedInstance.getContactsByIds(aSet)
                {
                    let contact = contacts.first!
                    if let userName = contact.userName as? String
                    {
                        currentUserName = userName
                    }
                }
            }
            
            if let userNameExist = currentUserName
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), { () -> Void in
                    DataSource.sharedInstance.loadAvatarForLoginName(userNameExist, completion: {[weak self] (image) -> () in
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if let weakSelf = self
                            {
                                if let anImage = image
                                {
                                    println(" - > Avatar image size: \(anImage.size)")
                                    weakSelf.currentSelectedUserAvatar = anImage
                                    weakSelf.currentTopRightButton?.setImage(weakSelf.currentSelectedUserAvatar?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
                                    return
                                }
                                else
                                {
                                    weakSelf.currentSelectedUserAvatar = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
                                    weakSelf.currentTopRightButton?.setImage(weakSelf.currentSelectedUserAvatar, forState: .Normal)
                                    
                                    println(" -> Could not load AVATAR image for selected contact.")
                                }
                            }
                        })
                    })
                })
            }
        }
    }
    
    func selectElementsOwnerTapped(sender:AnyObject)
    {
        if let contactsPicker = self.storyboard?.instantiateViewControllerWithIdentifier("ConfigurableContactsVC") as? ConfigurableContactsVC
        {
            contactsPicker.delegate = self
            
            contactsPicker.contactsToSelectFrom = DataSource.sharedInstance.getMyContacts()
            
            self.navigationController?.pushViewController(contactsPicker, animated: true)
        }
    }
    
    //MARK: TableItemPickerDelegate
    func itemPickerDidCancel(itemPicker: AnyObject) {
        //self.isReloadingTable = true
       
        if let aNumber = DataSource.sharedInstance.user?.userId
        {
            if self.selectedUserId.integerValue != aNumber.integerValue
            {
                self.selectedUserId = NSNumber(integer: aNumber.integerValue)
                self.configureCurrentRightButtonImage()
                
                sortCurrentElementsForNewUserId()
                
                self.reloadTableView()
            }
            else
            {
                isReloadingTable = false
            }
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject) {
        //self.isReloadingTable = true
        
        if let aContact = item as? Contact
        {
            if let aNumber = aContact.contactId
            {
                if self.selectedUserId.integerValue != aNumber.integerValue
                {
                    self.selectedUserId = NSNumber(integer: aNumber.integerValue)
                    self.configureCurrentRightButtonImage()
                    
                    sortCurrentElementsForNewUserId()
                    self.reloadTableView()
                }
                else
                {
                    self.isReloadingTable = false
                }
            }
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}
