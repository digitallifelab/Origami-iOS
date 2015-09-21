//
//  ElementTaskStarterVC.swift
//  Origami
//
//  Created by CloudCraft on 21.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementTaskStarterVC: UIViewController , UITableViewDelegate, UITableViewDataSource {

    weak var currentElement:Element?
    
    @IBOutlet weak var datePicker:UIDatePicker?
    @IBOutlet weak var participantsTable:UITableView?
    
    var doneButton:UIBarButtonItem?
    var remindDate:NSDate?
    var responsibleUserId:NSNumber?
    var myContacts:[Contact]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myContacts = DataSource.sharedInstance.getMyContacts()
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let contacts = myContacts
        {
            if !contacts.isEmpty
            {
                participantsTable?.delegate = self
                participantsTable?.dataSource = self
                participantsTable?.reloadData()
            }
        }
        
    }
    

    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    //MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contacts = myContacts
        {
            return contacts.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let contactCell = tableView.dequeueReusableCellWithIdentifier("", forIndexPath: indexPath) as? ContactCheckerCell
        {
            return contactCell
        }
        
        return UITableViewCell(style: .Default, reuseIdentifier: "DefaultCell")
    }
    
    //MARK: ----
    func taskDonePressed(sender:AnyObject)
    {
        
    }
   

}
