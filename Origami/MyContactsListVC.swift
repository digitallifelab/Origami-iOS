//
//  ContactsListVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class MyContactsListVC: UIViewController , UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var myContactsTable:UITableView!
    
    var myContacts:[Contact]?
    
    var allContacts:[Contact]?
    
    var contactsSearchButton:UIBarButtonItem?
    
    var currentSelectedContactsIndex:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureNavigationItems()
        
        //myContactsTable.editing = true
        
        DataSource.sharedInstance.getAllContacts {[weak self] (contacts, error) -> () in
            
            if let weakSelf = self
            {
                if let allContacts = contacts
                {
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        weakSelf.allContacts = allContacts
                        weakSelf.contactsSearchButton?.enabled = true
                    })
               
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        myContacts = DataSource.sharedInstance.getMyContacts()
        if myContacts != nil
        {
            myContactsTable.reloadData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contactFavouriteToggledNotification:", name: kContactFavouriteButtonTappedNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kContactFavouriteButtonTappedNotification, object: nil)
        
    }
    
    func configureNavigationItems()
    {
        let closeButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Reply, target: self, action: "dismissSelf:")
        self.navigationItem.leftBarButtonItem = closeButton
        
        contactsSearchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "showAllContactsVC")
        contactsSearchButton?.enabled = false
        self.navigationItem.rightBarButtonItem = contactsSearchButton
        
        let segmentedControl = UISegmentedControl(items: ["All", "Favourite"])
        segmentedControl.selectedSegmentIndex = 0
        self.navigationItem.titleView = segmentedControl
    }
    
    func dismissSelf(sender:AnyObject?)
    {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showAllContactsVC()
    {
        if let allContactsVC = self.storyboard?.instantiateViewControllerWithIdentifier("AllContactsVC") as? AllContactsVC
        {
            allContactsVC.allContacts = allContacts
            self.navigationController?.pushViewController(allContactsVC, animated: true)
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }

//    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return true
//    }
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if myContacts != nil
        {
             return myContacts!.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var contactCell = tableView.dequeueReusableCellWithIdentifier("MyContactCell", forIndexPath: indexPath) as! MyContactListCell
        contactCell.selectionStyle = .None
        
        configureCell(contactCell, forIndexPath:indexPath)
        return contactCell
    }
    
    private func configureCell(cell: MyContactListCell, forIndexPath indexPath:NSIndexPath)
    {
        if let contact = contactForIndexPath(indexPath)
        {
            //name field
            var nameString = ""
            if let firstName = contact.firstName as? String
            {
                nameString += firstName
            }
            if let lastName = contact.lastName as? String
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
            cell.nameLabel.text = nameString
            
            //favourite
            if contact.isFavourite.boolValue
            {
                cell.favouriteButton.tintColor = UIColor.yellowColor()
            }
            else
            {
                cell.favouriteButton.tintColor = UIColor.blackColor()
            }
            
            //email field
            cell.emailLabel?.text = contact.userName as? String
            
            //phone field
            cell.phoneLabel?.text = contact.phone as? String
            
            //avatar
            DataSource.sharedInstance.loadAvatarForLoginName(contact.userName as! String, completion: {[weak cell] (image) -> () in
                if let weakCell = cell, avatarImage = image
                {
                    weakCell.avatar.image = avatarImage
                }
            })
        }
    }
    
    private func contactForIndexPath(indexPath:NSIndexPath) -> Contact?
    {
        let row = indexPath.row
        if myContacts!.count > row
        {
            let lvContact = myContacts![row]
            return lvContact
        }
        return nil
    }
    
    private func contactByUserName(userName:String) -> Contact?
    {
        if let contacts = myContacts
        {
            for aContact in contacts
            {
                if aContact.userName == userName
                {
                    return aContact
                }
            }
        }
        
        return nil
    }
    
    private func indexPathForContact(contact:Contact) -> NSIndexPath?
    {
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
      
        return nil
    }
    
    //MARK: Notifications
    func contactFavouriteToggledNotification(notification:NSNotification?)
    {
        if let
            userName = notification?.userInfo?["userName"] as? String,
            contact = self .contactByUserName(userName),
            contactIdInt = contact.contactId?.integerValue
        {
            
            DataSource.sharedInstance.updateContactIsFavourite(contactIdInt, completion: {[weak self] (success, error) -> () in
                if success
                {
                    var favourite = contact.isFavourite.boolValue
                    favourite = !favourite
                    DataSource.sharedInstance.getContactsByIds(Set([contactIdInt]))!.first!.isFavourite = NSNumber(bool: favourite)
                    
                    if let weakSelf = self, indexPath = weakSelf.indexPathForContact(contact)
                    {
                        weakSelf.myContactsTable.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    }
                }
                else if let responseError = error
                {
                    println(" Some error while changing contact IsFavourite: \n\(responseError) ")
                }
            })
        }
    }

}
