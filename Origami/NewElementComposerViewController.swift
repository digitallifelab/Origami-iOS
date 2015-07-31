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

class NewElementComposerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ButtonTapDelegate/*, TextEditingDelegate*/ {

    var rootElementID:Int?
    var composingDelegate:ElementComposingDelegate?
    lazy var contactIDsToPass:Set<Int> = Set([Int]())
    var newElement:Element? {
        didSet{
            if let passIDs = newElement?.passWhomIDs
            {
                contactIDsToPass = Set(passIDs)
            }
            table.reloadData()
        }
    }
    //var transitionAnimator:FadeOpaqueAnimator?
    var allContacts = DataSource.sharedInstance.getAllContacts()
    
    var editingConfuguration:CurrentEditingConfiguration = .None
    
    var editingStyle:ElementEditingStyle = .EditCurrent{
        didSet{
            if editingStyle == .AddNew
            {
                self.newElement = Element()
                self.newElement?.rootElementId = self.rootElementID
                self.newElement?.passWhomIDs = Array(self.contactIDsToPass)
            }
            configureBottomToolbar()
        }
    }
    
    @IBOutlet var table: UITableView!
    @IBOutlet var toolbar:UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // table view delegate and data source are set in interface builder
        //transitionAnimator = FadeOpaqueAnimator()
        table.estimatedRowHeight = 80.0
        table.rowHeight = UITableViewAutomaticDimension
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool)
    {
        table.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableViewUpdates", name: "UpdateTextiewCell", object: nil)
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
                if editingConfuguration == .Title
                {
                    var textViewCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! NewElementTextViewCell
                    configureTextViewCell(textViewCell, forIndexPath: indexPath)
                    return textViewCell
                }
                else
                {
                    var textCell = tableView.dequeueReusableCellWithIdentifier("newElementTextLabelCell", forIndexPath: indexPath) as! NewElementTextLabelCell
                    configureTextLabelCell(textCell, forIndexPath:indexPath)
                    return textCell
                }
            
            case 1:
                if editingConfuguration == .Details
                {
                    var textViewCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! NewElementTextViewCell
                    configureTextViewCell(textViewCell, forIndexPath: indexPath)
                    return textViewCell
                }
                else
                {
                    var textCell = tableView.dequeueReusableCellWithIdentifier("newElementTextLabelCell", forIndexPath: indexPath) as! NewElementTextLabelCell
                    configureTextLabelCell(textCell, forIndexPath:indexPath)
                    return textCell
                }
            
            case 2:
                var contactCell = tableView.dequeueReusableCellWithIdentifier("ContactCheckerCell", forIndexPath: indexPath) as! ContactCheckerCell
                configureContactCell(contactCell, forIndexPath:indexPath)
                return contactCell
            default:
                return UITableViewCell(style: .Default, reuseIdentifier: "")
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2
        {
            if contactIDsToPass.isEmpty
            {
                return "Add Contacts"
            }
            else
            {
                return "\(contactIDsToPass.count)" +  ((contactIDsToPass.count > 1) ? " conatcts" : " contact")
            }
        }
        
        return nil
    }
    
    //MARK:  Tools
    func configureTextLabelCell(cell:NewElementTextLabelCell, forIndexPath indexPath:NSIndexPath)
    {
        if indexPath.section == 0
        {
            cell.isTitleCell = true
            
            if let title = newElement?.title as? String
            {
                let titleAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName:UIColor.blackColor()]
                cell.attributedText = NSAttributedString(string: title, attributes: titleAttributes)
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
                    cell.attributedText = NSAttributedString(string: "add description", attributes: descriptionAttributes)
                }
                
            }
            else
            {
                let descriptionAttributes = [NSFontAttributeName : UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName : UIColor.lightGrayColor()]
                cell.attributedText = NSAttributedString(string: "add description", attributes: descriptionAttributes)
            }
        }
    }

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
                    cell.attributedText = NSAttributedString(string: "add description", attributes: descriptionAttributes)
                }
                
            }
            else
            {
                let descriptionAttributes = [NSFontAttributeName : UIFont(name: "Segoe UI", size: 14)!, NSForegroundColorAttributeName : UIColor.blackColor()]
                cell.attributedText = nil// NSAttributedString(string: "add description", attributes: descriptionAttributes)
            }
        }
    }
    
    func configureContactCell(cell:ContactCheckerCell, forIndexPath indexPath:NSIndexPath)
    {
        if let lvContact = allContacts?[indexPath.row]
        {
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
            if contactIDsToPass.contains(lvContact.contactId!)
            {
                cell.checkBox.image = checkedCheckboxImage
            }
            else
            {
                cell.checkBox.image = unCheckedCheckboxImage
            }
            
            //set avatar image
            if let avatarData = DataSource.sharedInstance.getAvatarDataForContactUserName(lvContact.userName! as String)
            {
                cell.avatar.image = UIImage(data:avatarData)
            }
        }
    }
    
    func contactTappedAtIndexPath(indexPath: NSIndexPath)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue()) { [unowned self]() -> Void in
            if let lvContact = self.allContacts?[indexPath.row]
            {
                if self.contactIDsToPass.contains(lvContact.contactId!)
                {
                    self.contactIDsToPass.remove(lvContact.contactId!)
                }
                else
                {
                    self.contactIDsToPass.insert(lvContact.contactId!)
                }
                //self.table.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                self.table.reloadSections(NSIndexSet(index:indexPath.section), withRowAnimation: .None)
            }
        }
    }
    
    //MARK: UITableVIewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.newElement == nil // we ara for
        {
            
        }
        if indexPath.section < 2//3
        {
            if let cell = self.table.cellForRowAtIndexPath(indexPath) as? NewElementTextLabelCell
            {
                if cell.isTitleCell
                {
                    editingConfuguration = .Title
                }
                else
                {
                    editingConfuguration = .Details
                }
            }
            else if let cell = self.table.cellForRowAtIndexPath(indexPath) as? NewElementTextViewCell
            {
                if cell.isTitleCell
                {
                    self.newElement?.title = cell.textView.text //when we switch off editing in the title section - assign current value to our editing element
                    editingConfuguration = .None
                }
                else
                {
                    self.newElement?.details = cell.textView.text //when we switch off editing in the details section - assign current value to our editing element
                    editingConfuguration = .None
                }
            }
        }
        else
        {
           
            editingConfuguration = .None
            contactTappedAtIndexPath(indexPath)
        }
        
        let indexpathForDetailsCell = NSIndexPath(forRow: 0, inSection: 1)
        if let detailsCell = table.cellForRowAtIndexPath(indexpathForDetailsCell) as? NewElementTextViewCell
        {
            self.newElement?.details = detailsCell.textView.text //when we switch off editing in the details section - assign current value to our editing element
        }
        let indexpathForTitleCell = NSIndexPath(forRow: 0, inSection: 0)
        if let titleCell = table.cellForRowAtIndexPath(indexpathForTitleCell) as? NewElementTextViewCell
        {
            self.newElement?.title = titleCell.textView.text //when we switch off editing in the details section - assign current value to our editing element
        }
        
        
        
        let titlePath = NSIndexPath(forRow: 0, inSection: 0)
        let detailsPath = NSIndexPath(forRow: 0, inSection: 1)
        tableView.reloadRowsAtIndexPaths([titlePath, detailsPath], withRowAnimation: .None)
        
        //tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
//    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
//    }
    
    //MARK: ButtonTapDelegate
    func didTapOnButton(button: UIButton) {
        
    }
    
    //MARK: TextEditingDelegate
//    func textEditorDidCancel(editor:AnyObject)
//    {
//        if let viewController = editor as? UIViewController
//        {
//            viewController.dismissViewControllerAnimated(true, completion: nil)
//        }
//    }
//    
//    func textEditor(editor: AnyObject, wantsToSubmitNewText newText:String)
//    {
//        if let textEditor = editor as? SimpleTextEditorVC
//        {
//            var reloadTitleCell = false
//            if textEditor.isEditingElementTitle
//            {
//                newElement?.title = newText
//                reloadTitleCell = true
//            }
//            else
//            {
//                newElement?.details = newText
//            }
//            
//            textEditor.dismissViewControllerAnimated(true, completion: {[weak self] () -> Void in
//                if let weakSelf = self
//                {
//                    weakSelf.table.reloadSections(NSIndexSet(index:(reloadTitleCell) ? 0 : 1), withRowAnimation: .Fade)
//                }
//            })
//        }
//    }
    
    
    func reloadTableViewUpdates() // this needed to make table view cell grow automatically.
    {
        table.beginUpdates()
        table.endUpdates()
    }
    
    func cancelButtonTap(sender:AnyObject?)
    {
        composingDelegate?.newElementComposerWantsToCancel(self)
    }
    
    func doneButtonTap(sender:AnyObject?)
    {
        if let anElement = self.newElement, let currentTitle = newElement?.title as? String
        {
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
                
            }
           
            if let rootID = self.rootElementID
            {
                anElement.rootElementId = rootID
            }
            composingDelegate?.newElementComposer(self, finishedCreatingNewElement: anElement)
        }
        else
        {
            cancelButtonTap(sender)
        }
    }
    
    func deleteElementToolBarButtonTapped(sender:UIButton?)
    {
        
    }
    
    func archiveElementToolBarButtonTapped(sender:UIButton?)
    {
        
    }
    
    
    
    
}// class end


