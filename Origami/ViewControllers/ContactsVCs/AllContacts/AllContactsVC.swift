//
//  AllContactsVC.swift
//  Origami
//
//  Created by CloudCraft on 18.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class AllContactsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //TODO: Delete this class completely
    @IBOutlet weak var contactsTable:UITableView?
    var delegate:AllContactsDelegate?
    var allContacts:[Contact]?
    var contactImages = [String:UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        contactsTable?.estimatedRowHeight = 60
        contactsTable?.rowHeight = UITableViewAutomaticDimension
        
        if let existContacts = allContacts
        {
            self.allContacts = existContacts.sort { (contact1, contact2) -> Bool in
                if let
                    lastName1 = contact1.lastName,// as? String, 
                    lastName2 = contact2.lastName //as? String
                {
                    let comparisonResult = lastName1.caseInsensitiveCompare(lastName2)
                    return comparisonResult == .OrderedAscending
                }
                return false
            }
            
            let bgQueue = dispatch_queue_create("avatars-loader-queue", DISPATCH_QUEUE_CONCURRENT)
            dispatch_async(bgQueue, { [weak self]() -> Void in
                let bgGroup = dispatch_group_create()
            
                var shouldReloadAfterRealAvatarLoaded = false
                
                for lvContact in existContacts
                {
                    let userName = lvContact.userName //as? String
                    if !userName.isEmpty
                    {
                        dispatch_group_enter(bgGroup)
                        
                        if let avatar = DataSource.sharedInstance.getAvatarForUserId(lvContact.contactId)
                        {
                            if let weakSelf = self{
                                weakSelf.contactImages[userName] = avatar
                                shouldReloadAfterRealAvatarLoaded = true
                            }
                        }
//                        

                                
                            //}
                            dispatch_group_leave(bgGroup)
                        //})
                    }
                }
            
            
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 30.0))
                
                dispatch_group_wait(bgGroup, timeout)
           
                if shouldReloadAfterRealAvatarLoaded
                {
                    if let weakSelf = self
                    {
                        if let visibleCells = weakSelf.contactsTable?.visibleCells as? [AllContactsVCCell]
                        {
                            var indexPathsToReload = [NSIndexPath]()
                            for aCell in visibleCells
                            {
                                if let indexPath = weakSelf.contactsTable?.indexPathForCell(aCell)
                                {
                                    indexPathsToReload.append(indexPath)
                                }
                            }
                            if !indexPathsToReload.isEmpty
                            {
                                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                                    if let weakSelf = self
                                    {
                                        weakSelf.contactsTable?.reloadRowsAtIndexPaths(indexPathsToReload, withRowAnimation: .None)
                                    }
                                })
                            }
                        }
                    }
                }
                else
                {
                    print(" No Avatar loaded. Will not reload visible rows.")
                }
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
            return contacts.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let commonContactCell = tableView.dequeueReusableCellWithIdentifier("allContactsCell", forIndexPath: indexPath) as! AllContactsVCCell
        
        commonContactCell.avatarImageView?.maskToCircle()
        commonContactCell.selectionStyle = .None
        configureCell(commonContactCell, forIndexPath: indexPath)
        
        return commonContactCell
    }
    
    func configureCell(cell:AllContactsVCCell, forIndexPath indexPath:NSIndexPath)
    {
        if let contact = contactForIndexPath(indexPath)
        {
            let mine = contactIsMine(contact)
            
            cell.contactIsMine = mine

          
            cell.moodLabel?.text = contact.mood //as? String//userMood /* "Warning once only: Detected a case where constraints ambiguous" */
            var contactName = ""
            
            if let firstName = contact.firstName //as? String
            {
                contactName = firstName
            }
            if let lastName = contact.lastName //as? String
            {
                if contactName.isEmpty
                {
                    contactName = lastName
                }
                else
                {
                    contactName += (" " + lastName)
                }
            }
            
            cell.nameLabel?.text = (contactName.isEmpty) ? nil : contactName
            
            if let avatarImage = contactImages[contact.userName]
            {
                cell.avatarImageView?.image = avatarImage
            }
            else
            {
                cell.avatarImageView?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            }

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
        //TODO: delete methods no longer used
        if let _ = DataSource.sharedInstance.getContactsByIds(Set([contact.contactId]))
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
    
    private func contactNameStringFromContact(contact:Contact) -> String
    {
        var nameString = ""
//        if let firstName = contact.firstName as? String
//        {
//            nameString += firstName
//        }
//        if let lastName = contact.lastName as? String
//        {
//            if nameString.isEmpty
//            {
//                nameString = lastName
//            }
//            else
//            {
//                nameString += (" " + lastName)
//            }
//        }
        if let lvNameString = contact.nameAndLastNameSpacedString()
        {
            nameString = lvNameString
        }
        return nameString
    }
    
    //MARK: Selection of Contacts
    func didSelectContact(contact:Contact, atIndexPath indexPath:NSIndexPath)
    {
        if contactIsMine(contact)
        {
            DataSource.sharedInstance.deleteMyContact(contact, completion: { [weak self] (success, error) -> () in
                
                if let weakSelf = self
                {
                    if success
                    {
                        weakSelf.contactsTable?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                        DataSource.sharedInstance.localDatadaseHandler?.deleContactById(contact.contactId) {[weak self] _ in
                            if let weakSelf = self
                            {
                                dispatch_async(dispatch_get_main_queue())
                                {
                                    weakSelf.delegate?.reloadUserContactsSender(weakSelf) //MyContactsVC will try to refetch contacts
                                }
                            }
                        }
                    }
                    else
                    {
                        weakSelf.showAlertWithTitle("Warning", message: "Could not delete contact", cancelButtonTitle: "Close")
                    }
                }
            })
        }
        else
        {
            DataSource.sharedInstance.addNewContactToMyContacts(contact, completion: { [weak self] (success, error) -> () in
                if let weakSelf = self
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                        if success
                        {
                            weakSelf.contactsTable?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                            weakSelf.delegate?.reloadUserContactsSender(weakSelf) //MyContactsVC will try to refetch contacts
                        }
                        else
                        {
                            weakSelf.showAlertWithTitle("Warning", message: "Could not add contact", cancelButtonTitle: "Close")
                        }
                    }
                }
            })
        }
    }
}