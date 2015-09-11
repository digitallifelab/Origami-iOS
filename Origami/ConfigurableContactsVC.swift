//
//  ConfigurableContactsViewController.swift
//  Origami
//
//  Created by CloudCraft on 11.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ConfigurableContactsVC: UITableViewController {

    let kContactCellIdentifier = "SelectableContactCell"
    var contactsToSelectFrom:[Contact]?
    var delegate:TableItemPickerDelegate?
    var avatarsHolder:[NSIndexPath:UIImage] = [NSIndexPath:UIImage]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let contacts = contactsToSelectFrom
        {
            
            let bgOpQueue = NSOperationQueue()
            var i = 0
            for aContact in contacts
            {
                let indexPath = NSIndexPath(forRow: i, inSection: 0)
                i++
                if let userName = aContact.userName as? String
                {
                    bgOpQueue.addOperationWithBlock({ () -> Void in
                        
                        DataSource.sharedInstance.loadAvatarForLoginName(userName) {[weak self] (image) -> () in
                            if let avatar = image
                            {
                                if let weakSelf = self
                                {
                                    weakSelf.avatarsHolder[indexPath] = avatar
                                }
                            }
                        }
                    })
                }
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if let contacts = contactsToSelectFrom
        {
            return 1
        }
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contacts = contactsToSelectFrom
        {
            return contacts.count
        }
        return 0
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! SelectableContactCell

        if let contact = contactForIndexPath(indexPath)
        {
            if let contactFullname = contact.nameAndLastNameSpacedString()
            {
                cell.contactNameLabel?.text = contactFullname
            }
        }
        
        if let avatar = avatarsHolder[indexPath]
        {
            cell.avatarImageView?.image = avatar
        }
        else
        {
            cell.avatarImageView?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
        }

        return cell
    }
    
    func contactForIndexPath(indexPath:NSIndexPath) -> Contact?
    {
        if let contacts = contactsToSelectFrom
        {
            if indexPath.row < contacts.count
            {
                return contacts[indexPath.row]
            }
        }
        
        return nil
    }
    
    //MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let aContact = contactForIndexPath(indexPath)
        {
            println("did selet contact: \(aContact.firstName)")
            
            self.delegate?.itemPicker(self, didPickItem: aContact)
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66.0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66.0
    }
    
    

   

}
