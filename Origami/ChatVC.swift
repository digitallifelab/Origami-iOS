//
//  ChatVC.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatVC: UIViewController, ChatInputViewDelegate, MessageObserver, UITableViewDataSource, UITableViewDelegate, TableItemPickerDelegate, ElementComposingDelegate {

    var currentElement:Element?
    
    @IBOutlet var chatTable:UITableView!
    @IBOutlet var bottomControlsContainerView:ChatTextInputView!
    @IBOutlet var topNavBarBackgroundView:UIView!
    @IBOutlet weak var textHolderBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var textHolderHeightConstraint: NSLayoutConstraint!
    var defaultTextInputViewHeight:CGFloat?
    var currentChatMessages = [Message](){
        didSet{
            println("\n ->Did set currentChatMessages.\n Chat Messages Count: \(currentChatMessages.count)")
        }
    }
    
    var displayMode:DisplayMode = .Day{
        didSet{
            
        }
    }
    
    var newElementOptionsView:OptionsView?
    var newElementDetailsInfo:String?
    var newCreatedElement:Element?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.toolbarHidden = true
        bottomControlsContainerView.delegate = self
        // Do any additional setup after loading the view.
        if let messages = DataSource.sharedInstance.getMessagesQuantyty(20, forElementId: currentElement!.elementId!, lastMessageId: nil)
        {
            currentChatMessages = messages
        }
        
        setupNavigationBar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupNavigationTitleView() // we can appear after editing contacts for this chat - to reload and display proper participants quantity.
        
        defaultTextInputViewHeight = textHolderHeightConstraint.constant
        
        DataSource.sharedInstance.addObserverForNewMessagesForElement(self, elementId: currentElement!.elementId!)

        addObserversForKeyboard()
        
        reloadChatTable()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cellWasLongPressedNotification:", name: kLongPressMessageNotification, object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.toolbarHidden = true
        let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        setAppearanceForNightModeToggled(nightModeOn)
        turnNightModeOn(nightModeOn)
        bottomControlsContainerView.endTyping(clearText: true) // sets default attributed text to textView
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        DataSource.sharedInstance.removeAllObserversForNewMessages()
        
        removeObserversForKeyboard()
        
        bottomControlsContainerView.endTyping(clearText: true) // sets default attributed text to textView
        self.navigationController?.toolbarHidden = false
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kLongPressMessageNotification, object: nil)
    }
    
    
    //MARK: Appearance
    
    //MARK: DayMode
    func turnNightModeOn(nightMode:Bool)
    {
        if nightMode
        {
            self.displayMode = .Night
        }
        else
        {
            self.displayMode = .Day
        }
        bottomControlsContainerView.displayMode = self.displayMode
        self.chatTable.reloadSections(NSIndexSet(index:0), withRowAnimation: .Fade)
    }
    
    //MARK: ChatInputViewDelegate
    func chatInputView(inputView: ChatTextInputView, wantsToChangeToNewSize desiredSize:CGSize) {
        let oldSize:CGSize = inputView.textView.bounds.size
        
        if oldSize.height == desiredSize.height // do nothing
        {
            return
        }
        
        var difference = ceil(desiredSize.height - oldSize.height)
        textHolderHeightConstraint.constant += difference

        self.view.layoutIfNeeded()
        
    }
    
    func chatInputView(inputView:ChatTextInputView, sendButtonTapped button:UIButton)
    {
        if let textToSend = inputView.textView.text
        {
            if !textToSend.isEmpty
            {
                let nsDict = NSDictionary(
                    objects:
                    [inputView.textView.text!, NSNumber(integer: 0), "Ivan", currentElement!.elementId!, DataSource.sharedInstance.user!.userId!, NSDate().dateForServer() ?? NSDate.dummyDate()],
                    forKeys:
                    ["Msg","TypeId","FirstName","ElementId", "CreatorId", "CreateDate"])
                
                if let messageInfo = nsDict as? [String : AnyObject]
                {
                    var newMessage = Message(info: messageInfo)
                   
                    NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] () -> Void in
                        if let aSelf = self
                        {
                            aSelf.bottomControlsContainerView.endTyping(clearText:true)
                            aSelf.textHolderHeightConstraint.constant = aSelf.defaultTextInputViewHeight!
                        }
                    })
                    
                    let bgQueue = NSOperationQueue()
                    bgQueue.addOperationWithBlock({ () -> Void in
                        DataSource.sharedInstance.sendNewMessage(newMessage, completion: { [weak self](error) -> () in
                            if error != nil
                            {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    if let aSelf = self
                                    {
                                        aSelf.showAlertWithTitle("Message Send Error", message: error!.localizedDescription, cancelButtonTitle: "Ok")
                                    }
                                })
                                
                            }
                        })
                    })
                }
            }
            else
            {
                inputView.endTyping(clearText: true) //to set default attributed text
            }
        }
    }
    
    func chatInputView(inputView:ChatTextInputView, attachButtonTapped button:UIButton)
    {
        if let viewControllers = self.navigationController?.viewControllers
        {
            if viewControllers.count > 1
            {
                if let elementViewController = viewControllers[viewControllers.count - 2] as? SingleElementDashboardVC
                {
                    if let attachImagePickerVC = self.storyboard?.instantiateViewControllerWithIdentifier("ImagePickerVC") as? ImagePickingViewController
                    {
                        attachImagePickerVC.attachPickingDelegate = elementViewController
                        
                        self.presentViewController(attachImagePickerVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    
    func addObserversForKeyboard()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardAppearance:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardAppearance:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func removeObserversForKeyboard()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func handleKeyboardAppearance(notification:NSNotification)
    {
        if let notifInfo = notification.userInfo
        {
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue()
            let keyboardHeight = keyboardFrame.size.height
            //let animationOptionCurveNumber = notifInfo[UIKeyboardAnimationCurveUserInfoKey]! as! NSNumber
            //let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions.fromRaw(   animationOptionCurveNumber)
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            var keyboardIsToShow = false
            if notification.name == UIKeyboardWillShowNotification
            {
                keyboardIsToShow = true
                textHolderBottomConstaint.constant = keyboardHeight //- self.navigationController!.toolbar.bounds.size.height
            }
            else
            {
                textHolderBottomConstaint.constant = 0.0
            }
            
            
            UIView.animateWithDuration(animationTime,
                delay: 0.0,
                options: options,
                animations: {  [weak self]  in
                    if let weakSelf = self
                    {
                        weakSelf.view.layoutIfNeeded()
                    }
             
                
            },
                completion: { [weak self]  (finished) -> () in

            })
        }
    }
    
    //MARK: MessageObserver ( almost KVO )
    func newMessagesAdded(messages: [Message]) {
        if messages.count > 0
        {
            var indexPaths = [NSIndexPath]()
            for message in messages
            {
                let lvIndexPath = NSIndexPath(forRow: self.currentChatMessages.count, inSection: 0)
                indexPaths.append(lvIndexPath)
                self.currentChatMessages.append(message)
            }
            
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.chatTable.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
                    
                    weakSelf.chatTable.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                    
                    weakSelf.scrollToLastMessage()
                }
           
            })
            
        }
    }

    //MARK: MISCELANEOUS
    
    func setupNavigationBar()
    {
        var contactsButton = UIButton.buttonWithType(.Custom) as! UIButton
        contactsButton.frame = CGRectMake(0, 0, 35.0, 35.0)
        contactsButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        contactsButton.imageEdgeInsets = UIEdgeInsetsMake(5, 10.0, 5, -10.0)
        contactsButton.setImage(UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        contactsButton.tintColor = UIColor.whiteColor()
        contactsButton.addTarget(self, action: "showContactsChecker", forControlEvents: .TouchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: contactsButton)
        
    }
    
    func setupNavigationTitleView()
    {
        if let title = currentElement?.title as? String
        {
            var lvTitleLabel = UILabel()
            let titleFont =  UIFont(name: "Segoe UI", size: 15.0)
            lvTitleLabel.font = titleFont!
            lvTitleLabel.text = title//"\(participantsCount)" + " " + "participants".localizedWithComment("")
            lvTitleLabel.sizeToFit()
            lvTitleLabel.textAlignment = NSTextAlignment.Center
            lvTitleLabel.textColor = kWhiteColor
            lvTitleLabel.center.x = CGRectGetMidX(self.view.bounds)
            lvTitleLabel.numberOfLines = 1
            lvTitleLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            lvTitleLabel.frame = CGRectMake(60.0, 0.0, 100.0, 21.0)
            lvTitleLabel.center.x = CGRectGetMidX(self.view.bounds)
            self.navigationItem.titleView = lvTitleLabel
            self.navigationItem.titleView?.bounds.size.width = 180.0
        }
    }
    
    func dismissSelf()
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func showContactsChecker()
    {
        performSegueWithIdentifier("ShowContactsChecker", sender: self)
    }
    
    func reloadChatTable() {
        chatTable.rowHeight = UITableViewAutomaticDimension
        chatTable.estimatedRowHeight = 100.0
        chatTable.dataSource = self
        chatTable.delegate = self
        chatTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.None)
        
        //chatTable.reloadData()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.25)), dispatch_get_main_queue(), { [unowned self]() -> Void in
            self.scrollToLastMessage()
        })
       
        //chatTable.setNeedsLayout()
    }
    
    func scrollToLastMessage()
    {
        let contentHeight = chatTable.contentSize.height
        if contentHeight > chatTable.bounds.size.height
        {
            if self.currentChatMessages.count > 1
            {
                let lastMessagePath = NSIndexPath(forRow: self.currentChatMessages.count - 1, inSection: 0)
                //println("\n -> LastIndexPathRow: \(lastMessagePath.row)")
                chatTable.scrollToRowAtIndexPath(lastMessagePath, atScrollPosition: .Middle, animated: false)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.25)), dispatch_get_main_queue(), { [weak self]() -> Void in
                    if let weakSelf = self
                    {
                        let newLastPath = NSIndexPath(forRow: weakSelf.currentChatMessages.count - 1, inSection: 0)
                        weakSelf.chatTable.reloadRowsAtIndexPaths([newLastPath], withRowAnimation: .None)
                    }
                })
            }
        }
    }
    
    //MARK: UITableViewDataSource
    func messageForIndexPath(indexPath:NSIndexPath) -> Message?
    {
        if currentChatMessages.count > indexPath.row {
            return currentChatMessages[indexPath.row]
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return currentChatMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let existingMessage = messageForIndexPath(indexPath)
        {
            if existingMessage.creatorId!.integerValue == DataSource.sharedInstance.user!.userId!.integerValue
            {
                var sentCell = tableView.dequeueReusableCellWithIdentifier("MyMessageCell", forIndexPath: indexPath) as! ChatMessageSentCell
                sentCell.dateLabel.text = existingMessage.dateCreated!.timeDateString() as? String
                sentCell.message = existingMessage.textBody
                sentCell.messageLabel.textColor = (self.displayMode == .Day) ? kWhiteColor : UIColor.blackColor()
                sentCell.backgroundColor = UIColor.clearColor()
                return sentCell
            }
            else
            {
                var recievedCell = tableView.dequeueReusableCellWithIdentifier("OthersMessageCell", forIndexPath: indexPath) as! ChatMessageRecievedCell
                recievedCell.message = existingMessage.textBody
                recievedCell.messageLabel.textColor = (self.displayMode == .Day) ? UIColor.blackColor() : kWhiteColor
                recievedCell.dateLabel.text = existingMessage.dateCreated!.timeDateString() as? String
                recievedCell.avatar.tintColor = (self.displayMode == .Day) ? kDayCellBackgroundColor : kWhiteColor
                recievedCell.backgroundColor = UIColor.clearColor()
                return recievedCell
            }
        }
        else
        {
            let tableViewDefaultCell = UITableViewCell(style: .Default, reuseIdentifier: "EmptyCell")
            return tableViewDefaultCell
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 70.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        
        if let nsString:NSString = messageForIndexPath(indexPath)?.textBody
        {
            let size = CGSizeMake(160.0, CGFloat(FLT_MAX))
            let options = [NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!]
            let targetStringFrame = nsString.boundingRectWithSize(size, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: options, context: nil)
            let height = targetStringFrame.size.height + 8 * 2 + 22 + 5 + 5 + 8 * 2
            if height > 70.0
            {
                return height
            }
        }
        
        return 70.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        bottomControlsContainerView.endEditing(true)
    }
    
    //MARK: TableItemPickerDelegate
    func itemPickerDidCancel(itemPicker: AnyObject) {
        if let picker = itemPicker as? OptionsView
        {
            hideOptionsView(picker, completion: nil)
        }
    }
    
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject) {
        if let picker = itemPicker as? OptionsView
        {
            var indexpath = item as? NSIndexPath
            hideOptionsView(picker, completion: {[weak self] () -> () in
                
                if let indexPath = indexpath
                {
                    let row = indexPath.row
                    if let weakSelf = self
                    {
                        switch row
                        {
                        case 0: //Signal
                            weakSelf.startNewSubordinateWithType(.Signal, message:picker.message)
                        case 1: //Idea
                            weakSelf.startNewSubordinateWithType(.Idea, message:picker.message)
                        case 2: //Task
                            weakSelf.startNewSubordinateWithType(.Task, message:picker.message)
                        case 3: //Solution
                            weakSelf.startNewSubordinateWithType(.Decision, message:picker.message)
                        default:
                            break
                        }
                    }
                }
            })
        }
    }
    
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowContactsChecker"
        {
            if let toVC = segue.destinationViewController as? ParticipantsVC
            {
                toVC.currentElement = currentElement
            }
        }
    }
    
    //MARK: Bottom OptionsView stuff
    
    func cellWasLongPressedNotification(note:NSNotification)
    {
        var currentMessage:Message?
        if let cell = note.object as? UITableViewCell
        {
            if let targetIndexPath = self.chatTable.indexPathForCell(cell)
            {
                if let message = messageForIndexPath(targetIndexPath)
                {
                    currentMessage = message
                    //println(" pressed  message: \(message.textBody)")
                }
            }
            
        }
        
        var originX = floor (CGRectGetMidX(self.view.bounds) - 160.0)
        var originY = CGRectGetMaxY(self.view.bounds) - 200.0
        
        var optionsFame:CGRect = CGRectMake(originX, originY, 320, 200)
        
        var currentWidth = self.view.bounds.size.width
        var currentHeight = self.view.bounds.size.height
        
        if FrameCounter.isLowerThanIOSVersion("8.0")
        {
            let orientation = FrameCounter.getCurrentDeviceOrientation()
            if orientation == UIInterfaceOrientation.LandscapeLeft || orientation == UIInterfaceOrientation.LandscapeRight
            {
                currentHeight = self.view.bounds.size.width
                currentWidth = self.view.bounds.size.height
            }
        }
        
        showOptionsView(optionsFame,
            params: [
            ["Signal".localizedWithComment("")   : "icon-flag"],
            ["Idea".localizedWithComment("")     : "icon-idea"],
            ["Task".localizedWithComment("")     : "icon-okey"],
            ["Decision".localizedWithComment("") : "icon-solution"]
            ], message:currentMessage)
    }
    
    func showOptionsView(frame:CGRect, params:[[String:String]], message:Message?)
    {
        if let optionsView = OptionsView(optionsInfo: params)
        {
            optionsView.frame = frame
            //optionsView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
            self.view.addSubview(optionsView)
            optionsView.delegate = self
            optionsView.message = message
            //optionsView.showYourselfAnimated(true)
            self.newElementOptionsView = optionsView
            
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kLongPressMessageNotification, object: nil)
    }
    
    func hideOptionsView(view:OptionsView, completion:(()->())?)
    {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            view.alpha = 0.0
            }, completion: { (finished) -> Void in
                view.removeFromSuperview()
                
                completion?()
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cellWasLongPressedNotification:", name: kLongPressMessageNotification, object: nil)
    }
    
    func startNewSubordinateWithType(type:NewElementCreationType, message:Message?)
    {
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            if let elementId = currentElement?.elementId
            {
                if let textBody = message?.textBody
                {
                    self.newElementDetailsInfo = textBody
                }
                
                newElementCreator.composingDelegate = self
                newElementCreator.rootElementID = elementId.integerValue
                if let passwhomIDs = currentElement?.passWhomIDs
                {
                    if passwhomIDs.count > 0
                    {
                        var idInts = Set<Int>()
                        for number in passwhomIDs
                        {
                            idInts.insert(number.integerValue)
                        }
                        newElementCreator.contactIDsToPass = idInts// subordinate elements should automaticaly inherit current element`s assignet contacts..  Creator can add or delete contacts later, when creating element.
                    }
                    
                }
              
                newElementCreator.currentElementType = type
                self.navigationController?.pushViewController(newElementCreator, animated: true)
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
                dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                    newElementCreator.editingStyle = .AddNew
                })
//                self.presentViewController(newElementCreator, animated: true, completion: { () -> Void in
//                    newElementCreator.editingStyle = .AddNew
//                })
            }
        }
    }
    
    //MARK: ElementComposingDelegate
    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
       // self.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element) {
        self.navigationController?.popViewControllerAnimated(true)

        self.handleAddingNewElement(newElement)
        
//        self.dismissViewControllerAnimated(true, completion: {[weak self] () -> Void in
//             if let weakSelf = self
//             {
//                weakSelf.handleAddingNewElement(newElement)
//                
//            }
//        })
    }
    
    func newElementComposerTitleForNewElement(composer: NewElementComposerViewController) -> String? {
        if let fullInfo = self.newElementDetailsInfo
        {
            let countChars = count(fullInfo)
            
            if countChars > 40
            {
                let startIndex = fullInfo.startIndex
                let toIndex = advance(startIndex, 40)
                let cutString = fullInfo.substringToIndex(toIndex)
                return cutString
            }
            return fullInfo
        }
        return nil
    }
    
    func newElementComposerDetailsForNewElement(composer: NewElementComposerViewController) -> String? {
        
        return self.newElementDetailsInfo
    }
    //MARK: -----
    func handleAddingNewElement(element:Element)
    {
        // 1 - send new element to server
        // 2 - send passWhomIDs, if present
        var passWhomIDs:[Int]?
        let nsNumberArray = element.passWhomIDs
        if !nsNumberArray.isEmpty
        {
            passWhomIDs = [Int]()
            for number in nsNumberArray
            {
                passWhomIDs!.append(number.integerValue)
            }
        }
        
        let sentTypeIdInteger = element.typeId.integerValue
        
        let newLocalElement = Element(info:  element.toDictionary())
        self.newCreatedElement = newLocalElement
        // 1
        DataSource.sharedInstance.submitNewElementToServer(newLocalElement, completion: {[weak self] (newElementID, submitingError) -> () in
            if let lvElementId = newElementID
            {
                if let passWhomIDsArray = passWhomIDs // 2
                {
                    let passWhomSet = Set(passWhomIDsArray)
                    DataSource.sharedInstance.addSeveralContacts(passWhomSet, toElement: lvElementId, completion: { (succeededIDs, failedIDs) -> () in
                        if !failedIDs.isEmpty
                        {
                            //println(" added to \(succeededIDs)")
                            //println(" failed to add to \(failedIDs)")
                            if let weakSelf = self
                            {
                                weakSelf.showAlertWithTitle("ERROR.", message: "Could not add contacts to new element.", cancelButtonTitle: "Ok")
                            }
                        }
                        else
                        {
                            //println(" added to \(succeededIDs)")
                        }
                    })
                }
                
                if sentTypeIdInteger != 0
                {
                    if let weakSelf = self, currentNewElement = weakSelf.newCreatedElement
                    {
                        currentNewElement.elementId = lvElementId
                        DataSource.sharedInstance.editElement(currentNewElement, completionClosure: { (edited) -> () in
                            if edited
                            {
                                //println("Updated element`s typeId")
                            }
                            else
                            {
                                println("error while updating element`s type id")
                            }
                        })
                    }
                    
                }
            }
            else
            {
                if let weakSelf = self
                {
                    weakSelf.showAlertWithTitle("ERROR.", message: "Could not create new element.", cancelButtonTitle: "Ok")
                }
            }
        })
    }
    
}
