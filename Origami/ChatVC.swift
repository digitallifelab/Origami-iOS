//
//  ChatVC.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatVC: UIViewController, ChatInputViewDelegate, MessageObserver, UITableViewDataSource, UITableViewDelegate {

    var currentElement:Element?
    
    @IBOutlet var chatTable:UITableView!
    @IBOutlet var bottomControlsContainerView:ChatTextInputView!
    @IBOutlet var topNavBarBackgroundView:UIView!
    @IBOutlet weak var textHolderBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var textHolderHeightConstraint: NSLayoutConstraint!
    var defaultTextInputViewHeight:CGFloat?
    var currentChatMessages = [Message](){
        didSet{
            println("\n -> Chat Messages Count: \(currentChatMessages.count)")
        }
    }
    
    var displayMode:DisplayMode = .Day{
        didSet{
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        setAppearanceForNightModeToggled(nightModeOn)
        
        bottomControlsContainerView.endTyping(clearText: true) // sets default attributed text to textView
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        DataSource.sharedInstance.removeAllObserversForNewMessages()
        
        removeObserversForKeyboard()
        
         bottomControlsContainerView.endTyping(clearText: true) // sets default attributed text to textView
    }
    
    
    //MARK: Appearance
    func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        if nightModeOn
        {
            self.view.backgroundColor = UIColor.blackColor()
            self.topNavBarBackgroundView.backgroundColor = UIColor.blackColor()
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar
            bottomControlsContainerView.attachButton.tintColor = kWhiteColor
            self.tabBarController?.tabBar.backgroundColor = UIColor.blackColor()
        }
        else
        {
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
            self.topNavBarBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
            bottomControlsContainerView.attachButton.tintColor = kDayNavigationBarBackgroundColor
            self.tabBarController?.tabBar.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(1.0)
            
        }
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        
        //TODO: switch message cells night-day modes
        self.turnNightModeOn(nightModeOn)
        self.chatTable.reloadSections(NSIndexSet(index:0), withRowAnimation: .Fade)
       
    }
    
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
                    [inputView.textView.text!, NSNumber(integer: 0), "Ivan", currentElement!.elementId!, DataSource.sharedInstance.user!.userId!, NSDate().dateForServer()],
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
                textHolderBottomConstaint.constant = keyboardHeight - self.tabBarController!.tabBar.bounds.size.height
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
//        var backButton = UIButton.buttonWithType(.Custom) as! UIButton
//        backButton.frame = CGRectMake(0, 0, 40.0, 40.0)
//        backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 20)
//        backButton.setImage( UIImage(named: "icon-back")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
//        backButton.tintColor = UIColor.whiteColor()
//        backButton.addTarget(self, action: "dismissSelf", forControlEvents: UIControlEvents.TouchUpInside)
//        
//        
//        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        
        
        var contactsButton = UIButton.buttonWithType(.Custom) as! UIButton
        contactsButton.frame = CGRectMake(0, 0, 35.0, 35.0)
        contactsButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        contactsButton.imageEdgeInsets = UIEdgeInsetsMake(5, 10.0, 5, -10.0)
        contactsButton.setImage(UIImage(named: "icon-contacts"), forState: .Normal)
        contactsButton.tintColor = UIColor.whiteColor()
        contactsButton.addTarget(self, action: "showContactsChecker", forControlEvents: .TouchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: contactsButton)
    }
    
    func setupNavigationTitleView()
    {
        if let participantsCount = currentElement?.passWhomIDs.count
        {
            // setup title label
            var lvTitleLabel = UILabel(frame: CGRectMake(0, 0, 100.0, 40.0))
            let titleFont =  UIFont(name: "Segoe UI", size: 15.0)
            lvTitleLabel.font = titleFont!
            lvTitleLabel.text = "\(participantsCount)" + " " + "participants".localizedWithComment("")
            lvTitleLabel.textAlignment = NSTextAlignment.Center
            lvTitleLabel.textColor = kWhiteColor
            self.navigationItem.titleView = lvTitleLabel
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
                println("\n -> LastIndexPathRow: \(lastMessagePath.row)")
                chatTable.scrollToRowAtIndexPath(lastMessagePath, atScrollPosition: .Middle, animated: true)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.3)), dispatch_get_main_queue(), { [weak self]() -> Void in
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
    func messageForIndexPath(indexPath:NSIndexPath) -> Message? {
        if currentChatMessages.count > indexPath.row {
            return currentChatMessages[indexPath.row]
        }
        return nil
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentChatMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let existingMessage = messageForIndexPath(indexPath)
        {
            if existingMessage.creatorId!.integerValue == DataSource.sharedInstance.user!.userId!.integerValue
            {
                var sentCell = tableView.dequeueReusableCellWithIdentifier("MyMessageCell", forIndexPath: indexPath) as! ChatMessageSentCell
                sentCell.dateLabel.text = existingMessage.dateCreated!.timeDateString() as? String
                sentCell.message = existingMessage.textBody
                sentCell.messageLabel.textColor = (self.displayMode == .Day) ? kWhiteColor : UIColor.blackColor()
                return sentCell
            }
            else
            {
                var recievedCell = tableView.dequeueReusableCellWithIdentifier("OthersMessageCell", forIndexPath: indexPath) as! ChatMessageRecievedCell
                recievedCell.message = existingMessage.textBody
                recievedCell.messageLabel.textColor = (self.displayMode == .Day) ? UIColor.blackColor() : kWhiteColor
                recievedCell.dateLabel.text = existingMessage.dateCreated!.timeDateString() as? String
                recievedCell.avatar.tintColor = (self.displayMode == .Day) ? kDayCellBackgroundColor : kWhiteColor
                return recievedCell
            }
        }
        else
        {
            let tableViewDefaultCell = UITableViewCell(style: .Default, reuseIdentifier: "EmptyCell")
            return tableViewDefaultCell
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let aCell = cell as? ChatMessageRecievedCell
        {
            aCell.roundCorners()
        }
        if let aCell = cell as? ChatMessageSentCell
        {
            aCell.roundCorners()
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        bottomControlsContainerView.endEditing(true)
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
    
}
