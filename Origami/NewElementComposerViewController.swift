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

struct ContactInfo
{
    var contactName:String = ""
    var contactId:Int = 0
}

class NewElementComposerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIAlertViewDelegate {

    var currentElementId:Int = 0
    var rootElementID:Int = 0
        {
        didSet{
            print("\n -> NewElementComposerViewController,  rootElementId: \(rootElementID)\n")
        }
    }
    var currentElementParticipants:Set<Int> = Set<Int>()
    
    weak var composingDelegate:ElementComposingDelegate?
    
    var inMemoryElement:Element?
    
    var contactInfos:[ContactInfo]?
    private let bgQueue = NSOperationQueue()
    
    private var editingConfuguration:CurrentEditingConfiguration = .None{
        didSet{
            var configString = ".None"
            if editingConfuguration == .Title
            {
                configString = ".Title"
            }
            if editingConfuguration == .Details
            {
                configString = ".Details"
            }
            print(" ->CurrentEditingConfiguration:  \(configString)")
        }
    }
    
    var displayMode:DisplayMode = .Day {
        didSet{
            switch displayMode{
                case .Night:
                    self.view.backgroundColor = UIColor.blackColor()
                case .Day:
                    self.view.backgroundColor = UIColor.whiteColor()
            }
        }
    }
    
    var editingStyle:ElementEditingStyle = .AddNew
    
    var currentElementType:NewElementCreationType = .None
    
    var textViews = [NSIndexPath:UITextView]()
    
    @IBOutlet weak var table:UITableView?
    
    //MARK: - methods
    override func viewDidLoad() {
        super.viewDidLoad()

        table?.estimatedRowHeight = 80.0
        table?.rowHeight = UITableViewAutomaticDimension
        
        let isNightMode = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        if isNightMode
        {
            self.displayMode = .Night
        }
        else
        {
            self.displayMode = .Day
        }
   
        print("---- viewDidLoad :->  \n ContactIdsToPass: \(currentElementParticipants)")
        
        
        let contactsBlockOp = NSBlockOperation() { _ in
            DataSource.sharedInstance.localDatadaseHandler?.readAllMyContacts() { [weak self] (dbContacts) -> () in
                if let foundContacts = dbContacts, weakSelf = self
                {
                    var contactInfos = [ContactInfo]()
                    for aDbContact in foundContacts
                    {
                        guard let contactId = aDbContact.contactId?.integerValue else
                        {
                            continue
                        }
                        
                        var lvInfo = ContactInfo(contactName: "", contactId: contactId)
                        
                        if let name = aDbContact.nameAndLastNameSpacedString()
                        {
                            lvInfo.contactName = name
                        }
                        contactInfos.append(lvInfo)
                    }
                    
                    if !contactInfos.isEmpty
                    {
                        weakSelf.contactInfos = contactInfos
                    }
                }
            }
        }
        
        let passWhomIdsForElementOp = NSBlockOperation() { [weak self] _ in
            
            if let weakSelf = self
            {
                let dispatchGroup = dispatch_group_create()
                
                if weakSelf.currentElementId > 0
                {
                    dispatch_group_enter(dispatchGroup)
                    
                    DataSource.sharedInstance.loadPassWhomIdsForElement(weakSelf.currentElementId, comlpetion: {[weak self] (finished) -> () in
                        if let weakSelf = self, participantsForElement = DataSource.sharedInstance.participantIDsForElement[weakSelf.currentElementId]
                        {
                            weakSelf.currentElementParticipants = participantsForElement
                        }
                        dispatch_group_leave(dispatchGroup)
                    })
                }
                
                if weakSelf.rootElementID > 0
                {
                    dispatch_group_enter(dispatchGroup)
                    let rootId = weakSelf.rootElementID
                    DataSource.sharedInstance.loadPassWhomIdsForElement(rootId) { [weak self] (finished) -> () in
                        if let weakSelf = self, rootParticipants = DataSource.sharedInstance.participantIDsForElement[rootId]
                        {
                            print(" \(weakSelf.editingStyle) found participants for root element: \(rootParticipants)")
                        }
                        dispatch_group_leave(dispatchGroup)
                    }
                }
                
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 10.0))
                
                dispatch_group_wait(dispatchGroup, timeout)
                print(" -> finished passWhomIdsForElementOp \n")
            }
        }
        
        let afterPassWhomIdsForElementOp = NSBlockOperation() {[weak self] _ in
            print(" -> Strated afterPassWhomIdsForElementOp\n")
            guard let weakSelf = self else
            {
                return
            }
            
            if weakSelf.editingStyle == .AddNew
            {
                weakSelf.inMemoryElement = Element()
                weakSelf.inMemoryElement?.rootElementId = weakSelf.rootElementID
                weakSelf.inMemoryElement?.title = weakSelf.composingDelegate?.newElementComposerTitleForNewElement(weakSelf)
                weakSelf.inMemoryElement?.details = weakSelf.composingDelegate?.newElementComposerDetailsForNewElement(weakSelf)
                
                dispatch_async(dispatch_get_main_queue()){ _ in
                    weakSelf.configureBottomToolbar()
                    weakSelf.setupDelegateAndReloadTable()
                }
            }
            else
            {
                DataSource.sharedInstance.localDatadaseHandler?.readElementByIdAsync(weakSelf.currentElementId) { [weak self] (foundDBelement) -> () in
                    
                    guard let weakSelf = self , bdElement = foundDBelement else
                    {
                        return
                    }
                    
                    weakSelf.inMemoryElement = bdElement.createCopyForServer()
                    
                    let mainQueue = dispatch_get_main_queue()
                    let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
                    dispatch_async(mainQueue) { () -> Void in
                        weakSelf.configureBottomToolbar()
                        
                        dispatch_after(timeout, mainQueue) { () -> Void in
                            weakSelf.setupDelegateAndReloadTable()
                        }
                    }
                }
            }
        }
        
        passWhomIdsForElementOp.addDependency(contactsBlockOp)
        afterPassWhomIdsForElementOp.addDependency(passWhomIdsForElementOp)
        
        
        bgQueue.maxConcurrentOperationCount = 1
        
        bgQueue.addOperations([contactsBlockOp, passWhomIdsForElementOp, afterPassWhomIdsForElementOp], waitUntilFinished: false)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("---- viewWillAppear :->  \n ContactIdsToPass: \(currentElementParticipants)")
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        print("---- viewDidAppear :->  \n ContactIdsToPass: \(currentElementParticipants)")
        
        //table?.reloadData()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadTableViewUpdates:", name: "UpdateTextiewCell", object: nil)
        addObserversForKeyboard()
        
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        if bgQueue.operationCount > 0
        {
            bgQueue.cancelAllOperations()
        }
        
        print("---- viewWillDisappear :->  \n ContactIdsToPass: \(currentElementParticipants)")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: - 
    func setupDelegateAndReloadTable()
    {
        self.table?.delegate = self
        self.table?.dataSource = self
        self.table?.reloadData()
    }
    
    func configureBottomToolbar()
    {
        switch editingStyle
        {
        case .AddNew:
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonTap:")
            let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneButtonTap:")
            self.navigationItem.leftBarButtonItem = cancelBarButton
            self.navigationItem.rightBarButtonItem = doneBarButtonItem
            
        case .EditCurrent:
            let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelButtonTap:")
            let fixedSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            fixedSpace.width = 50.0
            if UIScreen.mainScreen().bounds.size.width < 330
            {
                fixedSpace.width = 40.0
            }
            
            var archiveButtonTitle = "Archive".localizedWithComment("")
            
            if let element = self.inMemoryElement
            {
                if element.isArchived()
                {
                    archiveButtonTitle = "Unarchive".localizedWithComment("")
                }
            }
            
            let archiveBarButton = UIBarButtonItem(title: archiveButtonTitle , style: UIBarButtonItemStyle.Plain, target: self, action: "archiveElementToolBarButtonTapped:")
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            let deleteBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteElementToolBarButtonTapped:")
            
            let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "doneButtonTap:")
            self.navigationItem.setLeftBarButtonItems([ cancelBarButton, flexibleSpace, archiveBarButton, flexibleSpace, deleteBarButton, flexibleSpace, doneBarButtonItem], animated: true)
            self.navigationItem.rightBarButtonItem = nil
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
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue
            let keyboardHeight = keyboardFrame.size.height
           
            var keyboardIsToShow = false
            if notification.name == UIKeyboardWillShowNotification
            {
                keyboardIsToShow = true
            }
            
            if keyboardIsToShow
            {
                if let table = self.table
                {
                    let contentInsets = UIEdgeInsetsMake(table.contentInset.top, 0.0, keyboardHeight, 0.0)
                    table.contentInset = contentInsets
                    table.scrollIndicatorInsets = contentInsets
                    table.beginUpdates()
                    table.endUpdates()
                }
            }
            else
            {
                if let aTable = self.table
                {
                    let contentInsets = UIEdgeInsetsMake(aTable.contentInset.top, 0.0, 0.0, 0.0)
                    aTable.contentInset = contentInsets
                    aTable.scrollIndicatorInsets = contentInsets
                }
                
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
            return contactInfos?.count ?? 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section
        {
            case 0:
                let textViewCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! NewElementTextViewCell
                configureTextViewCell(textViewCell, forIndexPath: indexPath)
                return textViewCell
            case 1:
                let textViewCell = tableView.dequeueReusableCellWithIdentifier("TextViewCell", forIndexPath: indexPath) as! NewElementTextViewCell
                configureTextViewCell(textViewCell, forIndexPath: indexPath)
                return textViewCell
            case 2:
                let contactCell = tableView.dequeueReusableCellWithIdentifier("ContactCheckerCell", forIndexPath: indexPath) as! ContactCheckerCell
                configureContactCell(contactCell, forIndexPath:indexPath)
                return contactCell
            default:
                return UITableViewCell(style: .Default, reuseIdentifier: "")
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2
        {
            return "Team".localizedWithComment("")
        }
        return nil
    }

    func configureTextViewCell(cell:NewElementTextViewCell, forIndexPath indexPath:NSIndexPath)
    {
        cell.textView.delegate = self
        textViews[indexPath] = cell.textView
        
        let attributedTextColor = (self.displayMode == .Day) ? kBlackColor : kWhiteColor
        let cellColor = (self.displayMode == .Day) ? kWhiteColor : kBlackColor
        
        cell.backgroundColor = cellColor
        cell.textView.textColor = attributedTextColor
        cell.textView.tintColor = attributedTextColor
        if indexPath.section == 0
        {
            cell.isTitleCell = true
            
            if let title = inMemoryElement?.title// as? String
            {
                let titleAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 25)!, NSForegroundColorAttributeName:attributedTextColor]
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
            cell.backgroundColor = cellColor
            if let description = inMemoryElement?.details //as? String
            {
                if description != ""
                {
                    let descriptionAttributes = [NSFontAttributeName:UIFont(name: "Segoe UI", size: 14)!, NSForegroundColorAttributeName:attributedTextColor]
                    cell.attributedText = NSAttributedString(string: description, attributes: descriptionAttributes)
                }
                else
                {
                    cell.textView.attributedText = nil
                }
            }
            else
            {
                cell.textView.attributedText = nil
            }
        }
    }
    
    func configureContactCell(cell:ContactCheckerCell, forIndexPath indexPath:NSIndexPath)
    {
        if let lvContact = contactInfos?[indexPath.row]
        {
            if let avatarImage = DataSource.sharedInstance.userAvatarsHolder[lvContact.contactId]
            {
                cell.avatar?.image = avatarImage
            }
            else
            {
                cell.avatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            }
            //set name text
            
            cell.nameLabel?.text = lvContact.contactName
            
            //set proper checkbox image
            let contactIdInt = lvContact.contactId
            
            cell.displayMode = self.displayMode
            
            cell.setDisabled(false)
            
            if contactIdInt > 0
            {
                if let participantsForRoot = DataSource.sharedInstance.participantIDsForElement[self.rootElementID]
                {
                    if participantsForRoot.contains(contactIdInt)
                    {
                        cell.checkBox?.image = checkedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
                        cell.setDisabled(true)
                    }
                    else
                    {
                        if currentElementParticipants.contains(contactIdInt)
                        {
                            cell.checkBox?.image = checkedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
                        }
                        else
                        {
                            cell.checkBox?.image = unCheckedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
                        }
                    }
                }
                else
                {
                    if currentElementParticipants.contains(contactIdInt)
                    {
                        cell.checkBox?.image = checkedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
                    }
                    else
                    {
                        cell.checkBox?.image = unCheckedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
                    }
                }
            }
            else
            {
                cell.checkBox?.image = unCheckedCheckboxImage?.imageWithRenderingMode(.AlwaysTemplate)
            }
            
         
        }
    }
    
    //MARK: UITableViewDelegate
    
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

        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        
        //create constraints for label
        let centerXConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        
        let centerYConstraint = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        
        view.addConstraints([centerXConstraint, centerYConstraint])
        
        return view
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
       
        return 80.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section > 1
        {
            return 50.0 //contacts
        }
        else
        {
            let section = indexPath.section
            switch section
            {
            case 0: // Title
                
                if let textView = textViews[indexPath]
                {
                    let lvTestSize = textView.sizeThatFits( CGSizeMake( textView.bounds.size.width, CGFloat.max))
                    let titleHeight = ceil(lvTestSize.height) + 8 + 8 + 17 + 5
                    return titleHeight
                }
                return 130.0
            case 1: //Details (should be higher than title)
                if let textView = textViews[indexPath]
                {
                    let lvTestSize = textView.sizeThatFits( CGSizeMake( textView.bounds.size.width, CGFloat.max))
                    let detailsHeight = ceil(lvTestSize.height) + 8 + 8 + 17 + 24
                    if detailsHeight > 200.0
                    {
                        return detailsHeight
                    }
                }
                return 200.0
            default:break
            }
            return 100.0
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
        guard let _ = self.inMemoryElement else
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
            
            self.table?.endEditing(false)
        }
        else
        {
            contactTappedAtIndexPath(indexPath)
            editingConfuguration = .None
            return
        }
        
        tableView.reloadRowsAtIndexPaths([titlePath, detailsPath], withRowAnimation: .None)
    }
    
    
    func contactTappedAtIndexPath(indexPath: NSIndexPath)
    {
        if let lvContact = contactInfos?[indexPath.row]
        {
            let lvContactIDInt = lvContact.contactId
            
            if let participantsForRoot = DataSource.sharedInstance.participantIDsForElement[self.rootElementID]
            {
                if participantsForRoot.contains(lvContactIDInt)
                {
                    return
                }
            }
            
            if self.currentElementParticipants.contains(lvContactIDInt)
            {
                self.currentElementParticipants.remove(lvContactIDInt)
            }
            else
            {
                self.currentElementParticipants.insert(lvContactIDInt)
            }
        }
        
        self.table?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
    }
    
    //MARK: - UIScrollViewDelegate
    func scrollViewWillBeginDragging(scrollView: UIScrollView)
    {
        self.table?.endEditing(false)
    }
    
    //MARK: - NSNotificationCenter
    func reloadTableViewUpdates(notification:NSNotification?) // this needed to make table view cell grow automatically.
    {
        if let notif = notification
        {
            //var cellIndexPath = notif.object as? NSIndexPath
            
            if let info = notif.userInfo, let textViewTargetHeight = info["height"] as? CGFloat, targetTextView = notif.object as? UITextView
            {
                var targetIndexPath:NSIndexPath?
                for (indexPath,textView) in textViews
                {
                    if textView == targetTextView
                    {
                        if textView.bounds.size.height != textViewTargetHeight
                        {
                            targetIndexPath = indexPath
                        }
                        break
                    }
                }
                table?.beginUpdates()
                table?.endUpdates()
                
                scrollCursorToVisibleIfNeededFor(targetIndexPath)
            }
        }
    }
    
    func scrollCursorToVisibleIfNeededFor(indexPath:NSIndexPath?)
    {
        if let path = indexPath, cell = table?.cellForRowAtIndexPath(path) as? NewElementTextViewCell
        {
            if let textPosition = cell.textView.selectedTextRange
            {
                let cursorRect = cell.textView.caretRectForPosition(textPosition.start)
                
                _ = table?.convertRect(cursorRect, fromView:cell.textView)
                
                if !rectVisible(cursorRect)
                {
                    //cursorRect.size.height += 8; // To add some space underneath the cursor
                    table?.scrollRectToVisible(cursorRect, animated:true)
                }
            }
        }
    }
    
    func rectVisible(rect:CGRect) -> Bool
    {
        if let aTable = self.table
        {
            var visibleRect:CGRect = CGRectZero
            visibleRect.origin = aTable.contentOffset;
            visibleRect.origin.y += aTable.contentInset.top;
            visibleRect.size = aTable.bounds.size;
            visibleRect.size.height -= aTable.contentInset.top + aTable.contentInset.bottom;
            
            return CGRectContainsRect(visibleRect, rect);
        }
       
        return false
    }
    
    //MARK: UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        
     
        if detectTextView_isTitleCell_TextView(textView)
        {
            self.editingConfuguration = .Title
        }
        else
        {
            self.editingConfuguration = .Details
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        let lvTestSize = textView.sizeThatFits( CGSizeMake( textView.bounds.size.width, CGFloat.max))
        let targetHeight = ceil(lvTestSize.height)
        if textView.bounds.size.height != targetHeight
        {
            NSNotificationCenter.defaultCenter().postNotificationName("UpdateTextiewCell", object:textView , userInfo:["height": targetHeight])
        }
    }
    
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if self.editingConfuguration == .Title && text == "\n"
        {
            textView.endEditing(false)
            return false
        }
        
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool
    {
        if detectTextView_isTitleCell_TextView(textView)
        {
            self.inMemoryElement?.title = textView.text
        }
        else
        {
            self.inMemoryElement?.details = textView.text
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView)
    {
        if detectTextView_isTitleCell_TextView(textView)
        {
            print(" Cutrrent editing config = \(editingConfuguration)  , current textView isTitle = TRUE")
        }
        else
        {
            print(" Cutrrent editing config = \(editingConfuguration)  , current textView isTitle = FALSE")
        }
    }
    
    func detectTextView_isTitleCell_TextView(textView:UITextView) -> Bool
    {
        let textViewOriginalFrame = textView.frame
        let textViewFrame = textView.convertRect(textViewOriginalFrame, toView:self.table)
        if let indexPaths = self.table?.indexPathsForRowsInRect(textViewFrame), let firstIndexPath = indexPaths.first
        {
            if let cell  = self.table?.cellForRowAtIndexPath(firstIndexPath) as? NewElementTextViewCell
            {
                if cell.isTitleCell
                {
                    return true
                }
                return false
            }
        }
        return false
    }
    //MARK: ---
    func cancelButtonTap(sender:AnyObject?)
    {
        composingDelegate?.newElementComposerWantsToCancel(self)
    }
    
    func doneButtonTap(sender:AnyObject?)
    {
        self.table?.endEditing(false)
        
        if let anElement = self.inMemoryElement, let currentTitle = anElement.title //as? String
        {
            if currentTitle.characters.count < 1
            {
                print(" -> Cancelling editing of element. Reason: Element title is EMPTY")
                cancelButtonTap(sender)
                return
            }
            
            if anElement.details == nil
            {
                anElement.details = ""
            }
           
            if !currentElementParticipants.isEmpty
            {
                if self.editingStyle == .AddNew
                {
                    var contactIDs = Array(currentElementParticipants)
                    contactIDs.sortInPlace(>)
                    anElement.passWhomIDs = contactIDs
                }
                else //EditCurrent
                {
                    var contactIDs = Array(currentElementParticipants)
                    contactIDs.sortInPlace(>)
                    anElement.passWhomIDs = contactIDs
                }
            }
            else
            {
                anElement.passWhomIDs.removeAll(keepCapacity: false)
            }
            
            if anElement.rootElementId == 0
            {
                anElement.rootElementId =  self.rootElementID
            }
            
            
            if self.currentElementType != .None // when creating new element from chat
            {
                let optionsConverter = ElementOptionsConverter()
                var selectedOption = 0
                switch self.currentElementType
                {
                    case .Signal:
                        anElement.isSignal = true
                    case .Idea:
                        selectedOption = 1
                    case .Task:
                        selectedOption = 2
                    case .Decision:
                        selectedOption = 3
                    case .None:
                        selectedOption = 0
                }
                
                if selectedOption > 0
                {
                    let option = optionsConverter.toggleOptionChange(0, selectedOption: selectedOption)
                    anElement.typeId = option
                }
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
        let warningTitle = "Warning".localizedWithComment("")
        let warningMessage = "You are about to delete current element and all it`s subordinates."
        let deleteTitle = "delete".localizedWithComment("")
        let cancelTitle = "cancel".localizedWithComment("")
        
        if #available(iOS 8.0, *)
        {
            let alertController = UIAlertController(title: warningTitle, message: warningMessage, preferredStyle: .Alert)
            let deleteAction = UIAlertAction(title: deleteTitle , style: UIAlertActionStyle.Default ) { [weak self](alertAction) -> Void in
                if let weakSelf = self
                {
                    weakSelf.dismissSelfWithElementDeletedNotification()
                }
            }
            
            let cancelAction = UIAlertAction(title: cancelTitle, style: .Cancel) { (alertAction) -> Void in
                
            }
            
            alertController.addAction(deleteAction)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else
        {
            let alertDelete = UIAlertView(title: warningTitle, message: warningMessage, delegate: self, cancelButtonTitle: cancelTitle, otherButtonTitles: deleteTitle)
            alertDelete.tag = 0xde1e7e
            alertDelete.show()
        }
    }
    
    func archiveElementToolBarButtonTapped(sender:UIButton?)
    {
        sender?.enabled = false
        
        self.navigationController?.popViewControllerAnimated(true)
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
            let rawArchiveValue = ActionButtonCellType.Archive.rawValue
            NSNotificationCenter.defaultCenter().postNotificationName(kElementActionButtonPressedNotification, object: nil, userInfo: ["actionButtonIndex" : rawArchiveValue])
        })
        
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int)
    {
        if alertView.tag == 0xde1e7e
        {
            if buttonIndex != alertView.cancelButtonIndex
            {
                dismissSelfWithElementDeletedNotification()
            }
        }
    }
    
    
    func dismissSelfWithElementDeletedNotification()
    {
        self.navigationController?.popViewControllerAnimated(false)
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(kElementActionButtonPressedNotification, object: nil, userInfo: ["actionButtonIndex" : ActionButtonCellType.Delete.rawValue])
        })
    }
    
    
}// class end


