//
//  AllContactsVC.swift
//  Origami
//
//  Created by CloudCraft on 18.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class AllContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var contactsTable:UITableView?
    
    var allContacts:[Contact]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        contactsTable?.estimatedRowHeight = 60
        contactsTable?.rowHeight = UITableViewAutomaticDimension
        
        if let existContacts = allContacts
        {
            allContacts!.sort({ (contact1, contact2) -> Bool in
                if let lastName1 = contact1.lastName as? String, lastName2 = contact2.lastName as? String
                {
                    let comparisonResult = lastName1.caseInsensitiveCompare(lastName2)
                    return comparisonResult == .OrderedAscending
                }
                return false
            })
        }
        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contacts = allContacts
        {
            return allContacts!.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var commonContactCell = tableView.dequeueReusableCellWithIdentifier("allContactsCell", forIndexPath: indexPath) as! AllContactsVCCell
        
        commonContactCell.avatarImageView?.maskToCircle()
        commonContactCell.selectionStyle = .None
        configureCell(commonContactCell, forIndexPath: indexPath)
        
        return commonContactCell
    }
    
    func configureCell(cell:AllContactsVCCell, forIndexPath indexPath:NSIndexPath)
    {
        if let contact = contactForIndexPath(indexPath)
        {
            cell.contactIsMine = contactIsMine(contact)
            
            var firstName = contact.firstName as? String
            var lastName = contact.lastName as? String
            var userName = contact.userName as? String
            var phoneNumber = contact.phone as? String
            var userMood = contact.mood as? String
            //cell.phoneNumber?.text = phoneNumber ?? "phone no."
            //cell.emailLabel?.text = userName
             cell.moodLabel?.text = /*userMood ??*/ "status"
            var contactName = ""
            
            if firstName != nil
            {
                contactName = firstName!
            }
            if lastName != nil
            {
                if contactName.isEmpty
                {
                    contactName = lastName!
                }
                else
                {
                    contactName += (" " + lastName!)
                }
            }
            //println(contactName)
            cell.nameLabel?.text = (contactName.isEmpty) ? nil : contactName
            
           
            
            cell.avatarImageView?.tintColor = kDayNavigationBarBackgroundColor
            //avatar
            DataSource.sharedInstance.loadAvatarForLoginName(contact.userName as! String, completion: {[weak cell] (image) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let weakCell = cell, avatarImage = image
                    {
                        weakCell.avatarImageView?.image = avatarImage
                    }
                })
                
            })
        }
    }
    
    func contactForIndexPath(path:NSIndexPath) -> Contact?
    {
        let row = path.row
        
        if let contacts = allContacts
        {
            let count = contacts.count
            
            if count > row
            {
                let contact = contacts[row]
                return contact
            }
        }
        
        return nil
    }
    
    func contactIsMine(contact:Contact) -> Bool
    {
        if let myContact = DataSource.sharedInstance.getContactsByIds(Set([contact.contactId!.integerValue]))
        {
            return true
        }
        return false
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        if let selectedContact = contactForIndexPath(indexPath)
        {
            didSelectContact(selectedContact, atIndexPath: indexPath)
        }
    }
    
    //MARK: Selection of Contacts
    func didSelectContact(contact:Contact, atIndexPath indexPath:NSIndexPath)
    {
        if contactIsMine(contact)
        {
            DataSource.sharedInstance.deleteMyContact(contact, completion: { [weak self] (success, error) -> () in
                if success
                {
                    if let weakSelf = self
                    {
                        weakSelf.contactsTable?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    }
                }
                else
                {
                    if let weakSelf = self
                    {
                        weakSelf.showAlertWithTitle("Warning", message: "Could not delete contact", cancelButtonTitle: "Close")
                    }
                }
            })
        }
        else
        {
            DataSource.sharedInstance.addNewContactToMyContacts(contact, completion: { [weak self] (success, error) -> () in
                if success
                {
                    if let weakSelf = self
                    {
                        weakSelf.contactsTable?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                    }
                }
                else
                {
                    if let weakSelf = self
                    {
                        weakSelf.showAlertWithTitle("Warning", message: "Could not add contact", cancelButtonTitle: "Close")
                    }
                }
            })
        }
    }
}
