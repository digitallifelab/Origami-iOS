//
//  ContactsPickerVC.swift
//  Origami
//
//  Created by CloudCraft on 22.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactsPickerVC: UIViewController, UITableViewDelegate, UITableViewDataSource, DatePickerDelegate {

    @IBOutlet weak var tableView:UITableView?
    
    let kContactCellIdentifier = "SelectableContactCell"
    var contactsToSelectFrom:[DBContact]?
    var delegate:TableItemPickerDelegate?
    var avatarsHolder:[NSIndexPath:UIImage] = [NSIndexPath:UIImage]()
 
    var finishDate:NSDate?
 
    var ableToPickFinishDate = false
    
    var selectedContactId:Int = 0
    var selectedIndexPath:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView?.allowsMultipleSelection = false
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView?.reloadData()
        tableView?.selectRowAtIndexPath(selectedIndexPath, animated: false, scrollPosition: .Middle)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed:")
        self.navigationItem.rightBarButtonItem = doneBarButtonItem
        
        
       
        //self.tableView?.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: .Top)
        if ableToPickFinishDate
        {
            configureToolbarDateButton()
        }
    }
    
    // MARK: -
    func configureToolbarDateButton()
    {
        let rightToolBarItem = UIBarButtonItem(title: "setFinishDate".localizedWithComment(""), style: UIBarButtonItemStyle.Bordered, target: self, action: "showDatePickerVC:")
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        self.toolbarItems = [flexibleSpace, rightToolBarItem]
    }
  
    // MARK: - Table view data source
    
     func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if let _ = contactsToSelectFrom
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
        
        var contact_id = -1
        
        if indexPath.section == 1
        {
            if let contact = contactForIndexPath(indexPath)
            {
                if let contactFullname = contact.nameAndLastNameSpacedString()
                {
                    cell.contactNameLabel?.text = contactFullname
                }
                if let contactId = contact.contactId?.integerValue
                {
                    contact_id = contactId
                }
            }
        }
        else if let _ = DataSource.sharedInstance.user, userId = DataSource.sharedInstance.user?.userId
        {
            cell.contactNameLabel?.text = "Me".localizedWithComment("")
            contact_id = userId
        }
        
        if let avatar = DataSource.sharedInstance.userAvatarsHolder[contact_id]
        {
            cell.avatarImageView?.image = avatar
        }
        else
        {
            cell.avatarImageView?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
        }
        
        
        return cell
    }
    
    func contactForIndexPath(indexPath:NSIndexPath) -> DBContact?
    {
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
        
        selectedIndexPath = indexPath
        
        if !ableToPickFinishDate
        {
            if let aContact = contactForIndexPath(indexPath)
            {
                self.selectedContactId = aContact.contactId!.integerValue
                self.delegate?.itemPicker(self, didPickItem: NSNumber(integer:self.selectedContactId))
            }
            else
            {
                self.selectedContactId = 0
                self.delegate?.itemPickerDidCancel(self)
            }
        }
        else
        {
            if let aContact = contactForIndexPath(indexPath)
            {
                self.selectedContactId = aContact.contactId!.integerValue
            }
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
//        if let contact = selectedContact
//        {
            self.delegate?.itemPicker(self, didPickItem: NSNumber(integer: self.selectedContactId))
//        }
    }
    
    // MARK: -
    func showDatePickerVC(sender:UIBarButtonItem)
    {
        if let datesPickerVc = self.storyboard?.instantiateViewControllerWithIdentifier("DatePickerVC") as? DatePickerVC
        {
            finishDate = nil
            datesPickerVc.delegate = self
            self.navigationController?.pushViewController(datesPickerVc, animated: true)
        }
    }
    //MARK: DatePickerDelegate
    func datePickerViewController(vc: DatePickerVC, didSetDate date: NSDate?) {
        self.finishDate = date
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
