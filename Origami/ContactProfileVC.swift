//
//  ContactProfileVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

import CoreData

class ContactProfileVC: UIViewController , UITableViewDelegate, UITableViewDataSource {

    var contactManagedId:NSManagedObjectID?
    var contact:DBContact?
    
    let titleInfoKey = "title"
    let detailsInfoKey = "details"
    var avatarImage:UIImage?
    
    @IBOutlet weak var tableView:UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let managedId = contactManagedId
        {
            DataSource.sharedInstance.localDatadaseHandler?.readContactByManagedObjectID(managedId) {[weak self] (foundContact, error) in
                if let weakSelf = self
                {
                    if let lvContact = foundContact
                    {
                        weakSelf.contact = lvContact
                        weakSelf.refreshTable(nil)
                    }
                }
            }
        }
        
        tableView?.delegate = self
        tableView?.dataSource = self
        
        setupToolbarHomeButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        avatarImage = nil
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func setupToolbarHomeButton()
    {
        let homeButton = UIButton(type: .System)
     
        homeButton.setImage(UIImage(named:kHomeButtonImageName)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    
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

    //MARK: - 
    func refreshTable(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo, userId = userInfo["userId"] as? Int
        {
            if let contactId = self.contact?.contactId?.integerValue
            {
                if contactId == userId
                {
                    print("removed ContactProfileVC  from Observing User Avatar Did finish loading")
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: kAvatarDidFinishDownloadingNotification, object: nil)
                }
            }
        }
        
        if let contactLoginName = self.contact?.userName , contactId = contact?.contactId?.integerValue
        {
            self.avatarImage = DataSource.sharedInstance.getAvatarForUserId(contactId)
            
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.tableView?.reloadData()
                }
            })
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                
                DataSource.sharedInstance.loadAvatarFromDiscForLoginName(contactLoginName, completion: {[weak self] (image, error) -> () in
                    if let avatarImage = image, weakSelf = self
                    {
                        weakSelf.avatarImage = avatarImage
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            weakSelf.tableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
                        })
                    }
                    else
                    {
                        print(" Did not load avatar for contact.")
                        print(".. starting loading from server..")
                        if let weakSelf = self
                        {
                            NSNotificationCenter.defaultCenter().removeObserver(weakSelf, name: kAvatarDidFinishDownloadingNotification, object: nil)
                            
                            NSNotificationCenter.defaultCenter().addObserver(weakSelf, selector: "refreshTable:", name: kAvatarDidFinishDownloadingNotification, object: nil)
                        }
                        
                        DataSource.sharedInstance.startLoadingAvatarForUserName((name: contactLoginName, id: contactId))
                    }
                    
                })
            })
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentRow = indexPath.row
        switch currentRow
        {
        case 0: // avatar
            return 117.0
        case 1..<10: // name, email, phone, mood, so on
            return 60.0
        default:
            return 0.0
        }
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        return returnCellForIndexPath(indexPath) ?? UITableViewCell(style: .Default, reuseIdentifier: "Cell")
    }
    
    private func returnCellForIndexPath(indexPath:NSIndexPath) -> UITableViewCell?
    {
        let currentRow = indexPath.row
        switch currentRow
        {
        case 0:
            let avatarCell = tableView?.dequeueReusableCellWithIdentifier("ContactProfileAvatarCell", forIndexPath: indexPath) as! ContactProfileAvatarCell
            if let contact = self.contact
            {
                avatarCell.favourite = contact.favorite!.boolValue
            }
            avatarCell.avatar?.image = self.avatarImage
            return avatarCell
        default:
            let textCell = tableView?.dequeueReusableCellWithIdentifier("ContactProfileTextInfoCell", forIndexPath: indexPath) as! ContactProfileTextInfoCell
            if let info = textInfoForIndexPath(indexPath)
            {
                textCell.titleTextLabel?.text = info[titleInfoKey]
                textCell.mainInfoTextLabel?.text = info[detailsInfoKey]
            }
            return textCell
        }
    }
    
    private func textInfoForIndexPath(indexPath:NSIndexPath) -> [String:String]?
    {
        if let contact = self.contact
        {
            var toReturnInfo = [String:String]()
            let currentRow = indexPath.row
            switch currentRow
            {
                case 1:
                    toReturnInfo[titleInfoKey] = "mood".localizedWithComment("")
                    if let contactMood = contact.mood// as? String
                    {
                        toReturnInfo[detailsInfoKey] = contactMood
                    }
                case 2:
                    toReturnInfo[titleInfoKey] = "name".localizedWithComment("")
                    if let nameAndLastNameSingleString = contact.nameAndLastNameSpacedString()
                    {
                        toReturnInfo[detailsInfoKey] = nameAndLastNameSingleString
                    }
                case 3:
                    toReturnInfo[titleInfoKey] = "email".localizedWithComment("")
                    
                    toReturnInfo[detailsInfoKey] = (contact.userName!.isEmpty) ? nil : contact.userName
                
                case 4:
                    toReturnInfo[titleInfoKey] = "phone".localizedWithComment("")
                    if let userPhone = contact.phone
                    {
                        if !userPhone.characters.isEmpty
                        {
                            toReturnInfo[detailsInfoKey] = userPhone
                        }
                    }
                case 5:
                    toReturnInfo[titleInfoKey] = "age".localizedWithComment("")
                    if let aBirthDay = contact.birthdayString()
                    {
                        toReturnInfo[detailsInfoKey] = aBirthDay
                    }
                case 6:
                    toReturnInfo[titleInfoKey] = "language".localizedWithComment("")
                    if let aLang = languageById(contact.language?.integerValue)
                    {
                        toReturnInfo[detailsInfoKey] = aLang.languageName
                    }
                case 7:
                    toReturnInfo[titleInfoKey] = "country".localizedWithComment("")
                    if let aCountry = countryById( contact.country?.integerValue)
                    {
                        toReturnInfo[detailsInfoKey] = aCountry.countryName
                    }
                case 8:
                    toReturnInfo[titleInfoKey] = "sex".localizedWithComment("")
                    if let aGender = contact.sex
                    {
                        let female = aGender.boolValue
                        if female
                        {
                            toReturnInfo[detailsInfoKey] = "female".localizedWithComment("")
                        }
                        else
                        {
                            toReturnInfo[detailsInfoKey] = "male".localizedWithComment("")
                        }
                    }
                
                default :
                    break
            }
            return toReturnInfo
            
        }
        return nil
    }
    
    func languageById(langId:Int?) -> Language?
    {
        guard let languageId = langId else
        {
            return nil
        }
        
        for aLanguage in DataSource.sharedInstance.languages
        {
            if aLanguage.languageId == languageId
            {
                return aLanguage
            }
        }
        return nil
    }
    
    func countryById(countryId:Int?) -> Country?
    {
        guard let lvCountryId = countryId else
        {
            return nil
        }
        
    
        for aCountry in DataSource.sharedInstance.countries
        {
            if aCountry.countryId == lvCountryId
            {
                return aCountry
            }
        }
        
        return nil
    }
    
}
