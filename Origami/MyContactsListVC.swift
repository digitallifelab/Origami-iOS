//
//  ContactsListVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit
import CoreData
class MyContactsListVC: UIViewController , UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate, AllContactsDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var myContactsTable:UITableView?
    
    var myContacts:[DBContact]?
    var favContacts:[Contact] = [Contact]()
    var allContacts:[Contact]?
    var contactsSearchButton:UIBarButtonItem?
    var contactImages = [String:UIImage]()
    var currentSelectedContactsIndex:Int = 0
    var customTransitionAnimator:UIViewControllerAnimatedTransitioning?
    var allContactsFetchController:NSFetchedResultsController?
    var favContactsFetchController:NSFetchedResultsController?
    var localMainContext:NSManagedObjectContext?
    
    var currentFetchController:NSFetchedResultsController?
    //MARK:----
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureNavigationItems()
        configureNavigationControllerToolbarItems()
        
        if let dbHandler = DataSource.sharedInstance.localDatadaseHandler
        {
            self.localMainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            self.localMainContext!.parentContext = dbHandler.getPrivateContext()
            
            let allContactsRequest = NSFetchRequest(entityName: "DBContact")
            let lastNameSort = NSSortDescriptor(key: "lastName", ascending: true)
            allContactsRequest.sortDescriptors = [lastNameSort]
            self.allContactsFetchController = NSFetchedResultsController(fetchRequest: allContactsRequest, managedObjectContext: self.localMainContext!, sectionNameKeyPath: nil, cacheName: nil)
            
            let favContactsRequest = NSFetchRequest(entityName: "DBContact")
            favContactsRequest.sortDescriptors = [lastNameSort]
            favContactsRequest.predicate = NSPredicate(format: "favorite =  true")
            
            self.favContactsFetchController = NSFetchedResultsController(fetchRequest: favContactsRequest, managedObjectContext: self.localMainContext!, sectionNameKeyPath: nil, cacheName: nil)
            
            self.currentFetchController = self.allContactsFetchController
            self.currentFetchController?.delegate = self
            
        }
        
        #if SHEVCHENKO
        DataSource.sharedInstance.getAllContacts {[weak self] (contacts, error) -> () in
            
            if let weakSelf = self
            {
                if let allContacts = contacts
                {
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        weakSelf.allContacts = allContacts
                        weakSelf.contactsSearchButton?.enabled = true
                    }
                }
            }
        }
        #endif
        
        
        myContactsTable?.estimatedRowHeight = 60
        myContactsTable?.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool)
    {
        do {
            try self.currentFetchController?.performFetch()
        }
        catch{
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.removeGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
    }
    
    func configureNavigationItems()
    {
        contactsSearchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "showAllContactsVC")
        contactsSearchButton?.enabled = false
        self.navigationItem.rightBarButtonItem = contactsSearchButton
        
        let segmentedControl = UISegmentedControl(items: ["All".localizedWithComment(""), "Favorite".localizedWithComment("")])
        segmentedControl.selectedSegmentIndex = 0
        currentSelectedContactsIndex = segmentedControl.selectedSegmentIndex
        segmentedControl.addTarget(self, action: "contactsFilterDidChange:", forControlEvents: UIControlEvents.ValueChanged)
        self.navigationItem.titleView = segmentedControl

        
        configureLeftBarButtonItem()
    }
    
    func configureLeftBarButtonItem()
    {
        let leftButton = UIButton(type:.System)
        leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
        leftButton.setImage(UIImage(named: "icon-options")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        leftButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        
        let leftBarButton = UIBarButtonItem(customView: leftButton)
        
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func configureNavigationControllerToolbarItems()
    {
        let homeButton = UIButton(type:.System)
        //homeButton.tintColor = kDayNavigationBarBackgroundColor
        homeButton.setImage(UIImage(named: kHomeButtonImageName)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        homeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        homeButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        homeButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        homeButton.addTarget(self, action: "homeButtonPressed:", forControlEvents: .TouchUpInside)
        
        let homeImageButton = UIBarButtonItem(customView: homeButton)
        
        let flexibleSpaceLeft = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let flexibleSpaceRight = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let currentToolbarItems:[UIBarButtonItem] = [flexibleSpaceLeft, homeImageButton ,flexibleSpaceRight]
        
        //
        self.setToolbarItems(currentToolbarItems, animated: false)
    }
    
    
    //MARK: ------ menu displaying
    func menuButtonTapped(sender:AnyObject)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    //MARK: ---
    func showAllContactsVC()
    {
        if let allContactsVC = self.storyboard?.instantiateViewControllerWithIdentifier("AllContactsVC") as? AllContactsVC
        {
            allContactsVC.allContacts = allContacts
            allContactsVC.delegate = self
            self.navigationController?.pushViewController(allContactsVC, animated: true)
        }
    }
    
    //MARK: current VC

    func contactsFilterDidChange(sender:UISegmentedControl)
    {
        currentSelectedContactsIndex = sender.selectedSegmentIndex
        switch currentSelectedContactsIndex{
        case 0:
            self.currentFetchController = self.allContactsFetchController
        case 1:
            self.currentFetchController = self.favContactsFetchController
        default:
            break
        }
        
        
        self.currentFetchController?.delegate = self
        
        do
        {
            try self.currentFetchController?.performFetch()
        }
        catch
        {
            
        }
        self.myContactsTable?.reloadData()
        
    }
    
    
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let contactProfileVC = self.storyboard?.instantiateViewControllerWithIdentifier("ContactProfileVC") as? ContactProfileVC
        {
            if let contact = self.contactForIndexPath(indexPath)
            {
                contactProfileVC.contactManagedId = contact.objectID
            }
            self.navigationController?.pushViewController(contactProfileVC, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 67.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let contact = contactForIndexPath(indexPath)
        {
            let contactName = contact.nameAndLastNameSpacedString()!
            
            let mainFrameWidth = UIScreen.mainScreen().bounds.size.width
            let nameFrame = contactName.boundingRectWithSize(CGSizeMake(mainFrameWidth - (8 + 40 + 8 + 40), CGFloat(FLT_MAX) ), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 17.0)!], context: nil)
            
            var moodFrame = CGRectZero
            if let contactMood = contact.mood
            {
                moodFrame = contactMood.boundingRectWithSize(CGSizeMake(mainFrameWidth - (8 + 40 + 8 + 40), CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!], context: nil)
            }
            
            let verticalConstraints:CGFloat = 8 + 1 + 16
            let labelFrameHeights = nameFrame.size.height + moodFrame.size.height
            
           
            
            let toReturnHeight = ceil( labelFrameHeights + verticalConstraints )
            if toReturnHeight > 67.0
            {
                return toReturnHeight
            }
        }
        return 67.0
    }

    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
        if let currentFetchController = self.currentFetchController, objects = currentFetchController.fetchedObjects
        {
            return objects.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let contactCell = tableView.dequeueReusableCellWithIdentifier("MyContactCell", forIndexPath: indexPath) as! MyContactListCell
        contactCell.selectionStyle = .None
        
        configureCell(contactCell, forIndexPath:indexPath)
        return contactCell
    }
    
    private func configureCell(cell: MyContactListCell, forIndexPath indexPath:NSIndexPath)
    {
        if let contact = contactForIndexPath(indexPath)
        {
            //name field
            cell.nameLabel.text = contact.nameAndLastNameSpacedString()
            
            // mood field
            cell.moodLabel?.text = contact.mood
            
            //favourite
            if contact.favorite!.boolValue
            {
                cell.favouriteButton.tintColor = kDaySignalColor
            }
            else
            {
                cell.favouriteButton.tintColor = UIColor.lightGrayColor()
            }
            cell.favouriteButton.tag = indexPath.row
            
            //avatar
            cell.avatar.tintColor = kDayCellBackgroundColor
           
            if let avatarImage = DataSource.sharedInstance.getAvatarForUserId(contact.contactId!.integerValue)
            {
                cell.avatar?.image = avatarImage
            }
            else
            {
                cell.avatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            }

        }
    }
    
    private func contactForIndexPath(indexPath:NSIndexPath) -> DBContact?
    {
        let row = indexPath.row
        if let currentFetchController = self.currentFetchController, objects = currentFetchController.fetchedObjects as? [DBContact]
        {
            return objects[row]
        }
        
        return nil
    }
    
    private func contactNameStringFromContact(contact:Contact) -> String
    {
        var nameString = ""
        if let firstName = contact.firstName// as? String
        {
            nameString += firstName
        }
        if let lastName = contact.lastName// as? String
        {
            if nameString.isEmpty
            {
                nameString = lastName
            }
            else
            {
                nameString += (" " + lastName)
            }
        }
        
        return nameString
    }
    
    //MARK: Notifications
    func contactFavouriteToggledNotification(notification:NSNotification?)
    {
        if let
            userIndex = notification?.userInfo?["index"] as? Int,
            contact = self.contactForIndexPath(NSIndexPath(forRow: userIndex, inSection: 0))
        {
            let contactIdInt = contact.contactId!.integerValue
            guard contactIdInt > 0 else
            {
                print("\n WIll not try to update \"Favourite\" contact - 0(zero) contact id passed.\n")
                return
            }
        }
    }
    
    //MARK: - AllContactsDelegate
    func reloadUserContactsSender(sender: UIViewController?) {
        //self.myContacts = DataSource.sharedInstance.getMyContacts()
        do{
            try self.currentFetchController?.performFetch()
        }
        catch{
            
        }
        
        //self.myContactsTable?.reloadData()
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
            self.myContactsTable?.dataSource = nil
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.myContactsTable?.dataSource = self
        self.myContactsTable?.reloadData()
    }

}
