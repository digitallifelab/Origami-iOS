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
    @IBOutlet var topNavBarBackgroundView:UIView!
    var currentElement:Element?
    var contacts:[Contact]?
    var checkedContacts:[Contact] = [Contact]()
    var uncheckedContacts:[Contact] = [Contact]()
    var selectionEnabled = false
    var displayMode:DisplayMode = .Day
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentElement!.creatorId.integerValue == DataSource.sharedInstance.user!.userId!.integerValue
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
                    var allContactsSet:Set<Contact> = Set(contacts!)
                    
                    checkedContacts = contacts!.filter({ (lvContact) -> Bool in
                        let contains = passWhomIDsSet.contains(lvContact.contactId!)
                        return contains
                    })
                    //sort alphabeticaly
                    sortContactsAlphabeticaly(&checkedContacts)
                    
                    var uncheckedContactsSet = allContactsSet.subtract(Set(checkedContacts))
                    uncheckedContacts = Array(uncheckedContactsSet)
                    
                    sortContactsAlphabeticaly(&uncheckedContacts)
                }
                else
                {
                    uncheckedContacts += contacts!
                    sortContactsAlphabeticaly(&uncheckedContacts)
                }
            }
            
        }
        
        contactsTable.delegate = self
        contactsTable.dataSource = self
        contactsTable.reloadData()
    }
    
    func sortContactsAlphabeticaly(inout contactArray:[Contact])
    {
        contactArray.sort({ (contact1, contact2) -> Bool in
            if let firstName1 = contact1.firstName as? String, firstName2 = contact2.firstName as? String
            {
                return firstName1 >= firstName2
            }
            
            if let lastName1 = contact1.lastName as? String, lastName2 = contact2.lastName as? String
            {
                return lastName1 > lastName2
            }
            
            if let userName1 = contact1.userName as? String , userName2 = contact2.userName as? String
            {
                return userName1 >= userName2
            }
            // if nothing found
            return true
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
            return "participating".localizedWithComment("")
        case 1:
            return "add participants".localizedWithComment("")
            
        default : return nil
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
      
        var currentContact = contactForIndexPath(indexPath)
        var nameLabelText = ""
        
        if currentContact != nil
        {
            if let firstName = currentContact!.firstName as? String
            {
                nameLabelText += firstName
                if let lastName = currentContact!.lastName as? String
                {
                    nameLabelText += " " + lastName
                }
            }
            else  if let lastName = currentContact!.lastName as? String
            {
                nameLabelText += lastName
            }
        }
        var contactCell = tableView.dequeueReusableCellWithIdentifier("ContactCheckerCell", forIndexPath: indexPath) as! ContactCheckerCell
        contactCell.nameLabel.text = nameLabelText
        contactCell.displayMode = self.displayMode
        switch indexPath.section
        {
        case 0:
            contactCell.checkBox.image = checkedCheckboxImage
            return contactCell
        case 1:
            contactCell.checkBox.image = unCheckedCheckboxImage
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
            switch indexPath.section
            {
                case 0:
                    //unchecked contact from participants
                DataSource.sharedInstance.removeContact(selectedContact.contactId!.integerValue, fromElement: currentElement!.elementId!.integerValue, completion: { [weak self] (success, error) -> () in
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
                DataSource.sharedInstance.addContact(selectedContact.contactId!.integerValue, toElement: currentElement!.elementId!.integerValue, completion: { [weak self] (success, error) -> () in
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
    
    //MARK: Alert
    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        alertController.addAction(closeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: Appearance
    func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        if nightModeOn
        {
            self.view.backgroundColor = UIColor.blackColor()
            self.topNavBarBackgroundView.backgroundColor = UIColor.blackColor()
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar
            self.tabBarController?.tabBar.tintColor = kWhiteColor
            self.tabBarController?.tabBar.backgroundColor = UIColor.blackColor()
            self.displayMode = .Night
        }
        else
        {
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
            self.topNavBarBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
            self.tabBarController?.tabBar.tintColor = kWhiteColor
            self.tabBarController?.tabBar.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.8)
            self.displayMode = .Day
        }
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        
        //TODO: switch message cells night-day modes
        // self.collectionSource?.turnNightModeOn(nightModeOn)
        // self.collectionDashboard.reloadData()
        
    }
}
