//
//  ParticipantsVC.swift
//  Origami
//
//  Created by CloudCraft on 30.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ParticipantsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var contactsTable:UITableView!
    
    var currentElementId = 0
    var rootElementId = 0
    private var elementIsOwned = false
    var contacts:[DBContact]?
    var checkedContacts:[DBContact] = [DBContact]()
    var uncheckedContacts:[DBContact] = [DBContact]()
    var selectionEnabled = false
    var displayMode:DisplayMode = .Day
    
    var participantIDsForElement:Set<Int> = Set<Int>()
    //MARK: -
   
    
    //MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let currentElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(currentElementId), elementId = currentElement.rootElementId?.integerValue
        {
            self.rootElementId = elementId
            
            DataSource.sharedInstance.loadPassWhomIdsForElement(elementId, comlpetion: nil)
        }
        
        DataSource.sharedInstance.loadPassWhomIdsForElement(currentElementId) { (finished) -> () in
            DataSource.sharedInstance.localDatadaseHandler?.readAllMyContacts({[weak self] (dbContacts) -> () in
                
                if let weakSelf = self
                {
                    weakSelf.contacts = dbContacts
                    dispatch_async(dispatch_get_main_queue()) { _ in
                        weakSelf.setUpInitialArrays()
                    }
                }
                })
        }
    
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        setAppearanceForNightModeToggled(nightModeOn)
        self.displayMode = (nightModeOn) ? .Night : .Day
    }
    
    func setElementOwned(owned: Bool)
    {
        self.elementIsOwned = owned
    }
    
    //MARK: ---
    func setUpInitialArrays()
    {
        if let passWhomIDsForCurrentElement = DataSource.sharedInstance.participantIDsForElement[currentElementId]
        {
            self.participantIDsForElement = passWhomIDsForCurrentElement
        }
        
        if let lvContacts = self.contacts
        {
            var participantsToSort = [DBContact]()
            var nonParticipantsToSort = [DBContact]()
            for aContact in lvContacts
            {
                guard let contactId = aContact.contactId?.integerValue else
                {
                    continue
                }
                
                if participantIDsForElement.contains(contactId)
                {
                    participantsToSort.append(aContact)
                }
                else
                {
                    nonParticipantsToSort.append(aContact)
                }
            }
            
            let sortingFunc = {(contact1:DBContact, contact2:DBContact) -> Bool in
                if let fullName1 = contact1.nameAndLastNameSpacedString(), fullName2 = contact2.nameAndLastNameSpacedString()
                {
                    return fullName1 < fullName2
                }
                return true
            }
            
            participantsToSort.sortInPlace(sortingFunc)
            
            nonParticipantsToSort.sortInPlace(sortingFunc)
            
            checkedContacts = participantsToSort
            uncheckedContacts = nonParticipantsToSort
        }
        
        contactsTable.delegate = self
        contactsTable.dataSource = self
        contactsTable.reloadData()
    }
    
//    func sortContactsAlphabeticaly(inout contactArray:[DBContact])
//    {
//        contactArray.sortInPlace({ (contact1, contact2) -> Bool in
//            if let
//                firstName1 = contact1.firstName,// as? String,
//                firstName2 = contact2.firstName //as? String
//            {
//                return firstName1 >= firstName2
//            }
//            
//            if let
//                lastName1 = contact1.lastName, //as? String,
//                lastName2 = contact2.lastName //as? String
//            {
//                return lastName1 > lastName2
//            }
//            
//            
//            return contact1.userName >= contact2.userName
//        })
//    }

    func dismissSelf()
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func contactForIndexPath(indexPath:NSIndexPath) -> DBContact?
    {
        switch indexPath.section
        {
        case 0:
            return checkedContacts[indexPath.row]
        case 1:
            return uncheckedContacts[indexPath.row]
        default: return nil
        }
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section
        {
        case 0:
            return checkedContacts.count
        case 1:
            return uncheckedContacts.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section
        {
        case 0:
            return "Team".localizedWithComment("")
        case 1:
            return "AddMember".localizedWithComment("")
            
        default : return nil
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section > 1
        {
            return nil
        }
        
        //prepare view
        let view = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, 50.0))
        view.backgroundColor = kWhiteColor
        view.opaque = true
        
        //prepare label
        let label = UILabel()
        label.textAlignment = NSTextAlignment.Center
        label.textColor = kDayCellBackgroundColor

        if let font = UIFont(name: "SegoeUI-Semibold", size: 18.0)
        {
            label.font = font
        }
        label.text = self.tableView(tableView, titleForHeaderInSection:section)

        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        //create constraints for label
        let centerXConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        
        let centerYConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        
        view.addConstraints([centerXConstraint, centerYConstraint])
        
        return view
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var nameLabelText:String?
        var currentAvatar = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
        if let currentContact = contactForIndexPath(indexPath)
        {
            nameLabelText = currentContact.nameAndLastNameSpacedString()
            if let avatarImage = DataSource.sharedInstance.userAvatarsHolder[currentContact.contactId!.integerValue]
            {
                currentAvatar = avatarImage
            }
        }
        
        let contactCell = tableView.dequeueReusableCellWithIdentifier("ContactCheckerCell", forIndexPath: indexPath) as! ContactCheckerCell
        contactCell.nameLabel?.text = nameLabelText
        contactCell.displayMode = self.displayMode
        contactCell.selectionStyle = UITableViewCellSelectionStyle.None
        contactCell.avatar?.image = currentAvatar
        switch indexPath.section
        {
        case 0:
            contactCell.checkBox?.image = checkedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
            contactCell.setDisabled(!elementIsOwned)
            return contactCell
        case 1:
            contactCell.checkBox?.image = unCheckedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
            contactCell.setDisabled(false)
            return contactCell
        default:
            let defaultCell = UITableViewCell(style: .Default, reuseIdentifier: "DummyCell") as UITableViewCell
            return defaultCell
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if !elementIsOwned
        {
            // current user is not creator of current element. We can`t assign or delete contacts.
            return
        }
        
        
        if let selectedContact = contactForIndexPath(indexPath), let contactId = selectedContact.contactId?.integerValue
        {
            guard contactId > 0 && currentElementId > 0 else
            {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                return
            }
            
            switch indexPath.section
            {
                case 0:
                    
                    let completionBlockForRemovingContact = { [weak self] (success:Bool, error:NSError?) -> () in
                        if let weakSelf = self
                        {
                            dispatch_async(dispatch_get_main_queue()) { _ in
                                if success
                                {
                                    weakSelf.checkedContacts.removeAtIndex(indexPath.row)
                                    weakSelf.contactsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                                    
                                    let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.3))
                                    dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                                        weakSelf.setUpInitialArrays()
                                    })
                                }
                                else
                                {
                                    weakSelf.showAlertWithTitle("Error", message: error!.localizedDescription, cancelButtonTitle: "Ok")
                                }
                            }
                            
                        }
                    }
                        
                        
                    // we cannot remove contacts from element if they are present in parent element
                    if let contactIDsForParentElement = DataSource.sharedInstance.participantIDsForElement[rootElementId]
                    {
                        if !contactIDsForParentElement.contains(contactId)
                        {
                            DataSource.sharedInstance.removeContact(contactId, fromElement: currentElementId, completion: completionBlockForRemovingContact)
                        }
                    }
                    else
                    {
                        DataSource.sharedInstance.removeContact(contactId, fromElement: currentElementId, completion: completionBlockForRemovingContact)
                    }
                
                case 1:
                
                    let completionBlockForAddingContact = { [weak self] (success:Bool, error:NSError?) -> () in
                        if let weakSelf = self
                        {
                            dispatch_async(dispatch_get_main_queue()) { _ in
                                if success
                                {
                                    weakSelf.uncheckedContacts.removeAtIndex(indexPath.row)
                                    weakSelf.contactsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Right)
                                    
                                    let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.3))
                                    dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                                        weakSelf.setUpInitialArrays()
                                    })
                                }
                                else
                                {
                                    self!.showAlertWithTitle("Error", message: error!.localizedDescription, cancelButtonTitle: "Ok")
                                }
                            }
                        }
                    }
                    
                    DataSource.sharedInstance.addContact(contactId, toElement:currentElementId, completion: completionBlockForAddingContact)
                
                default: break
            }//end of SWITCH statement
        }
    }
    
}
