//
//  ChatVC.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

import CoreData

class ChatVC: UIViewController, ChatInputViewDelegate, UITableViewDataSource, UITableViewDelegate, TableItemPickerDelegate, ElementComposingDelegate , NSFetchedResultsControllerDelegate{

    var currentElement:DBElement?
    
    @IBOutlet var chatTable:UITableView!
    @IBOutlet var bottomControlsContainerView:ChatTextInputView!
    @IBOutlet var topNavBarBackgroundView:UIView!
    @IBOutlet weak var textHolderBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var textHolderHeightConstraint: NSLayoutConstraint!
    var defaultTextInputViewHeight:CGFloat?
    //var currentChatMessages = [DBMessageChat]()
    
    var messagesFetchController:NSFetchedResultsController?
    
    var mainContext:NSManagedObjectContext?
    
    var displayMode:DisplayMode = .Day
    
    //var refreshControl:UIRefreshControl?
    
    var newElementOptionsView:OptionsView?
    var newElementDetailsInfo:String?
    var newCreatedElement:Element?
    
    deinit{
        
        NSNotificationCenter.defaultCenter().removeObserver(self.mainContext!, name: NSManagedObjectContextDidSaveNotification, object: nil)
        mainContext = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.toolbarHidden = true
        bottomControlsContainerView.delegate = self
        // Do any additional setup after loading the view.    
        
        setupNavigationBar()
        
        chatTable.rowHeight = UITableViewAutomaticDimension
        chatTable.estimatedRowHeight = 100.0
        chatTable.delegate = self
        chatTable.dataSource = self
        if let existContext = self.mainContext
        {
            NSNotificationCenter.defaultCenter().removeObserver(existContext)
        }
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        if let elementId = currentElement?.elementId?.integerValue, context = self.mainContext
        {
            context.parentContext = DataSource.sharedInstance.localDatadaseHandler?.getPrivateContext()
            let messagesForElementFetchRequest = NSFetchRequest(entityName: "DBMessageChat")
            messagesForElementFetchRequest.fetchBatchSize = 20
            messagesForElementFetchRequest.predicate = NSPredicate(format: "elementId = \(elementId)")
            messagesForElementFetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
            print(context.parentContext?.description)
            messagesFetchController = NSFetchedResultsController(fetchRequest: messagesForElementFetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            
            messagesFetchController?.delegate = self
            
            NSNotificationCenter.defaultCenter().addObserver(context, selector: "mergeChangesFromContextDidSaveNotification:", name: NSManagedObjectContextDidSaveNotification, object: DataSource.sharedInstance.localDatadaseHandler!.getPrivateContext())
           
        }
        

        
        
        do{
            try messagesFetchController?.performFetch()
        }
        catch let error as NSError {
            print("messagesFetchController fetch messages error:\n \(error)")
        }
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.toolbarHidden = true
        let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        setAppearanceForNightModeToggled(nightModeOn)
        turnNightModeOn(nightModeOn)
        bottomControlsContainerView.endTyping(clearText: true) // sets default attributed text to textView
        
        //chatTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Bottom)
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        
        setupNavigationTitleView() // we can appear after editing contacts for this chat - to reload and display proper participants quantity.
        
        defaultTextInputViewHeight = textHolderHeightConstraint.constant
        
        addObserversForKeyboard()
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cellWasLongPressedNotification:", name: kLongPressMessageNotification, object: nil)
        
        scrollToLastMessage(false)
    }
 
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        DataSource.sharedInstance.removeAllObserversForNewMessages()
        
        removeObserversForKeyboard()
        
        bottomControlsContainerView.endTyping(clearText: true) // sets default attributed text to textView
        self.navigationController?.toolbarHidden = false
        //NSNotificationCenter.defaultCenter().removeObserver(self.mainContext, name: NSManagedObjectContextDidSaveNotification, object: nil)
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
        guard let textToSend = inputView.textView.text, userId = DataSource.sharedInstance.user?.userId, currentElementId = currentElement?.elementId else
        {
            inputView.endTyping(clearText: true) //to set default attributed text
            return
        }
        
        if !textToSend.isEmpty
        {
            let currentDate = NSDate()
            let currentDateString = currentDate.dateForServer() ?? NSDate.dummyDate()
            
            let nsDict = NSDictionary(
                objects:
                [inputView.textView.text!,
                    NSNumber(integer: 0),
                    "Ivan",
                    currentElementId,
                    userId,
                    currentDateString],
                forKeys:
                ["Msg",
                    "TypeId",
                    "FirstName",
                    "ElementId",
                    "CreatorId",
                    "CreateDate"])
            
            
            
            guard let messageInfo = nsDict as? [String : AnyObject] else
            {
                return
            }
            
            let newMessage = Message(info: messageInfo)
            newMessage.dateCreated = currentDate
            print("newMessage date: \(newMessage.dateCreated!)")
            dispatch_async(dispatch_get_main_queue()){[weak self] _ in
                if let aSelf = self
                {
                    aSelf.bottomControlsContainerView.endTyping(clearText:true)
                    aSelf.textHolderHeightConstraint.constant = aSelf.defaultTextInputViewHeight!
                }
            }
            
           
            dispatch_async(getBackgroundQueue_DEFAULT() ) { _ in
                
                DataSource.sharedInstance.sendNewMessage(newMessage) { [weak self] (error) -> () in
                    if let messageError = error, aSelf = self
                    {
                        dispatch_async(dispatch_get_main_queue()) { _ in
                            
                            aSelf.showAlertWithTitle("Message Send Error",
                                message: messageError.localizedDescription,
                                cancelButtonTitle: "close".localizedWithComment(""))
                        }
                    }
                }
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
                        
                        self.navigationController?.pushViewController(attachImagePickerVC, animated: true)
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
        
    //MARK: - NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.chatTable.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.chatTable.endUpdates()
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(timeout, dispatch_get_main_queue(), {[weak self] () -> Void in
            if let weakSelf = self
            {
                weakSelf.scrollToLastMessage(true)
            }
        })
        
        self.setParentElementNeedsUpdateIfPresent()
        
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        if let messageObject = anObject as? DBMessageChat
        {
            switch type
            {
                case .Insert:
                print("did Insert message: \n -date:\(messageObject.dateCreated!) \n -text:\n\(messageObject.textBody!)")
                if let inPath = indexPath
                {
                    self.chatTable.insertRowsAtIndexPaths([inPath], withRowAnimation: .None)
                }
                else if let newPath = newIndexPath
                {
                     self.chatTable.insertRowsAtIndexPaths([newPath], withRowAnimation: .None)
                }
                case .Move:
                print("did Move message: \n -date:\(messageObject.dateCreated!) \n -text:  \(messageObject.textBody!)")
                if let inPath = indexPath
                {
                    print("path: \(inPath)")
                }
                if let newPath = newIndexPath
                {
                    print("path: \(newPath)")
                }
                case .Update:
                print("did Update message: \n -date:\(messageObject.dateCreated!) \n -text: \(messageObject.textBody!)")
                case .Delete:
                print("did Delete message: \n -date:\(messageObject.dateCreated!) \n -text: \(messageObject.textBody!)")
            }
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
        if let title = currentElement?.title //as? String
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
        if let count = self.messagesFetchController?.fetchedObjects?.count
        {
            if count > 1
            {
                let lastMessagePath = NSIndexPath(forRow: (count - 1), inSection: 0)
                
                chatTable.scrollToRowAtIndexPath(lastMessagePath, atScrollPosition: .Bottom, animated: animated)
            }
        }
        
    }
    
    //MARK: UITableViewDataSource
    func messageForIndexPath(indexPath:NSIndexPath) -> DBMessageChat?
    {
        if let fetchedObjects = self.messagesFetchController?.fetchedObjects as? [DBMessageChat]
        {
            if fetchedObjects.count > indexPath.row
            {
                return fetchedObjects[indexPath.row]
            }
        }
//        if currentChatMessages.count > indexPath.row {
//            return currentChatMessages[indexPath.row]
//        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let fetchedObjects = self.messagesFetchController?.fetchedObjects as? [DBMessageChat]
        {
            let countMessages = fetchedObjects.count
            print(" fetched Messages: \(countMessages)")
            return countMessages
        }
         print(" fetched Messages: 0")
        return 0
//        return currentChatMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        guard let existingMessage = messageForIndexPath(indexPath),  creatorIdInt = existingMessage.creatorId?.integerValue, currentUserID = DataSource.sharedInstance.user?.userId else
        {
            return UITableViewCell(style: .Default, reuseIdentifier: "EmptyCell")
        }
        
       
        if creatorIdInt == currentUserID
        {
            let sentCell = tableView.dequeueReusableCellWithIdentifier("MyMessageCell", forIndexPath: indexPath) as! ChatMessageSentCell
            sentCell.dateLabel.text = existingMessage.dateCreated?.timeDateString()
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
            recievedCell.dateLabel.text = existingMessage.dateCreated?.timeDateString()
            recievedCell.avatar?.tintColor = (self.displayMode == .Day) ? kDayCellBackgroundColor : kWhiteColor
            recievedCell.backgroundColor = UIColor.clearColor()
            
            if let anImage = DataSource.sharedInstance.getAvatarForUserId(creatorIdInt)
            {
                recievedCell.avatar?.image = anImage.imageWithRenderingMode(.AlwaysOriginal)
            }
            else
            {
                recievedCell.avatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            }
            
            return recievedCell
        }
        
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 100.0
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
//    func startRefreshing(sender:UIRefreshControl)
//    {
//        loadPreviousMessages {[weak sender] () -> () in
//     
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                if let weakRefreshControl = sender
//                {
//                    weakRefreshControl.endRefreshing()
//                }
//            })
//            
//        }
//    }
    
    func loadPreviousMessages(completion:(()->())?)
    {
        //stop refreshing last messages from server
//        DataSource.sharedInstance.messagesLoader?.stopRefreshingLastMessages()
//        
//        guard let topMessage = self.currentChatMessages.first, messageElementId = topMessage.elementId?.integerValue , messageId = topMessage.messageId?.integerValue else
//        {
//            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1))
//            dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
//                completion?()
//            })
//            return
//        }
//        
//        
//        DataSource.sharedInstance.localDatadaseHandler?.readChatMessagesForElementById(messageElementId, fetchSize: 20, lastMessageId: messageId, completion: {[weak self] (foundMessages, error) -> () in
//            
//            if let messagesError = error
//            {
//                print("Error while querying previous messages for ChatVC...:")
//                print(messagesError)
//            }
//            else if let previousMessagesPortion = foundMessages
//            {
//                if let weakSelf = self
//                {
//                    let currentMessages = weakSelf.currentChatMessages
//                    let newMessages = previousMessagesPortion + currentMessages
//                    weakSelf.currentChatMessages = newMessages
//                    
//                    dispatch_async( dispatch_get_main_queue()) {
//                        weakSelf.chatTable.reloadData()
//                    }
//                    completion?()
//                }
//            }
//            
//            //resume refreshing last messages from server
//            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 2.0))
//            dispatch_after(timeout, getBackgroundQueue_UTILITY(), { () -> Void in
//                DataSource.sharedInstance.messagesLoader?.startRefreshingLastMessages()
//            })
//            
//            completion?()
//        })
        
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
                if let anElement = currentElement, elementId = anElement.elementId?.integerValue
                {
                    toVC.currentElementId = elementId
                    toVC.setElementOwned(anElement.isOwnedByCurrentUser())
                }
            }
        }
    }
    
    //MARK: Bottom OptionsView stuff
    
    func cellWasLongPressedNotification(note:NSNotification)
    {
        var currentMessage:String?
        if let cell = note.object as? UITableViewCell
        {
            if let targetIndexPath = self.chatTable.indexPathForCell(cell)
            {
                if let message = messageForIndexPath(targetIndexPath), text = message.textBody
                {
                    currentMessage = text
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
    
    func showOptionsView(frame:CGRect, params:[[String:String]], message:String?)
    {
        if let optionsView = OptionsView(optionsInfo: params)
        {
            optionsView.frame = frame
            self.view.addSubview(optionsView)
            optionsView.delegate = self
            optionsView.message = message
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
    
    func startNewSubordinateWithType(type:NewElementCreationType, message:String?)
    {
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            if let elementIdInt = currentElement?.elementId?.integerValue
            {
                if let textBody = message
                {
                    self.newElementDetailsInfo = textBody
                }
                
                newElementCreator.composingDelegate = self
                newElementCreator.rootElementID = elementIdInt
              
                newElementCreator.currentElementType = type
                
                newElementCreator.editingStyle = .AddNew
                
                self.navigationController?.pushViewController(newElementCreator, animated: true)
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
    
//    func newElementComposerTitleForNewElement(composer: NewElementComposerViewController) -> String? {
//        if let fullInfo = self.newElementDetailsInfo
//        {
//            let countChars = fullInfo.characters.count
//            
//            if countChars > 40
//            {
//                let startIndex = fullInfo.startIndex
//                let toIndex = startIndex.advancedBy(40)
//                let cutString = fullInfo.substringToIndex(toIndex)
//                return cutString
//            }
//            return fullInfo
//        }
//        return nil
//    }
//    
//    func newElementComposerDetailsForNewElement(composer: NewElementComposerViewController) -> String? {
//        
//        return self.newElementDetailsInfo
//    }
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
                passWhomIDs!.append(number)
            }
        }
        
        let sentTypeIdInteger = element.typeId
        
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
