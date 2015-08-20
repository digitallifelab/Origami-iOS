//
//  NewElementComposerViewController.swift
//  Origami
//
//  Created by CloudCraft on 03.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

enum CurrentEditingConfiguration:Int
{
    case Title
    case Details
    case None
}

class NewElementComposerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ButtonTapDelegate {

    var rootElementID:Int = 0
    var composingDelegate:ElementComposingDelegate?
    lazy var contactIDsToPass:Set<Int> = Set([Int]())
    var newElement:Element? {
        didSet{
            if let passIDs = newElement?.passWhomIDs
            {
                for number in passIDs
                {
                    contactIDsToPass.insert(number.integerValue)
                }
                //contactIDsToPass = Set(passIDs)
            }
            //println("Will pass to contact ids: \n \(contactIDsToPass)")
            table.reloadData()
        }
    }
    
    var contactImages = [String:UIImage]()
    //var transitionAnimator:FadeOpaqueAnimator?
    var allContacts = DataSource.sharedInstance.getMyContacts()
    
    var editingConfuguration:CurrentEditingConfiguration = .None
    
    var displayMode:DisplayMode = .Day {
        didSet{
            switch displayMode{
                case .Night:
                    self.toolbar.tintColor = UIColor.whiteColor()
                    self.toolbar.barTintColor = UIColor.blackColor()
                    self.view.backgroundColor = UIColor.blackColor()
                case .Day:
                    self.toolbar.tintColor = kDayNavigationBarBackgroundColor
                    self.toolbar.barTintColor = kWhiteColor
                    self.view.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    var editingStyle:ElementEditingStyle = .EditCurrent{
        didSet{
            if editingStyle == .AddNew
            {
                self.newElement = Element()
                self.newElement?.rootElementId = NSNumber(integer:self.rootElementID)
                self.newElement?.passWhomIDs = Array(self.contactIDsToPass)
            }
            configureBottomToolbar()
            table.reloadData()
        }
    }
    
    @IBOutlet var table: UITableView!
    @IBOutlet var toolbar:UIToolbar!
    
    //MARK: methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // table view delegate and data source are set in interface builder
        //transitionAnimator = FadeOpaqueAnimator()
        table.estimatedRowHeight = 80.0
        table.rowHeight = UITableViewAutomaticDimension
        let isNightMode = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        if isNightMode
        {
            self.displayMode = .Night
        }
        else
        {
            self.displayMode = .Day
        }
   
        if self.allContacts != nil
        {
            for lvContact in allContacts!
            {
                //set avatar image
                if let userName = lvContact.userName as? String
                {
                    DataSource.sharedInstance.loadAvatarForLoginName(userName, completion: {[weak self] (image) -> () in
                        if let weakSelf = self
                        {
                            if let avatar = image
                            {
                                weakSelf.contactImages[userName] = avatar
                            }
                            else
                            {
                                weakSelf.contactImages[userName] = UIImage(named: "icon-contacts")
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
    
    override func viewDidAppear(animated: Bool)
    {
        table.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableViewUpdates", name: "UpdateTextiewCell", object: nil)
        addObserversForKeyboard()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func configureBottomToolbar()
    {
        switch editingStyle
        {
        case .AddNew:
            var cancelBarButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonTap:")
            var flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            var doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneButtonTap:")
            toolbar.items = [cancelBarButton, flexibleSpace, doneBarButtonItem]
        case .EditCurrent:
            var cancelBarButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonTap:")
            var flexibleSpaceLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            var archiveBarButton = UIBarButtonItem(title: "Archive", style: UIBarButtonItemStyle.Plain, target: self, action: "archiveElementToolBarButtonTapped:")
            var flexibleSpaceCenter = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            var deleteBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteElementToolBarButtonTapped:")
            var flexibleSpaceRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            var doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneButtonTap:")
            toolbar.items = [cancelBarButton, flexibleSpaceLeft, archiveBarButton, flexibleSpaceCenter, deleteBarButton, flexibleSpaceRight, doneBarButtonItem]
        }
    }
    
    func addObserversForKeyboard()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardAppearance:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardAppearance:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func handleKeyboardAppearance(notification:NSNotification)
    {
        if let notifInfo = notification.userInfo
        {
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue()
            let keyboardHeight = keyboardFrame.size.height
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            var keyboardIsToShow = false
            if notification.name == UIKeyboardWillShowNotification
            {
                keyboardIsToShow = true
            }
        }
    }
    
    func stopTyping(tapRecognizer:UITapGestureRecognizer?)
    {
        if let cellTitle = table.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? NewElementTextViewCell
        {
            cellTitle.endEditing(true)
            if count(cellTitle.textView.text) > 0 && cellTitle.textView.text != newElement!.title as? String
            {
                var currentTextViewCellTitle = cellTitle.textView.text
                if currentTextViewCellTitle != cellTitle.defaultAttributedText.string
                {
                    newElement?.title = cellTitle.textView.text
                    println("Element title did change")
                }
                else
                {
                   println("Element title did not change")
                }
            }
        }
        
        if let descriptionCell = table.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? NewElementTextViewCell
        {
            descriptionCell.endEditing(true)
            if count(descriptionCell.textView.text) > 0 && descriptionCell.textView.text != newElement!.title as? String
            {
                newElement?.details = descriptionCell.textView.text
                println("Element Description did change")
            }
            else
            {
                println("Element Description did not change")
            }
        }
    }
    
    //MARK:UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 3 // no bunnon cells -//   //4 //title, description, buttons, contacts
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 2//3
        {
            return 1
        }
        else
        {
            return allContacts?.count ?? 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section
        {
            case 0:
//                if editingConfuguration == .Title || editingConfuguration == .None
//                {
                    var textViewCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! NewElementTextViewCell
                    configureTextViewCell(textViewCell, forIndexPath: indexPath)
                    return textViewCell
//                }
//                else
//                {
//                    var textCell = tableView.dequeueReusableCellWithIdentifier("newElementTextLabelCell", forIndexPath: indexPath) as! NewElementTextLabelCell
//                    configureTextLabelCell(textCell, forIndexPath:indexPath)
//                    return textCell
//                }
            
            case 1:
//                if editingConfuguration == .Details || editingConfuguration == .None
//                {
                    var textViewCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! NewElementTextViewCell
                    configureTextViewCell(textViewCell, forIndexPath: indexPath)
                    return textViewCell
//                }
//                else
//                {
//                    var textCell = tableView.dequeueReusableCellWithIdentifier("newElementTextLabelCell", forIndexPath: indexPath) as! NewElementTextLabelCell
//                    configureTextLabelCell(textCell, forIndexPath:indexPath)
//                    return textCell
//                }
            
            case 2:
                var contactCell = tableView.dequeueReusableCellWithIdentifier("ContactCheckerCell", forIndexPath: indexPath) as! ContactCheckerCell
                configureContactCell(contactCell, forIndexPath:indexPath)
                return contactCell
            default:
                return UITableViewCell(style: .Default, reuseIdentifier: "")
        }
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section < 2 { return 0.0 }
        return 50.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section < 2
        {
            return nil
        }
        
        //prepare view
        var view = UIView(frame: CGRectMake(0, 0, tableView.bounds.size.width, 50.0))
        view.backgroundColor = kWhiteColor
        view.opaque = true
        
        //prepare label
        let label = UILabel()
        label.textAlignment = NSTextAlignment.Center
        label.textColor = kDayCellBackgroundColor
        //        var testFontNames = UIFont.fontNamesForFamilyName("Segoe UI")
        //        println("\(testFontNames)")
        if let font = UIFont(name: "SegoeUI-Semibold", size: 18.0)
        {
            label.font = font
        }
        label.text = self.tableView(tableView, titleForHeaderInSection:section)
        label.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(label)
        
        //create constraints for label
        let centerXConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        
        let centerYConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        
        view.addConstraints([centerXConstraint, centerYConstraint])
        
        return view
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2
        {
//            if contactIDsToPass.isEmpty
//            {
                return "Team".localizedWithComment("")
//            }
//            else
//            {
//                return "\(contactIDsToPass.count)" +  ((contactIDsToPass.count > 1) ? " conatcts" : " contact")
//            }
        }
        
        return nil
    }
    
    //MARK:  Tools
//    func configureTextLabelCell(cell:NewElementTextLabelCell, forIndexPath indexPath:NSIndexPath)
//    {
//        if indexPath.section == 0
//        {
//            cell.isTitleCell = true
//            
//            if let title = newElement?.title as? String
//            {
//                let titleAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName:UIColor.lightGrayColor()]
//                cell.attributedText = NSAttributedString(string: title, attributes: titleAttributes)
//            }
//            else
//            {
//                let titleAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName:UIColor.lightGrayColor()]
//                cell.attributedText = NSAttributedString(string: "add title", attributes: titleAttributes)
//            }
//        }
//        else
//        {
//            cell.isTitleCell = false
//            if let description = newElement?.details as? String
//            {
//                if description != ""
//                {
//                    let descriptionAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 14)!, NSForegroundColorAttributeName:UIColor.lightGrayColor()]
//                    cell.attributedText = NSAttributedString(string: description, attributes: descriptionAttributes)
//                }
//                else
//                {
//                    let descriptionAttributes = [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()]
//                    cell.attributedText = NSAttributedString(string: "add description", attributes: descriptionAttributes)
//                }
//                
//            }
//            else
//            {
//                let descriptionAttributes = [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()]
//                cell.attributedText = NSAttributedString(string: "add description", attributes: descriptionAttributes)
//            }
//        }
//    }

    func configureTextViewCell(cell:NewElementTextViewCell, forIndexPath indexPath:NSIndexPath)
    {
        if indexPath.section == 0
        {
            cell.isTitleCell = true
            
            if let title = newElement?.title as? String
            {
                let titleAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName:UIColor.blackColor()]
                cell.attributedText = NSAttributedString(string: title, attributes: titleAttributes)
            }
            else
            {
                cell.attributedText = nil
                cell.textView.attributedText = nil
            }
        }
        else
        {
            cell.isTitleCell = false
            
            if let description = newElement?.details as? String
            {
                if description != ""
                {
                    let descriptionAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 14)!, NSForegroundColorAttributeName:UIColor.blackColor()]
                    cell.attributedText = NSAttributedString(string: description, attributes: descriptionAttributes)
                }
                else
                {
                    let descriptionAttributes = [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()]
                    cell.textView.attributedText = nil// NSAttributedString(string: "add description", attributes: descriptionAttributes)
                }
                
            }
            else
            {
                let descriptionAttributes = [NSFontAttributeName : UIFont(name: "Segoe UI", size: 14)!, NSForegroundColorAttributeName : UIColor.blackColor()]
                cell.textView.attributedText = nil// NSAttributedString(string: "add description", attributes: descriptionAttributes)
            }
        }
    }
    
    func configureContactCell(cell:ContactCheckerCell, forIndexPath indexPath:NSIndexPath)
    {
        if let lvContact = allContacts?[indexPath.row]
        {
            
            if let avatarImage = contactImages[lvContact.userName! as String]
            {
                cell.avatar.image = avatarImage
            }
            else
            {
                cell.avatar.image = UIImage(named: "icon-contacts")
            }
            //set name text
            var nameLabelText = ""
            if let firstName = lvContact.firstName as? String
            {
                nameLabelText += firstName
                if let lastName = lvContact.lastName as? String
                {
                    nameLabelText += " " + lastName
                }
            }
            else  if let lastName = lvContact.lastName as? String
            {
                nameLabelText += lastName
            }
            
            cell.nameLabel.text = nameLabelText
            
            //set proper checkbox image
            if contactIDsToPass.contains(lvContact.contactId!.integerValue)
            {
                cell.checkBox.image = checkedCheckboxImage
            }
            else
            {
                cell.checkBox.image = unCheckedCheckboxImage
            }
            
            cell.displayMode = self.displayMode
        }
    }
    
    func contactTappedAtIndexPath(indexPath: NSIndexPath)
    {
        if let lvContact = allContacts?[indexPath.row], lvContactIDInt = lvContact.contactId?.integerValue
        {            
            if self.contactIDsToPass.contains(lvContactIDInt)
            {
                self.contactIDsToPass.remove(lvContactIDInt)
            }
            else
            {
                self.contactIDsToPass.insert(lvContactIDInt)
            }
        }
        
        self.table.reloadData()
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue()) { [unowned self]() -> Void in
//            //self.table.reloadSections(NSIndexSet(index:indexPath.section), withRowAnimation: .None)
//            
//            //self.table.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: false)
//        }
    }
    
    //MARK: UITableVIewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.newElement == nil // we are creating new element
        {
            return
        }
        
        let titlePath = NSIndexPath(forRow: 0, inSection: 0)
        let detailsPath = NSIndexPath(forRow: 0, inSection: 1)
        
        if indexPath.section < 2//3
        {
            if indexPath.section == titlePath.section //tapped on title cell
            {
                switch editingConfuguration
                {
                case .None: //start editing title
                    fallthrough
                case .Details: //start editing title
                    editingConfuguration = .Title
                case .Title: // stop editing title
                    editingConfuguration = .None
                }
            }
            else if indexPath.section == detailsPath.section //tapped on details cell
            {
                switch editingConfuguration
                {
                case .None: //start editing details
                    fallthrough
                case .Title: //start editing details
                    editingConfuguration = .Details
                case .Details: // stop editing details
                    editingConfuguration = .None
                }
            }
            
            stopTyping(nil)
        }
        else
        {
            editingConfuguration = .None
            contactTappedAtIndexPath(indexPath)
            return
        }
        
        
        tableView.reloadRowsAtIndexPaths([titlePath, detailsPath], withRowAnimation: .None)
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.stopTyping(nil)
    }
    
    //MARK: ButtonTapDelegate
    func didTapOnButton(button: UIButton) {
        
    }
    
    
    func reloadTableViewUpdates() // this needed to make table view cell grow automatically.
    {
        table.beginUpdates()
        table.endUpdates()
        
        //TODO: scroll up if cursor is lower, than keyboard top side
    }
    
    func cancelButtonTap(sender:AnyObject?)
    {
        composingDelegate?.newElementComposerWantsToCancel(self)
    }
    
    func doneButtonTap(sender:AnyObject?)
    {
        if let anElement = self.newElement, let currentTitle = newElement?.title as? String
        {
            if count(currentTitle) < 1
            {
                cancelButtonTap(sender)
                return
            }
            else if currentTitle == "add title"
            {
                cancelButtonTap(sender)
                return
            }
            
            if anElement.details == nil
            {
                anElement.details = ""
            }
           
            if !contactIDsToPass.isEmpty
            {
                if self.editingStyle == .AddNew
                {
                    var contactIDs = Array(contactIDsToPass)
                    contactIDs.sort(>)
                    anElement.passWhomIDs = contactIDs
                }
                else //EditCurrent
                {
                    var contactIDs = Array(contactIDsToPass)
                    contactIDs.sort(>)
                    anElement.passWhomIDs = contactIDs
                }
            }
            else
            {
                anElement.passWhomIDs.removeAll(keepCapacity: false)
            }
            
            anElement.rootElementId = NSNumber(integer:  self.rootElementID)
            
            composingDelegate?.newElementComposer(self, finishedCreatingNewElement: anElement)
        }
        else
        {
            cancelButtonTap(sender)
        }
    }
    
    func deleteElementToolBarButtonTapped(sender:UIButton?)
    {
        var alertController = UIAlertController(title: "Warning", message: "You are about to delete current element and all it`s subordinates.", preferredStyle: .Alert)
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default ) { [unowned self](alertAction) -> Void in
            
            self.dismissViewControllerAnimated(true, completion: {[unowned self] () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(kElementActionButtonPressedNotification, object: self, userInfo: ["actionButtonIndex" : ActionButtonCellType.Delete.rawValue])
            })
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (alertAction) -> Void in
            
        }
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    
    }
    
    func archiveElementToolBarButtonTapped(sender:UIButton?)
    {
        
    }
    
}// class end


