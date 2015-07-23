//
//  NewElementComposerViewController.swift
//  Origami
//
//  Created by CloudCraft on 03.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class NewElementComposerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ButtonTapDelegate, UIViewControllerTransitioningDelegate, TextEditingDelegate {

    var rootElementID:Int = 0
    var composingDelegate:ElementComposingDelegate?
    lazy var contactIDsToPass:Set<Int> = Set([Int]())
    var newElement = Element()
    var transitionAnimator:FadeOpaqueAnimator?
    let allContacts = DataSource.sharedInstance.getAllContacts()
    
    
    
    @IBOutlet weak var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // table view delegate and data source are set in interface builder
        transitionAnimator = FadeOpaqueAnimator()
        table.estimatedRowHeight = 50.0
        table.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        table.reloadData()
    }
    
    //MARK:UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4 //title, description, buttons, contacts
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < 3
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
            case 1:
                fallthrough
            case 0:
                var textCell = tableView.dequeueReusableCellWithIdentifier("newElementTextLabelCell", forIndexPath: indexPath) as! NewElementTextLabelCell
                configureTextCell(textCell, forIndexPath:indexPath)
                return textCell
            case 2:
                var buttonsCell = tableView.dequeueReusableCellWithIdentifier("ActionButtonsCell", forIndexPath: indexPath) as! ElementDashboardActionButtonsCell
                buttonsCell.actionButtonDelegate = self
                return buttonsCell
            case 3:
                var contactCell = tableView.dequeueReusableCellWithIdentifier("ContactCheckerCell", forIndexPath: indexPath) as! ContactCheckerCell
                configureContactCell(contactCell, forIndexPath:indexPath)
                return contactCell
            default:
                return UITableViewCell(style: .Default, reuseIdentifier: "")
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 3
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
    func configureTextCell(cell:NewElementTextLabelCell, forIndexPath indexPath:NSIndexPath)
    {
        if indexPath.section == 0
        {
            cell.isTitleCell = true
            
            if let title = newElement.title as? String
            {
                let titleAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName:UIColor.blackColor()]
                cell.attributedText = NSAttributedString(string: title, attributes: titleAttributes)
            }
        }
        else
        {
            cell.isTitleCell = false
            if let description = newElement.details as? String
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
    }
    
    func configureButtonsCell(cell:ElementDashboardActionButtonsCell)
    {
        
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
            if contactIDsToPass.contains(lvContact.contactId!.integerValue)
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
                if self.contactIDsToPass.contains(lvContact.contactId!.integerValue)
                {
                    self.contactIDsToPass.remove(lvContact.contactId!.integerValue)
                }
                else
                {
                    self.contactIDsToPass.insert(lvContact.contactId!.integerValue)
                }
                //self.table.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
                self.table.reloadSections(NSIndexSet(index:indexPath.section), withRowAnimation: .None)
            }
        }
    }
    
    //MARK: UITableVIewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section < 3
        {
            if indexPath.section == 0
            {
                startEditingElementText(true) //edit title
            }
            if indexPath.section == 1
            {
                startEditingElementText(false) //edit description
            }
        }
        else
        {
            contactTappedAtIndexPath(indexPath)
            
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    //MARK: ButtonTapDelegate
    func didTapOnButton(button: UIButton) {
        
    }
    
    //MARK: TextEditingDelegate
    func textEditorDidCancel(editor:AnyObject)
    {
        if let viewController = editor as? UIViewController
        {
            viewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func textEditor(editor: AnyObject, wantsToSubmitNewText newText:String)
    {
        if let textEditor = editor as? SimpleTextEditorVC
        {
            var reloadTitleCell = false
            if textEditor.isEditingElementTitle
            {
                newElement.title = newText
                reloadTitleCell = true
            }
            else
            {
                newElement.details = newText
            }
            
            textEditor.dismissViewControllerAnimated(true, completion: {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.table.reloadSections(NSIndexSet(index:(reloadTitleCell) ? 0 : 1), withRowAnimation: .Fade)
                }
            })
        }
    }
    
    //MARK: UIViewControllerTransitioningDelegate
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator?.transitionDirection = .FadeIn
        return transitionAnimator
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator?.transitionDirection = .FadeOut
        return transitionAnimator
    }
    
    
    //MARK Modal View Controler
    func startEditingElementText(isTitle:Bool)
    {
        
        //self.performSegueWithIdentifier("ShowTextEditing", sender: isTitle)
        let storyBoard = self.storyboard
        if let textEditorVC = storyboard!.instantiateViewControllerWithIdentifier("SimpleTextEditor") as? SimpleTextEditorVC
        {
            textEditorVC.isEditingElementTitle = isTitle
            textEditorVC.editingDelegate = self
            textEditorVC.modalPresentationStyle = .Custom
            textEditorVC.transitioningDelegate = self
            
            self.presentViewController(textEditorVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtonTap(sender:UIButton)
    {
        composingDelegate?.newElementComposerWantsToCancel(self)
    }
    
    @IBAction func doneButtonTap(sender:UIButton)
    {
        if newElement.title != nil && newElement.details != nil
        {
            if !contactIDsToPass.isEmpty
            {
                var contactIDs = Array(contactIDsToPass)
                contactIDs.sort(>)
                newElement.passWhomIDs = contactIDs
            }
            if rootElementID > 0
            {
                newElement.rootElementId = NSNumber(integer: rootElementID)
            }
            composingDelegate?.newElementComposer(self, finishedCreatingNewElement: newElement)
        }
        else
        {
            cancelButtonTap(sender)
        }
    }
    
}
