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
    var currentChatMessages = [Message]()
    var avatarsHolder:[Int:UIImage] = [Int:UIImage]()
    
    var displayMode:DisplayMode = .Day{
        didSet{
            
        }
    }
    
    var refreshControl:UIRefreshControl?
    
    var newElementOptionsView:OptionsView?
    var newElementDetailsInfo:String?
    var newCreatedElement:Element?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.toolbarHidden = true
        bottomControlsContainerView.delegate = self
        // Do any additional setup after loading the view.
        if let
            elementIdInt = self.currentElement?.elementId?.integerValue,
            messages = DataSource.sharedInstance.getMessagesQuantyty(5, elementId: elementIdInt, lastMessageId: nil)
        {
            currentChatMessages = messages
        }
        
        setupNavigationBar()
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "refreshing".localizedWithComment(""), attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 13)!])
        refreshControl?.tintColor = kDaySignalColor
        refreshControl?.addTarget(self, action: "startRefreshing:", forControlEvents: .ValueChanged)
        self.chatTable.addSubview(refreshControl!)
        
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
        
        let difference = ceil(desiredSize.height - oldSize.height)
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
                    let newMessage = Message(info: messageInfo)
                   
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
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue//()
            let keyboardHeight = keyboardFrame.size.height
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(rawValue:UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
          
            if notification.name == UIKeyboardWillShowNotification
            {
                textHolderBottomConstaint.constant = keyboardHeight //- self.navigationController!.toolbar.bounds.size.height
                chatTable.contentInset.bottom = keyboardHeight
            }
            else
            {
                textHolderBottomConstaint.constant = 0.0
                chatTable.contentInset.bottom = 0.0
            }
            
            
            UIView.animateWithDuration(animationTime,
                delay: 0.0,
                options: options,
                animations: {  [weak self]  in
                    if let weakSelf = self
                    {
                        weakSelf.view.setNeedsLayout()
                    }
            },
                completion: { [weak self]  (finished) -> () in
                    if let aSelf = self
                    {
                        aSelf.scrollToLastMessage(true)
                    }
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
                    weakSelf.chatTable.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Top)
                    
                   // weakSelf.chatTable.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                    
                    weakSelf.scrollToLastMessage(true)
                }
            })
        }
    }

    //MARK: MISCELANEOUS
    
    func setupNavigationBar()
    {
        let contactsButton = UIButton(type:.Custom)
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
            let lvTitleLabel = UILabel()
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
            self.scrollToLastMessage(true)
        })
    }
    
    func scrollToLastMessage(animated:Bool = false)
    {
        if self.currentChatMessages.count > 1
        {
            let lastMessagePath = NSIndexPath(forRow: self.currentChatMessages.count - 1, inSection: 0)
           
            chatTable.scrollToRowAtIndexPath(lastMessagePath, atScrollPosition: .Middle, animated: animated)
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
        if let
            existingMessage = messageForIndexPath(indexPath),
            creatorIdInt = existingMessage.creatorId?.integerValue
        {
            if creatorIdInt == DataSource.sharedInstance.user!.userId!.integerValue
            {
                let sentCell = tableView.dequeueReusableCellWithIdentifier("MyMessageCell", forIndexPath: indexPath) as! ChatMessageSentCell
                sentCell.dateLabel.text = existingMessage.dateCreated?.timeDateString() as? String
                sentCell.message = existingMessage.textBody
                sentCell.messageLabel.textColor = (self.displayMode == .Day) ? kWhiteColor : UIColor.blackColor()
                sentCell.backgroundColor = UIColor.clearColor()
                
                return sentCell
            }
            else
            {
                let recievedCell = tableView.dequeueReusableCellWithIdentifier("OthersMessageCell", forIndexPath: indexPath) as! ChatMessageRecievedCell
                recievedCell.message = existingMessage.textBody
                recievedCell.messageLabel.textColor = (self.displayMode == .Day) ? UIColor.blackColor() : kWhiteColor
                recievedCell.dateLabel.text = existingMessage.dateCreated?.timeDateString() as? String
                recievedCell.avatar?.tintColor = (self.displayMode == .Day) ? kDayCellBackgroundColor : kWhiteColor
                recievedCell.backgroundColor = UIColor.clearColor()
                
                if let anImage = avatarsHolder[creatorIdInt]
                {
                    recievedCell.avatar?.image = anImage
                }
                else
                {
                    let currentRow = indexPath.row
                    var globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                    
                    if #available(iOS 8.0, *)
                    {
                        globalQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                    }
                 
                    dispatch_async(globalQueue) {[weak self] () -> Void in
                        if let anImage = DataSource.sharedInstance.getAvatarForUserId(creatorIdInt), aSelf = self
                        {
                            aSelf.avatarsHolder[creatorIdInt] = anImage
                            print(" -> Chat Loaded avatar for contact Id. : \(creatorIdInt)")
                            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                if let weakSelf = self, indexPathsVisible = weakSelf.chatTable.indexPathsForVisibleRows
                                {
                                    for anIndexPath in indexPathsVisible
                                    {
                                        if anIndexPath.row == currentRow
                                        {
                                            weakSelf.chatTable.reloadRowsAtIndexPaths([anIndexPath], withRowAnimation: .None)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
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
    //MARK: UIRefreshControl
    func startRefreshing(sender:UIRefreshControl)
    {
        loadPreviousMessages {[weak sender] () -> () in
     
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let weakRefreshControl = sender
                {
                    weakRefreshControl.endRefreshing()
                }
            })
            
        }
    }
    
    func loadPreviousMessages(completion:(()->())?)
    {
        DataSource.sharedInstance.messagesLoader?.stopRefreshingLastMessages()
        
        guard let topMessage = self.currentChatMessages.first, messageElementId = topMessage.elementId?.integerValue else
        {
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1))
            dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                completion?()
            })
            return
        }
        
        let bgMessageQueue = dispatch_queue_create("com.Origami.ChatMessages.Queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgMessageQueue) { [weak self]() -> Void in
            
            let theVeryFirstMessageIdInMessages = topMessage.messageId
            if let previousMessagesPortion = DataSource.sharedInstance.getMessagesQuantyty(10, elementId: messageElementId, lastMessageId:theVeryFirstMessageIdInMessages), weakSelf = self
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    let existingMessages = weakSelf.currentChatMessages
                    weakSelf.currentChatMessages = previousMessagesPortion + existingMessages
                    weakSelf.chatTable.reloadData()
                   
                    completion?()
                })
                
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 2.0))
                let bgQueue:dispatch_queue_t?
                if #available (iOS 8.0, *)
                {
                    bgQueue = dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
                }
                else
                {
                    bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                }
                dispatch_after(timeout, bgQueue!, { () -> Void in
                    DataSource.sharedInstance.messagesLoader?.startRefreshingLastMessages()
                })
             
            }
            else
            {
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2))
                dispatch_after(timeout, bgMessageQueue, { () -> Void in
                     completion?()
                    DataSource.sharedInstance.messagesLoader?.startRefreshingLastMessages()
                })
               
            }
        }
      
        
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
            let indexpath = item as? NSIndexPath
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
                }
            }
            
        }
        
        let originX = floor (CGRectGetMidX(self.view.bounds) - 160.0)
        let originY = CGRectGetMaxY(self.view.bounds) - 200.0
        
        let optionsFame:CGRect = CGRectMake(originX, originY, 320, 200)
        
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
            if let elementIdInt = currentElement?.elementId?.integerValue
            {
                if let textBody = message?.textBody
                {
                    self.newElementDetailsInfo = textBody
                }
                
                newElementCreator.composingDelegate = self
                newElementCreator.rootElementID = elementIdInt
                
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
                
                newElementCreator.editingStyle = .AddNew
                
                self.navigationController?.pushViewController(newElementCreator, animated: true)
//                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
//                dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
//                    
//                })
            }
        }
    }
    
    //MARK: ElementComposingDelegate
    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element) {
        self.navigationController?.popViewControllerAnimated(true)
        self.handleAddingNewElement(newElement)
    }
    
    func newElementComposerTitleForNewElement(composer: NewElementComposerViewController) -> String? {
        if let fullInfo = self.newElementDetailsInfo
        {
            let countChars = fullInfo.characters.count
            
            if countChars > 40
            {
                let startIndex = fullInfo.startIndex
                let toIndex = startIndex.advancedBy(40)
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
                            if let weakSelf = self
                            {
                                weakSelf.showAlertWithTitle("ERROR.", message: "Could not add contacts to new element.", cancelButtonTitle: "Ok")
                            }
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
                                print("\n -> Updated element`s typeId")
                            }
                            else
                            {
                                print("error while updating element`s type id")
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
