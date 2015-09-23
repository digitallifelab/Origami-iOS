//
//  ContactsPickerVC.swift
//  Origami
//
//  Created by CloudCraft on 22.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactsPickerVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView:UITableView?
    
    let kContactCellIdentifier = "SelectableContactCell"
    var contactsToSelectFrom:[Contact]?
    var delegate:TableItemPickerDelegate?
    var avatarsHolder:[NSIndexPath:UIImage] = [NSIndexPath:UIImage]()
    var datePicker:UIDatePicker?
    var shouldShowDatePicker = false
    var selectedContact:Contact?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        
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
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.shouldShowDatePicker
        {
            let datePicker = UIDatePicker(frame: CGRectMake(0, CGRectGetHeight(self.view.bounds) - 220.0, 300.0, 220.0))
            datePicker.datePickerMode = UIDatePickerMode.DateAndTime
            datePicker.minimumDate = NSDate()
            //set one day ahead
            
            datePicker.date = NSDate(timeInterval: 1.days, sinceDate: NSDate())
            datePicker.backgroundColor = kWhiteColor.colorWithAlphaComponent(0.8)
            self.view.addSubview(datePicker)
            self.datePicker = datePicker
            UIView.animateWithDuration(0.3, animations: { [unowned self]() -> Void in
                self.tableView?.contentInset = UIEdgeInsetsMake(0, 0, datePicker.bounds.size.height, 0)
                })
            let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed:")
            self.navigationItem.rightBarButtonItem = doneBarButtonItem
            
        }
        
        self.tableView?.reloadData()
        self.tableView?.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: .Top)
    }
    


    
  
    // MARK: - Table view data source
    
     func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if let contacts = contactsToSelectFrom
        {
            return 2
        }
        return 1
    }
    
     func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            return 1
        }
        
        if let contacts = contactsToSelectFrom
        {
            return contacts.count
        }
        
        return 0
    }
    
    
     func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! SelectableContactCell
        cell.selectionStyle = .None
        
        if indexPath.section == 1
        {
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
        }
        else
        {
            if let user = DataSource.sharedInstance.user
            {
                cell.contactNameLabel?.text = "Me".localizedWithComment("")
            }
        }
        
        return cell
    }
    
    func contactForIndexPath(indexPath:NSIndexPath) -> Contact?
    {
        //println("contact for section: \(indexPath.section) row: \(indexPath.row)")
        if indexPath.section == 0
        {
            return nil
        }
        
        if let contacts = contactsToSelectFrom
        {
            if (indexPath.row) < contacts.count
            {
                return contacts[indexPath.row]
            }
        }
        
        return nil
    }
    
    //MARK: UITableViewDelegate
     func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !shouldShowDatePicker
        {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            if let aContact = contactForIndexPath(indexPath)
            {
                // println("did selet contact: \(aContact.firstName)")
                self.selectedContact = aContact
                self.delegate?.itemPicker(self, didPickItem: aContact)
            }
            else
            {
                //println("-> Did select current user")
                self.selectedContact = nil
                self.delegate?.itemPickerDidCancel(self)
            }
        }
        else
        {
            if let aContact = contactForIndexPath(indexPath)
            {
                // println("did selet contact: \(aContact.firstName)")
                self.selectedContact = aContact
            }
            else
            {
                //println("-> Did select current user")
                if let currentUserId = DataSource.sharedInstance.user?.userId
                {
                     self.selectedContact = Contact(info: ["ContactId":currentUserId])
                }
            }
            //tableView.deselectRowAtIndexPath(indexPath, animated: false)
            //tableView.reloadData()
        }
    }
    
     func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66.0
    }
    
     func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 66.0
    }
    
    //MARK: Done button
    func doneButtonPressed(sender:UIBarButtonItem)
    {
        if let contact = selectedContact
        {
            self.delegate?.itemPicker(self, didPickItem: contact)
        }
    }
    
    
    


}
