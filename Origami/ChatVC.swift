//
//  ChatVC.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatVC: UIViewController, ChatInputViewDelegate, MessageObserver, UITableViewDataSource {

    var currentElement:Element?
    
    @IBOutlet var chatTable:UITableView!
    @IBOutlet var bottomControlsContainerView:ChatTextInputView!
    @IBOutlet weak var textHolderBottomConstaint: NSLayoutConstraint!
    @IBOutlet weak var textHolderHeightConstraint: NSLayoutConstraint!
    var defaultTextInputViewHeight:CGFloat?
    var currentChatMessages = [Message](){
        didSet{
            println("Chat Messages Count: \(currentChatMessages.count)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bottomControlsContainerView.delegate = self
        // Do any additional setup after loading the view.
        
        currentChatMessages = DataSource.sharedInstance.getMessagesQuantyty(20, forElementId: currentElement!.elementId!, lastMessageId: nil)
        
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
        
        //scrollToLastMessage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        DataSource.sharedInstance.removeAllObserversForNewMessages()
        
        removeObserversForKeyboard()
    }
    
    //MARK: ChatInputViewDelegate
    func chatInputView(inputView: ChatTextInputView, wantsToChangeToNewSize desiredSize:CGSize) {
        let oldSize:CGSize = inputView.textView.bounds.size
        
        if oldSize.height == desiredSize.height // do nothing
        {
            return
        }
        
//        var toShrink = false
//        if oldSize.height > desiredSize.height
//        {
//            toShrink = true
//        }
        
        var difference = ceil(desiredSize.height - oldSize.height)
        textHolderHeightConstraint.constant += difference
        //textHolderBottomConstaint.constant += difference
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
                    scrollToLastMessage()
                   
                    let bgQueue = NSOperationQueue()
                    bgQueue.addOperationWithBlock({ () -> Void in
                        DataSource.sharedInstance.sendNewMessage(newMessage, completion: { [weak self](error) -> () in
                            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                                if self != nil
                                {
                                    self!.bottomControlsContainerView.endTyping(clearText:true)
                                    self!.textHolderHeightConstraint.constant = self!.defaultTextInputViewHeight!
                                    if error != nil
                                    {
                                        self!.showAlertWithTitle("Message Send Error", message: error!.localizedDescription, cancelButtonTitle: "Ok")
                                    }
                                }
                            })
                        })
                    })
                    
                }
            }
        }
        
       
    }
    func chatInputView(inputView:ChatTextInputView, attachButtonTapped button:UIButton) {
        
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
                self!.view.layoutIfNeeded()
                
            },
                completion: { [weak self]  (finished) -> () in
                    if self != nil
                    {
                        self!.scrollToLastMessage()
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
            
            chatTable.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .None)
            //let currentOffset = chatTable.contentOffset
            //let newOffset = CGPointMake(currentOffset.x, CGFloat(Float(messages.count) * 40.0))
            //scroll to bottom after delay
        }
    }
    //MARK: Alert
    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        alertController.addAction(closeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    //MARK: MISCELANEOUS
    
    func setupNavigationBar()
    {
        var backButton = UIButton.buttonWithType(.Custom) as! UIButton
        backButton.frame = CGRectMake(0, 0, 40.0, 40.0)
        backButton.imageEdgeInsets = UIEdgeInsetsMake(0, -20, 0, 20)
        backButton.setImage( UIImage(named: "icon-back")?.imageWithRenderingMode(.AlwaysTemplate), forState: UIControlState.Normal)
        backButton.tintColor = kDaySignalColor
        backButton.addTarget(self, action: "dismissSelf", forControlEvents: UIControlEvents.TouchUpInside)
        
        
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton) //UIBarButtonItem(image: UIImage(named: "icon-back"), style: UIBarButtonItemStyle.Plain, target: self, action: "dismissSelf")
        
        
        var contactsButton = UIButton.buttonWithType(.Custom) as! UIButton
        contactsButton.frame = CGRectMake(0, 0, 35.0, 35.0)
        contactsButton.imageEdgeInsets = UIEdgeInsetsMake(0, 10.0, 0, -10.0)
        contactsButton.setImage(UIImage(named: "icon-No-Avatar")?.imageWithRenderingMode(.AlwaysOriginal), forState: .Normal)
        contactsButton.tintColor = kDaySignalColor
        contactsButton.addTarget(self, action: "showContactsChecker", forControlEvents: .TouchUpInside)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: contactsButton)
    }
    
    func setupNavigationTitleView()
    {
        if let participantsCount = currentElement?.passWhomIDs?.count
        {
            // setup title label
            var lvTitleLabel = UILabel(frame: CGRectMake(0, 0, 100.0, 40.0))
            let titleFont =  UIFont(name: "Segoe UI", size: 15.0)
            lvTitleLabel.font = titleFont!
            lvTitleLabel.text = "\(participantsCount)" + " " + "participants".localizedWithComment("")
            lvTitleLabel.textAlignment = NSTextAlignment.Center
            lvTitleLabel.textColor = UIColor.grayColor()
            
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
       
        //chatTable.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.None)
        
        chatTable.reloadData()
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.2)), dispatch_get_main_queue(), { [unowned self]() -> Void in
            self.scrollToLastMessage()
        })
       
        //chatTable.setNeedsLayout()
    }
    
    func scrollToLastMessage()
    {
        let contentHeight = chatTable.contentSize.height
        if contentHeight > chatTable.bounds.size.height
        {
            if let lvIndexPath = chatTable.indexPathForRowAtPoint(CGPointMake(0.0, contentHeight - 150))
            {
                chatTable.scrollToRowAtIndexPath(lvIndexPath, atScrollPosition: .Bottom, animated: true)
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
                sentCell.messageLabel.text = existingMessage.textBody
                
                return sentCell
            }
            else
            {
                var recievedCell = tableView.dequeueReusableCellWithIdentifier("OthersMessageCell", forIndexPath: indexPath) as! ChatMessageRecievedCell
                recievedCell.messageLabel.text = existingMessage.textBody
                recievedCell.dateLabel.text = existingMessage.dateCreated!.timeDateString() as? String
                return recievedCell
            }
        }
        else
        {
            let tableViewDefaultCell = UITableViewCell(style: .Default, reuseIdentifier: "EmptyCell")
            return tableViewDefaultCell
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
    
}
