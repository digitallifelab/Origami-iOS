//
//  ContactsListVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class MyContactsListVC: UIViewController , UITableViewDelegate, UITableViewDataSource,UIViewControllerTransitioningDelegate, AllContactsDelegate {

    @IBOutlet weak var myContactsTable:UITableView?
    
    var myContacts:[Contact]?
    var favContacts:[Contact] = [Contact]()
    var allContacts:[Contact]?
    var contactsSearchButton:UIBarButtonItem?
    var contactImages = [String:UIImage]()
    var currentSelectedContactsIndex:Int = 0
    var customTransitionAnimator:UIViewControllerAnimatedTransitioning?
    
    //MARK:----
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureNavigationItems()
        configureNavigationControllerToolbarItems()
        
        myContacts = DataSource.sharedInstance.getMyContacts()
        
        //#if SHEVCHENKO
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
        //#endif
        myContactsTable?.estimatedRowHeight = 60
        myContactsTable?.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool)
    {
        self.calculateFavouriteContacts { (favouriteContacts) -> () in
            if let fav = favouriteContacts
            {
                self.favContacts = fav
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contactFavouriteToggledNotification:", name: kContactFavouriteButtonTappedNotification, object: nil)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kContactFavouriteButtonTappedNotification, object: nil)
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
    func calculateFavouriteContacts( completion:((favouriteContacts:[Contact]?)->())? )
    {
        if let myCONTACTS = self.myContacts
        {
            var localFavContacts = [Contact]()
            for aContact in myCONTACTS
            {
                if aContact.isFavourite.boolValue
                {
                    localFavContacts.append(aContact)
                }
            }
            
            if let completionBlock = completion
            {
                if localFavContacts.isEmpty
                {
                    completionBlock(favouriteContacts: nil)
                }
                else
                {
                    //sort favourite contacts my lastName
                    localFavContacts.sortInPlace({ (contact1, contact2) -> Bool in
                        if let
                            lastName1 = contact1.lastName,// as? String,
                            lastName2 = contact2.lastName //as? String
                        {
                            return (lastName1.caseInsensitiveCompare(lastName2) == .OrderedAscending)
                        }
                        return false
                    })
                    completionBlock(favouriteContacts: localFavContacts)
                }
            }
            
        }
        else
        {
            if let completionBlock = completion
            {
                completionBlock(favouriteContacts: nil)
            }
        }
    }
    
    func contactsFilterDidChange(sender:UISegmentedControl)
    {
        currentSelectedContactsIndex = sender.selectedSegmentIndex
        
        self.myContactsTable?.reloadData()
    }
    
    
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let contactProfileVC = self.storyboard?.instantiateViewControllerWithIdentifier("ContactProfileVC") as? ContactProfileVC
        {
            contactProfileVC.contact = self.contactForIndexPath(indexPath)
            self.navigationController?.pushViewController(contactProfileVC, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 67.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let contact = contactForIndexPath(indexPath)
        {
            let contactName = contactNameStringFromContact(contact)
            
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
        switch currentSelectedContactsIndex
        {
        case 0:
            if myContacts != nil
            {
                return myContacts!.count
            }
        case 1:
            return favContacts.count
        default:
            break
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
            cell.nameLabel.text = contactNameStringFromContact(contact)
            
            // mood field
            cell.moodLabel?.text = contact.mood// as? String
            
            //favourite
            if contact.isFavourite.boolValue
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
           
            if let avatarImage = DataSource.sharedInstance.userAvatarsHolder[contact.contactId]
            {
                cell.avatar?.image = avatarImage
            }
            else
            {
                cell.avatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            }

        }
    }
    
    private func contactForIndexPath(indexPath:NSIndexPath) -> Contact?
    {
        let row = indexPath.row
        switch currentSelectedContactsIndex
        {
        case 0:
            if myContacts!.count > row
            {
                let lvContact = myContacts![row]
                return lvContact
            }
        case 1:
            if favContacts.count > row
            {
                return favContacts[row]
            }
        default:
            break
        }
        
        return nil
    }
    
    private func indexPathForContact(contact:Contact) -> NSIndexPath?
    {
        switch currentSelectedContactsIndex
        {
        case 0:
            if let contacts = myContacts
            {
                var count = -1
                for var i = 0; i < contacts.count; i++
                {
                    let aContact = contacts[i]
                    if aContact.userName == contact.userName
                    {
                        count = i
                        break
                    }
                }
                
                if count >= 0
                {
                    return NSIndexPath(forRow: count, inSection: 0)
                }
            }
        case 1:
            var count = -1
            for var i = 0; i < favContacts.count; i++
            {
                let aContact = favContacts[i]
                if aContact.userName == contact.userName
                {
                    count = i
                    break
                }
            }
            
            if count >= 0
            {
                return NSIndexPath(forRow: count, inSection: 0)
            }

        default:
            break
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
            let contactIdInt = contact.contactId
            guard contactIdInt > 0 else
            {
                print("\n WIll not try to update \"Favourite\" contact - 0(zero) contact id passed.\n")
                return
            }
            
            DataSource.sharedInstance.updateContactIsFavourite(contactIdInt, completion: {[weak self] (success, error) -> () in
                if success
                {
                    var favourite = contact.isFavourite.boolValue
                    favourite = !favourite
                    DataSource.sharedInstance.getContactsByIds(Set([contactIdInt]))!.first!.isFavourite = NSNumber(bool: favourite)
                    
                    if let weakSelf = self, indexPath = weakSelf.indexPathForContact(contact)
                    {
                        weakSelf.calculateFavouriteContacts({ (favouriteContacts) -> () in
                           
                            weakSelf.favContacts.removeAll(keepCapacity: false)
                            if let favs = favouriteContacts
                            {
                                weakSelf.favContacts += favs
                            }
                            switch weakSelf.currentSelectedContactsIndex
                            {
                            case 0:
                                  weakSelf.myContactsTable?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                            case 1:
                                if favourite == false
                                {
                                    weakSelf.myContactsTable?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
                                    
                                    //this is needed to reassign favButton.tag s
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.3)), dispatch_get_main_queue(), { [weak self]() -> Void in
                                        if let weakSelf = self
                                        {
                                            weakSelf.myContactsTable?.reloadData()
                                        }
                                    })
                                    
                                }
                            default:
                                break
                            }
                          
                        })
                    }
                }
                else if let responseError = error
                {
                    print(" Some error while changing contact IsFavourite: \n\(responseError) ")
                }
            })
        }
    }
    
    //MARK: - AllContactsDelegate
    func reloadUserContactsSender(sender: UIViewController?) {
        self.myContacts = DataSource.sharedInstance.getMyContacts()
        
        self.myContactsTable?.reloadData()
    }

}
