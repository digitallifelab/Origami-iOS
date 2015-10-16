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
    
    var currentElement:Element?
    var contacts:[Contact]?
    var checkedContacts:[Contact] = [Contact]()
    var uncheckedContacts:[Contact] = [Contact]()
    var selectionEnabled = false
    var displayMode:DisplayMode = .Day
    
    var contactAvatars = [Int:UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentElement!.creatorId == DataSource.sharedInstance.user!.userId!.integerValue
        {
            selectionEnabled = true
        }

        setUpInitialArrays()
       
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
    
    //MARK: ---
    func setUpInitialArrays()
    {
        if let lvContacts = DataSource.sharedInstance.getMyContacts()
        {
            contacts = lvContacts
            
            if contacts != nil && currentElement != nil
            {
                if let passwhomIDs = currentElement?.passWhomIDs
                {
                    let passWhomIDsSet = Set(passwhomIDs)
                    let allContactsSet:Set<Contact> = Set(contacts!)
                    
                    checkedContacts = contacts!.filter({ (lvContact) -> Bool in
                        let contains = passWhomIDsSet.contains(lvContact.contactId)
                        return contains
                    })
                    //sort alphabeticaly
                    sortContactsAlphabeticaly(&checkedContacts)
                    
                    let uncheckedContactsSet = allContactsSet.subtract(Set(checkedContacts))
                    uncheckedContacts = Array(uncheckedContactsSet)
                    
                    sortContactsAlphabeticaly(&uncheckedContacts)
                }
                else
                {
                    uncheckedContacts += contacts!
                    sortContactsAlphabeticaly(&uncheckedContacts)
                }
            }
            
            let bgQueue:dispatch_queue_t?
            if #available (iOS 8.0, *)
            {
                bgQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
            }
            else
            {
                bgQueue = dispatch_queue_create("com.Origami.avatars.queue", DISPATCH_QUEUE_SERIAL)
            }
            
            dispatch_async(bgQueue!) {[weak self] () -> Void in
                var lvImagesDict = [Int:UIImage]()
                for aContact in lvContacts
                {
                    let integerId = aContact.contactId
                    if let avatarImage = DataSource.sharedInstance.getAvatarForUserId(integerId)
                    {
                        lvImagesDict[integerId] = avatarImage
                    }
                }
                if !lvImagesDict.isEmpty
                {
                    if let weakSelf = self
                    {
                        weakSelf.contactAvatars = lvImagesDict
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            weakSelf.contactsTable.reloadData()
                        })
                    }
                }
            }
            
        }
        
        contactsTable.delegate = self
        contactsTable.dataSource = self
        contactsTable.reloadData()
    }
    
    func sortContactsAlphabeticaly(inout contactArray:[Contact])
    {
        contactArray.sortInPlace({ (contact1, contact2) -> Bool in
            if let
                firstName1 = contact1.firstName,// as? String,
                firstName2 = contact2.firstName //as? String
            {
                return firstName1 >= firstName2
            }
            
            if let
                lastName1 = contact1.lastName, //as? String,
                lastName2 = contact2.lastName //as? String
            {
                return lastName1 > lastName2
            }
            
            
            return contact1.userName >= contact2.userName
        })
    }

    func dismissSelf()
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func contactForIndexPath(indexPath:NSIndexPath) -> Contact?
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
//        var testFontNames = UIFont.fontNamesForFamilyName("Segoe UI")
//        print("\(testFontNames)")
        if let font = UIFont(name: "SegoeUI-Semibold", size: 18.0)
        {
            label.font = font
        }
        label.text = self.tableView(tableView, titleForHeaderInSection:section)
        //label.setTranslatesAutoresizingMaskIntoConstraints(false)
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
//            if let firstName = currentContact.firstName as? String
//            {
//                nameLabelText += firstName
//                if let lastName = currentContact.lastName as? String
//                {
//                    nameLabelText += " " + lastName
//                }
//            }
//            else  if let lastName = currentContact.lastName as? String
//            {
//                nameLabelText += lastName
//            }
            nameLabelText = currentContact.nameAndLastNameSpacedString()
            if let avatarImage = self.contactAvatars[currentContact.contactId]
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
            return contactCell
        case 1:
            contactCell.checkBox?.image = unCheckedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
            return contactCell
        default:
            let defaultCell = UITableViewCell(style: .Default, reuseIdentifier: "DummyCell") as UITableViewCell
            return defaultCell
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if !selectionEnabled
        {
            // current user is not creator of current element. We can`t assign or delete contacts.
            return
        }
        
        
        if let selectedContact = contactForIndexPath(indexPath)
        {
            let contactId = selectedContact.contactId
            guard contactId > 0 else {
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                return
            }
            
            guard let elementID = currentElement?.elementId else{
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                return
            }
            
            switch indexPath.section
            {
                case 0:
                    //unchecked contact from participants
                DataSource.sharedInstance.removeContact(contactId, fromElement: elementID, completion: { [weak self] (success, error) -> () in
                    if let weakSelf = self
                    {
                        if success
                        {
                            weakSelf.checkedContacts.removeAtIndex(indexPath.row)
                            weakSelf.contactsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
                            dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                                weakSelf.setUpInitialArrays()
                            })
                        }
                        else
                        {
                            weakSelf.showAlertWithTitle("Error", message: error!.localizedDescription, cancelButtonTitle: "Ok")
                        }
                    }
                })
                case 1:
                DataSource.sharedInstance.addContact(contactId, toElement:elementID, completion: { [weak self] (success, error) -> () in
                    if let weakSelf = self
                    {
                        if success
                        {
                            weakSelf.uncheckedContacts.removeAtIndex(indexPath.row)
                            weakSelf.contactsTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                            
                            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
                            dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                                weakSelf.setUpInitialArrays()
                            })
                        }
                        else
                        {
                            self!.showAlertWithTitle("Error", message: error!.localizedDescription, cancelButtonTitle: "Ok")
                        }
                    }
                })
                default: break
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
}
