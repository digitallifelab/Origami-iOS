//
//  ElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

 class ElementDashboardVC: UIViewController, ElementSelectionDelegate, MessageObserver, ElementTextEditingDelegate, ButtonTapDelegate , AttachPickingDelegate, AttachmentSelectionDelegate, UIViewControllerTransitioningDelegate, ElementComposingDelegate {
    
    struct AttachToDisplay {
    
        var type:FileType
        var data:NSData
        var name:String
    }
    
    @IBOutlet var table:UITableView!
    @IBOutlet var navigationBackgroundView:UIView!
    
    private var fileToDisplay:AttachToDisplay?
    var shouldRecalculateTableContents = false
    var viewControlerDisplayMode:DisplayMode = .Day
    var tableHandler:ElementMainTableHandler?
    var fadeViewControllerAnimator:FadeOpaqueAnimator?
    var element:Element = Element() //should be assigned by segue from main Home VC, or by pushing another instanse of SELF because of tapping on subordinate element
    {
        didSet
        {
            self.title = element.title as? String
            self.tableHandler = ElementMainTableHandler(element: element)
            self.tableHandler?.displayMode =  self.viewControlerDisplayMode
        }
    }
   
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        checkAppearanceForNightDayMode()
        
        configureChatButtonItem()
        
        self.fadeViewControllerAnimator = FadeOpaqueAnimator() //custon view controller transition - when editing element`s title or description
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewControlerDisplayMode = ( NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey) ) ? .Night : .Day
        
        configureTitleLabel()  //- add empty label to hide  black "self.title" from nav bar.
        loadAssotiatedContactsInBackground()
        let tableHandler = ElementMainTableHandler(element: self.element)
        tableHandler.displayMode = self.viewControlerDisplayMode
        self.tableHandler = tableHandler // to handle reloading after deletion a subordinate.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //configureMainTable()
        if tableHandler != nil
        {
            if let existingChatPreviewHandler = tableHandler!.lastMessagesTableHandler
            {
                existingChatPreviewHandler.reloadLastMessagesForElementId(element.elementId!)
                tableHandler!.reloadChatMessagesSection()
            }
            else
            {
                if let lvMessages = tableHandler!.getLastChatMessages()
                {
                    tableHandler!.lastMessagesTableHandler = ElementChatPreviewTableHandler(messages: lvMessages)
                    tableHandler!.reloadChatMessagesSection()
                }
                else //observe messages added for current element id
                {
                    DataSource.sharedInstance.addObserverForNewMessagesForElement(self, elementId: element.elementId!)
                }
            }
            
            loadAttachesData(nil)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadAttachesData:", name: "refreshCurrentAttaches", object: nil)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        //to eliminate table jumping when reload table is called after view did appear, when we go back by navigationcontroller stack
        DataSource.sharedInstance.removeAllObserversForNewMessages()
        table.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        
    }
    //MARK: -----
    
    func checkAppearanceForNightDayMode()
    {
        let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        if nightModeOn
        {
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
        }
        else
        {
            self.view.backgroundColor = UIColor.whiteColor()
            self.navigationBackgroundView.backgroundColor = kDayCellBackgroundColor
        }
    }
    
    //MARK: -----
    
    func loadAssotiatedContactsInBackground()
    {
        let lvElement = self.element
        let bgQueue = dispatch_queue_create("Origami.BackGroundQueue.ConnectedUsersQuery", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue, { () -> Void in
            DataSource.sharedInstance.loadPassWhomIdsForElement(lvElement,
                comlpetion: {  [weak self] (finished) -> () in
                    if finished
                    {
                        if self != nil
                        {
                            for number in self!.element.passWhomIDs!
                            {
                                println("PassWhom ID for Element = \(number)")
                            }
                        }
                    }
                    else
                    {
                        println("Error while loading PAss Whom ISd for element.. elementID: \(lvElement.elementId!)")
                    }
                })
            })
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        shouldRecalculateTableContents = true
    }
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        //configureMainTable()
        shouldRecalculateTableContents = true
    }
    override func viewDidLayoutSubviews()
    {
        if shouldRecalculateTableContents
        {
            shouldRecalculateTableContents = false
            configureMainTable()
        }
    }

    //MARK: UIViewControllerTransitioningDelegate
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.fadeViewControllerAnimator!.transitionDirection = .FadeIn
        return self.fadeViewControllerAnimator!
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.fadeViewControllerAnimator!.transitionDirection = .FadeOut
        return self.fadeViewControllerAnimator
    }
    
    //MARK: TableView
    func configureMainTable()
    {
        if self.tableHandler != nil && self.table != nil
        {
            table.estimatedRowHeight = 100.0
            table.rowHeight = UITableViewAutomaticDimension
            
            if let lastChatMessages = DataSource.sharedInstance.getMessagesQuantyty(3, forElementId: element.elementId!, lastMessageId: nil)
            {
                tableHandler!.lastMessagesTableHandler = ElementChatPreviewTableHandler(messages: lastChatMessages)
            }
            
            tableHandler!.handledTableView = self.table
            tableHandler!.elementTapDelegate = self
            tableHandler!.elementTextViewEditingDelegate = self
            tableHandler!.buttonTapDelegate = self
            table.delegate = self.tableHandler
            table.dataSource = self.tableHandler
            tableHandler!.handledTableView.reloadData()
        }
    }
    
    //MARK: NavigationBar Items
    func configureChatButtonItem()
    {
        let chatButton:UIButton = UIButton.buttonWithType(.Custom) as! UIButton
        chatButton.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 0, -10)
        chatButton.setImage(UIImage(named: "icon-chat")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: UIControlState.Normal)
        chatButton.tintColor = kWhiteColor//kDaySignalColor
        chatButton.addTarget(self, action: "chatButtonTapped:", forControlEvents: .TouchUpInside)
        chatButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        
        let chatBarItem:UIBarButtonItem = UIBarButtonItem(customView: chatButton)
        
        self.navigationItem.rightBarButtonItem = chatBarItem
    }
    
    func configureTitleLabel()
    {
        var titleLabel = UILabel()//UILabel(frame:CGRectMake(0.0, 0.0, 150.0, 40.0))
//        titleLabel.textColor = self.navigationController?.navigationBar.tintColor
//        titleLabel.font = UIFont(name: "SegoeUI-Semibold", size: 20)
//        //titleLabel.text = self.title
//        
//        titleLabel.sizeToFit()
//        let labelSize = titleLabel.bounds.size
//        if labelSize.width > UIScreen.mainScreen().bounds.size.width / 3
//        {
//            let newWidth = UIScreen.mainScreen().bounds.size.width / 3
//            titleLabel.frame = CGRectMake(0, 0, newWidth, 40.0)
//        }
//        
//        let boundsNav = self.navigationController!.navigationBar.bounds
//        titleLabel.center = CGPointMake(CGRectGetMidX(boundsNav), CGRectGetMidY(boundsNav))
        
        self.navigationItem.titleView = titleLabel
    }
    
    //MARK: ElementSelectionDelegate
    func didTapOnElement(element: Element)
    {
        let nextViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ElementDashboard") as! ElementDashboardVC
        nextViewController.element = element
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    //MARK: 

    func titleCellEditTitleTapped(cell: ElementDashboardTextViewCell) {
        startEditingElementText(true)
    }
    
    func descriptionCellEditDescriptionTapped(cell: ElementDashboardTextViewCell) {
        startEditingElementText(false)
    }
    
    
    //MARK: Actions
    func chatButtonTapped(sender:AnyObject)
    {
        self.performSegueWithIdentifier("ShowElementChat", sender: element)
    }
    
    func startEditingElementText(isTitle:Bool)
    {
        //shouldEditTitle = isTitle
        //self.performSegueWithIdentifier("ShowTextEditing", sender: isTitle)
        let storyBoard = self.storyboard
        if let textEditorVC = storyboard!.instantiateViewControllerWithIdentifier("ElementTextEditing") as? ElementTextEditingVC
        {
            textEditorVC.editingElement = self.element
            textEditorVC.isEditingElementTitle = isTitle
            
            textEditorVC.modalPresentationStyle = .Custom
            textEditorVC.transitioningDelegate = self
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadElementTextInfoContents:", name: "TextEditorSubmittedNewText", object: textEditorVC)
            self.presentViewController(textEditorVC, animated: true, completion:nil)
        }
    }
    
    func reloadElementTextInfoContents(notification:NSNotification?)
    {
        if let userInfo = notification?.userInfo as? [String:AnyObject]
        {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: "TextEditorSubmittedNewText", object: nil)
            self.table.reloadData()
        }
    }
    
    func loadAttachesData(notification:NSNotification?)
    {
        println("---  Loading attaches For element---")
        if let lvNotification = notification
        {
            println("loadAttachesData called from Notification");
        }
        
        DataSource.sharedInstance.loadAttachesForElement(self.element, completion: { [weak self](attaches) -> () in
            
            if !attaches.isEmpty
            {
                println("Loaded Attaches For Element.  : \(attaches.count)")
                if self != nil
                {
                    if let newAttachesHandler = ElementAttachedFilesCollectionHandler(items: attaches)
                    {
                        newAttachesHandler.attachTapDelegate = self
                        self!.tableHandler!.attachesCollectionHandler = newAttachesHandler
                        self!.tableHandler!.displayAttachesTableCellIfNeeded()
                    }
                    
                    let bgQueue = dispatch_queue_create("Origami.AttachesInfoLoading.Queue", DISPATCH_QUEUE_SERIAL)
                    dispatch_async(bgQueue, { [weak self] () -> Void in
                        if self != nil
                        {
                            self!.performLoadingFileDataforAttaches(attaches, completion: { [weak self] (dataDictionary) -> () in
                                
                                if dataDictionary.count > 0
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        
                                        if self != nil
                                        {
                                            self!.tableHandler!.attachesCollectionHandler!.reloadCollectionWithData(dataDictionary)
                                        }
                                    })
                                }
                            })
                        }
                    })
                }
            }
            else
            {
                println(" - No Attaches for element found. -")
            }
        })
    }
    func performLoadingFileDataforAttaches(attaches:[AttachFile], completion completionClosure:([AttachFile:MediaFile])->() )
    {
        var fileDataDict = [AttachFile:MediaFile]()
        var attachesThatNeedToLoadData = [AttachFile]()
        for lvAttachFile in attaches
        {
            if let lvData = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(lvAttachFile)
            {
                // for now we support only images, so all MediaFiles will be ot type .Image
                //TODO: detect file type from file name and set proper MediaFile.type
                var mediaType:FileType = FileType.Document
                if lvAttachFile.fileName != nil
                {
                    let lvFileName = lvAttachFile.fileName! as NSString
                    let pathExpension:NSString = lvFileName.pathExtension
                    
                    if pathExpension.length > 0
                    {
                        if pathExpension.caseInsensitiveCompare("jpg") == .OrderedSame
                        {
                            mediaType = .Image
                        }
                    }
                }
                
                let lvMediaFile = MediaFile()
                lvMediaFile.type = mediaType
                lvMediaFile.name = lvAttachFile.fileName ?? "unknown-image.jpg"
                lvMediaFile.data = lvData
                
                fileDataDict[lvAttachFile] = lvMediaFile
            }
            else
            {
                attachesThatNeedToLoadData.append(lvAttachFile)
            }
        }
        
        if !attachesThatNeedToLoadData.isEmpty
        {
            attachesThatNeedToLoadData.filter({ (lvAttachToCheck) -> Bool in
                if let isAlreadyPendingToLoading = DataSource.sharedInstance.pendingAttachFileDataDownloads[lvAttachToCheck.attachID!]
                {
                    return !isAlreadyPendingToLoading
                }
                return true
            })
            
            println("Not all images are loaded for attaches.  Starting downloading attachment files to disc.")
            
            DataSource.sharedInstance.loadAttachFileDataForAttaches(attachesThatNeedToLoadData, completion: {[weak self] () -> () in
                if self != nil
                {
                    NSNotificationCenter.defaultCenter().postNotificationName("refreshCurrentAttaches", object: nil)
                }
            })
        }
        completionClosure(fileDataDict)
    }
    
    func handleDeletingCurrentElement()
    {
        DataSource.sharedInstance.deleteElementFromServer(element.elementId!.integerValue, completion: { [weak self] (deleted, error) -> () in
            if deleted
            {
                let elementIdInt = self!.element.elementId!.integerValue
                self!.element = Element() //breaking our ling to element in datasource
                DataSource.sharedInstance.deleteElementFromLocalStorage(elementIdInt)
                
                self!.navigationController?.popViewControllerAnimated(true)
            }
            else
            {
                //show error alert
                self!.showAlertWithTitle("Error".localizedWithComment(""), message: "Colud not delete current element".localizedWithComment(""), cancelButtonTitle: "Ok")
            }
        })
    }
    
    func showElementCreationVC(sender:AnyObject)
    {
        //performSegueWithIdentifier("NewElementSegue", sender: self)
        
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            newElementCreator.composingDelegate = self
            newElementCreator.rootElementID = element.elementId!.integerValue
            newElementCreator.modalPresentationStyle = .Custom
            newElementCreator.transitioningDelegate = self
            
            self.presentViewController(newElementCreator, animated: true, completion: nil)
        }
    }
    
    //MARK: ButtonTapDelegate
    func didTapOnButton(button: UIButton) {
        if button.tag == 10
        {
            println("Start attaching file to element.")
            //for now only images supported
            self.performSegueWithIdentifier("ShowImagePicker", sender: self)
        }
        if button.tag == 3
        {
            handleDeletingCurrentElement()
        }
        if button.tag == 2
        {
            showElementCreationVC(self)
        }
    }
    
    //MARK: AttachPickingDelegate
    func mediaPickerDidCancel(picker: AnyObject) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mediaPicker(picker: AnyObject, didPickMediaToAttach mediaFile: MediaFile) {
        DataSource.sharedInstance.attachFile(mediaFile, toElementId: element.elementId!) { (success, error) -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] () -> Void in
                if !success
                {
                    if error != nil
                    {
                        println("Error Adding attach file: \n \(error)")
                    }
                }
                if picker is ImagePickingViewController
                {
                    picker.dismissViewControllerAnimated(true, completion: {[weak self] () -> Void in
                        if self != nil
                        {
                            DataSource.sharedInstance.refreshAttachesForElement(self!.element, completion: {[weak self] (attaches) -> () in
                                if attaches.count > 0
                                {
                                    if self != nil
                                    {
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.5) ), dispatch_get_main_queue(), { () -> Void in
                                            self!.loadAttachesData(nil) //reload data
                                        })
                                        
                                    }
                                }
                            })
                        }
                    })
                }
            })
            
        }
    }
    
    //MARK: AttachmentSelectionDelegate
    func attachedFileTapped(file:AttachFile)
    {
        //if it is image - get full image from disc and display in new view controller
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let lvFileHandler = FileHandler()
            lvFileHandler.loadFileNamed(file.fileName!, completion: { (fileData, loadingError) -> Void in
                if fileData != nil
                {
                    if let imageToDisplay = UIImage(data: fileData)
                    {
                        NSOperationQueue.mainQueue().addOperationWithBlock({ [weak self]() -> Void in
                            if self != nil
                            {
                                self!.fileToDisplay = AttachToDisplay(type: .Image, data: fileData, name:file.fileName!)
                                self!.performSegueWithIdentifier("ShowSelectedImage", sender: nil)
                            }
                        })
                    }
                }
            })
        }
        
    }
    //MARK: Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let lvElement = sender as? Element
        {
            let targetVC = segue.destinationViewController as! ChatVC
            targetVC.currentElement = self.element
        }
//        else if segue.identifier == "ShowTextEditing"
//        {
//            if let targetVC = segue.destinationViewController as? ElementTextEditingVC
//            {
//                targetVC.editingElement = self.element
//                targetVC.isEditingElementTitle = shouldEditTitle
//            }
//        }
        else if segue.identifier == "ShowImagePicker"
        {
            if let mediaVC = segue.destinationViewController as? ImagePickingViewController
            {
                mediaVC.attachPickingDelegate = self
            }
        }
        else if segue.identifier == "ShowSelectedImage"
        {
            if let fileToDisplay = self.fileToDisplay
            {
                switch fileToDisplay.type
                {
                case .Image:
                    if let destinationVC = segue.destinationViewController as? AttachImageViewerVC
                    {
                        destinationVC.imageToDisplay = UIImage(data: fileToDisplay.data)
                        destinationVC.title = fileToDisplay.name
                    }
                case .Document:
                    fallthrough //TODO: Display some external pdf or text viewer or display inside app
                case .Sound:
                    fallthrough //TODO: display VC with music player
                case .Video:
                    fallthrough //TODO: display VC with Video player
                default: break
                }
            }
            
        }
        
    }
    
    //MARK: MessageObserver  KVO
    func newMessagesAdded(messages: [Message]) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            [weak self] () -> Void in
            
            if self != nil
            {
                if self!.tableHandler != nil
                {
                    self!.tableHandler!.lastMessagesTableHandler = ElementChatPreviewTableHandler(messages: messages)
                    self!.tableHandler!.reloadChatMessagesSection()
                }
            }
        }
      
    }
    
    //MARK: ElementComposingDelegate
    
    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        composer.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element) {
        composer.dismissViewControllerAnimated(true, completion: nil)
        handleAddingNewElement(newElement)
    }
    //MARK: -----
    func handleAddingNewElement(element:Element)
    {
        // 1 - send new element to server
        // 2 - send passWhomIDs, if present
        // 3 - if new element successfully added - reload dashboard collectionView
        var passWhomIDs:[Int]?
        if let nsNumberArray = element.passWhomIDs
        {
            passWhomIDs = [Int]()
            for number in nsNumberArray
            {
                passWhomIDs!.append(number.integerValue)
            }
        }
        
        DataSource.sharedInstance.submitNewElementToServer(element, completion: {[weak self] (newElementID, submitingError) -> () in
            if let lvElementId = newElementID
            {
                if let passWhomIDsArray = passWhomIDs
                {
                    
                    DataSource.sharedInstance.addSeveralContacts(passWhomIDsArray, toElement: NSNumber(integer:lvElementId), completion: { (succeededIDs, failedIDs) -> () in
                        if !failedIDs.isEmpty
                        {
                            println(" added to \(succeededIDs)")
                            println(" failed to add to \(failedIDs)")
                        }
                        else
                        {
                            println(" added to \(succeededIDs)")
                        }
                    })
                    if let weakSelf = self
                    {
                        weakSelf.tableHandler?.reloadSubordinateElementsCell()
                    }
                }
                else
                {
                    if let weakSelf = self
                    {
                        weakSelf.tableHandler?.reloadSubordinateElementsCell()
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

    
    
    //MARK: Alert
    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        alertController.addAction(closeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
