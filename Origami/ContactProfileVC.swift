//
//  ContactProfileVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactProfileVC: UIViewController , UITableViewDelegate, UITableViewDataSource {

    var contact:Contact?
    
    let titleInfoKey = "title"
    let detailsInfoKey = "details"
    var avatarImage:UIImage?
    @IBOutlet weak var tableView:UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let contactLoginName = self.contact?.userName as? String
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                DataSource.sharedInstance.loadAvatarForLoginName(contactLoginName, completion: { [weak self](image) -> () in
                    if let avatarImage = image, weakSelf = self
                    {
                        println(" Loaded avatar for contact.")
                        weakSelf.avatarImage = avatarImage
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            weakSelf.tableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
                        })
                    }
                    else
                    {
                        println(" Did not load avatar for contact.")
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                })
            })
            
        }
        
        tableView?.delegate = self
        tableView?.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
//        if let existContact = self.contact
//        {
//            println("\(self.contact!.toDictionary().description)")
//        }
    }
    
    

    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentRow = indexPath.row
        switch currentRow
        {
        case 0: // avatar
            return 117.0
        case 1..<6: // name, email, phone, mood, so on
            return 60.0
        default:
            return 0.0
        }
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
                avatarCell.favourite = contact.isFavourite.boolValue
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
                toReturnInfo[titleInfoKey] = "name".localizedWithComment("")
                toReturnInfo[detailsInfoKey] = contactNameStringFromContact(contact)
                return toReturnInfo
            case 2:
            if let email = contact.userName as? String
            {
                toReturnInfo[titleInfoKey] = "email".localizedWithComment("")
                toReturnInfo[detailsInfoKey] = email
                return toReturnInfo
            }
            case 3:
                if let userPhone = contact.phone as? String
                {
                    toReturnInfo[titleInfoKey] = "phone".localizedWithComment("")
                    toReturnInfo[detailsInfoKey] = userPhone
                    return toReturnInfo
                }
            default :
                break
            }
        }
        return nil
    }
    
    private func contactNameStringFromContact(contact:Contact) -> String
    {
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
        
        return nameString
    }
}
