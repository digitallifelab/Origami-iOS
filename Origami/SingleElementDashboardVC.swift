//
//  SingleElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDashboardVC: UIViewController, ElementComposingDelegate ,/*UIViewControllerTransitioningDelegate,*/ ElementSelectionDelegate, AttachmentSelectionDelegate, AttachPickingDelegate, UIPopoverPresentationControllerDelegate , UIActionSheetDelegate, MessageTapDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, TableItemPickerDelegate , FinishTaskResultViewDelegate, AttachViewerDelegate {

    //var currentElement:Element?
    var currentElement:DBElement?
    var collectionDataSource:SingleElementCollectionViewDataSource?
    var currentShowingAttachInfo:(fileName:String, id:Int)?
    var newElementDetailsInfo:String?
    var iOS7PopoverController:UIPopoverController?
    
    var displayMode:DisplayMode = .Day {
        didSet{
            let old = oldValue
            if self.displayMode == old
            {
                return
            }
        
            if collectionDataSource != nil
            {
                collectionDataSource?.displayMode = self.displayMode
                
                self.prepareCollectionViewDataAndLayout()
             
            }
        }
    }
    
    var afterViewDidLoad = false
    
    @IBOutlet var collectionView:UICollectionView!
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print(" ->removed observer SingleDashVC from Deinit.")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
     
        //print(" ...viewDidLoad....")
   
       
        //prepare our appearance
        //self.fadeViewControllerAnimator = FadeOpaqueAnimator()
        configureRightBarButtonItem()
        configureNavigationControllerToolbarItems()
        let nightMode = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        setAppearanceForNightModeToggled(nightMode)
        self.displayMode = (nightMode) ? .Night : .Day
        
        afterViewDidLoad = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool)
    {
      
       
        self.navigationController?.delegate = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kNewElementsAddedNotification, object: nil)
        print(" --- Removed From observing new elements added...")
        super.viewWillAppear(animated)
        if afterViewDidLoad
        {
            guard let elementId = self.currentElement?.elementId?.integerValue else
            {
              
//                if let refreshedElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
//                {
//                    self.currentElement = refreshedElement
//                }
                return
            }
            
            self.refreshCurrentElementFromLocalDatabase(elementId)
            
            
            let attachRefreshOp = NSBlockOperation() { _ in

                let semaphore = dispatch_semaphore_create(0)
                DataSource.sharedInstance.refreshAttachesForElement(elementId, completion: { (info) -> () in
                    
                    dispatch_semaphore_signal(semaphore)
                })
            
                let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 5.0))
            
                dispatch_semaphore_wait(semaphore, timeout)
                print("signelled semaphore for refresh attaches queue")
            }
            
            let collectionLayoutMainQueueOp = NSBlockOperation() { [weak self]_ in
                
                print(" prepareCollectionViewDataAndLayout from Operation. ")
                guard let weakSelf = self else {
                    return
                }
                weakSelf.prepareCollectionViewDataAndLayout()
            }
            
            collectionLayoutMainQueueOp.addDependency(attachRefreshOp)
            
            NSOperationQueue().addOperation(attachRefreshOp)
            
            NSOperationQueue.mainQueue().addOperation(collectionLayoutMainQueueOp)
          
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementActionButtonPressed:", name: kElementActionButtonPressedNotification, object: nil)
        
        if let navController = self.navigationController
        {
            navController.delegate = self
        }
        
        self.afterViewDidLoad = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementFavouriteToggled:", name: kElementFavouriteButtonTapped, object: nil)
      
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "startEditingElement:", name: kElementEditTextNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleMoreDetails:", name: kElementMoreDetailsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadingAttachFileDataCompleted:", name: kAttachFileDataLoadingCompleted, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "singleAttachDataWasLoaded:", name: kAttachDataDidFinishLoadingNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementWasDeletedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshCurrentElementAfterElementChangedNotification:", name: kElementWasChangedNotification, object: nil)
        
        
        //debug display root element id in title view
        if let rootElementId = self.currentElement?.rootElementId, elementId = self.currentElement?.elementId
        {
            let elementIdString = "\(elementId)"
            let rootElementIdString = " \(rootElementId)"
            self.title = rootElementIdString + " <- " + elementIdString
        }
        
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementFavouriteButtonTapped, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementActionButtonPressedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementMoreDetailsNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kAttachFileDataLoadingCompleted, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kAttachDataDidFinishLoadingNotification, object:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementWasChangedNotification, object: nil)
        
        if let elementId = self.currentElement?.elementId?.integerValue
        {
            dispatch_async(getBackgroundQueue_SERIAL()){
                do{
                    guard let  attaches = try DataSource.sharedInstance.localDatadaseHandler?.readAttachesForElementById(elementId) else
                    {
                        return
                    }
                    
                    var setOfAttachIDs = Set<Int>()
                    for anAttach in attaches
                    {
                        if let attachId = anAttach.attachId?.integerValue
                        {
                            setOfAttachIDs.insert(attachId)
                        }
                    }
                    DataSource.sharedInstance.cancelDownloadingAttachesByIDs(setOfAttachIDs)}
                catch{
                    return
                }
            }
        }
      
    }
    
    //MARK: Appearance --
    func configureRightBarButtonItem()
    {
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "optionsBarButtonTapped:")
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func configureNavigationControllerToolbarItems()
    {
        let homeButton = UIButton(type:.System)
        homeButton.setImage(UIImage(named: kHomeButtonImageName)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        homeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        homeButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        homeButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        homeButton.addTarget(self, action: "homeButtonPressed:", forControlEvents: .TouchUpInside)

        let homeImageButton = UIBarButtonItem(customView: homeButton)
        
        let flexibleSpaceLeft = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let flexibleSpaceRight = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let currentToolbarItems:[UIBarButtonItem] = [flexibleSpaceLeft, homeImageButton ,flexibleSpaceRight]
        
        //
        self.setToolbarItems(currentToolbarItems, animated: false)
    }
       
    func refreshCurrentElementFromLocalDatabase(elementId:Int)
    {
        if let refreshedElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
        {
            self.currentElement = refreshedElement
        }
    }
    
    //MARK: Day/Night Mode

    /**
    - Establishes new datasource for collectionview, sets current dicplay mode to datasource, assigns self as delegate of tapping on subordinate , attach and message.
    
    - sets **SingleElementCollectionViewDataSource** instance delegate and datasouce of collection view
    - sets new layout if created from current element
    - calls collectionView.reloadData()
    - throws: 
        - an error, containing a string in LocalizedDescription that says, layout coud not be created, 
        - or dataSource for colelctionview could not be created
    
    */
    func prepareCollectionViewDataAndLayout()
    {
//        if let messages = currentElement?.messages as? Set<DBMessageChat>
//        {
//            if !messages.isEmpty
//            {
//                print(" Current element has messages! \(messages.count) ")
//            }
//            else{
//                print("...Current element does not have messages....")
//            }
//        }
        
        
        let currentContentOffset = collectionView.contentOffset
         let dataSource = SingleElementCollectionViewDataSource()//element: currentElement) // both can be nil
                    self.collectionDataSource = dataSource
          
            collectionDataSource!.handledElement = currentElement
            collectionDataSource!.handledCollectionView = self.collectionView
            collectionDataSource!.displayMode = self.displayMode
            collectionDataSource!.subordinateTapDelegate = self
            collectionDataSource!.attachTapDelegate = self
            collectionDataSource!.messageTapDelegate = self
        
            collectionView.dataSource = collectionDataSource!
            collectionView.delegate = collectionDataSource!
        
            collectionView.reloadData()
        
            collectionView.setContentOffset(currentContentOffset, animated: false)

        if let collectionViewLayout = self.prepareCollectionLayoutForElement(collectionDataSource?.handledElement)
        {
            collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
        }
    }
    
    //MARK: Custom CollectionView Layout
    func prepareCollectionLayoutForElement(element:DBElement?) -> SimpleElementDashboardLayout?
    {
        guard let _ = element else
        {
            return nil
        }
        
        if let
            readyDataSource = self.collectionDataSource,
            infoStruct = readyDataSource.getLayoutInfo(),
            aLayout = SimpleElementDashboardLayout(infoStruct: infoStruct)
        {
            print("SingleElementLayoutInfoStruct -> needed number of sections: \(infoStruct.numberOfSections())")
            return aLayout
        }
        
        return nil
    }
    
    //MARK: Handling buttons and other elements tap in collection view
    func startEditingElement(notification:NSNotification?)
    {
        self.collectionView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .Top)
        
        if let
            editingVC = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController ,
            currentEl = self.currentElement,
            elementId = currentEl.elementId?.integerValue,
            rootId = currentElement?.rootElementId?.integerValue,
            selfNav = self.navigationController
        {
            editingVC.editingStyle = .EditCurrent
            editingVC.currentElementId = elementId
            editingVC.rootElementID = rootId
            editingVC.composingDelegate = self
            
            selfNav.pushViewController(editingVC, animated: true)
        }
    }
    
    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        
        if let editingVC = viewController as? NewElementComposerViewController
        {
            if editingVC.editingStyle == .EditCurrent
            {
                //TODO: switch to DBElement
//                if let copyElement = self.currentElement?.createCopy()
//                {
//                    editingVC.newElement = copyElement
//                    //editingVC.editingStyle = .EditCurrent
//                }
            }
        }
        else if viewController == self
        {
            print("\(self.currentElement?.title)")
        }
    }
    
//    func navigationControllerSupportedInterfaceOrientations(navigationController: UINavigationController) -> UIInterfaceOrientationMask {
//        return UIInterfaceOrientationMask.Portrait
//    }
    
    func elementFavouriteToggled(notification:NSNotification)
    {
        if let element = currentElement, elementId = element.elementId?.integerValue, oldFavourite = element.isFavourite?.boolValue
        {
            if element.isArchived()
            {
                self.showAlertWithTitle("Unauthorized", message: "Unarchive element first", cancelButtonTitle: "close".localizedWithComment(""))
                return
            }
            
            let isFavourite = !oldFavourite
           // let elementCopy = Element(info: element.toDictionary())

            DataSource.sharedInstance.updateElement(elementId, isFavourite: isFavourite) { [weak self] (edited) -> () in
                
                if let weakSelf = self
                {
                    if edited
                    {
                        weakSelf.refreshCurrentElementFromLocalDatabase(elementId)
                        weakSelf.setParentElementNeedsUpdateIfPresent()
                        weakSelf.collectionView?.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                    }
                }
                
                
            }
        }
    }
    
    func elementActionButtonPressed(notification:NSNotification?)
    {
        if let notificationUserInfo = notification?.userInfo as? [String:Int], buttonIndex = notificationUserInfo["actionButtonIndex"]
        {
            if let currentButtonType = ActionButtonCellType(rawValue: buttonIndex)
            {
                switch currentButtonType
                {
                case .Edit:
                    elementEditingToggled()
                case .Add:
                    elementAddNewSubordinatePressed()
                case .Delete:
                    elementDeletePressed()
                case .Archive:
                    elementArchivePressed()
                case .Signal:
                    elementSignalToggled()
                case .Task:
                    elementTaskPressed()
                case .Idea:
                    elementIdeaPressed()
                case .Decision:
                    elementDecisionPressed()
                }
            }
            else
            {
                assert(false, "Unknown button type pressed.")
            }
        }
    }
    
    func elementSignalToggled()
    {
        if let theElement = currentElement, elementId = theElement.elementId?.integerValue, oldSignal = theElement.isSignal?.boolValue
        {
            if !theElement.isOwnedByCurrentUser()
            {
                return // Important
            }
            if theElement.isArchived()
            {
                self.showAlertWithTitle("Unauthorized", message: "Unarchive element first", cancelButtonTitle: "close".localizedWithComment(""))
                return
            }
            
            let isSignal = !oldSignal
            let elementCopy = theElement.createCopyForServer()

            elementCopy.isSignal = isSignal
            
            DataSource.sharedInstance.editElement(elementCopy) {[weak self] (edited) -> () in
                if let aSelf = self
                {
                    dispatch_async(dispatch_get_main_queue()) { _ in
                        aSelf.refreshCurrentElementFromLocalDatabase(elementId)
                        if edited
                        {
                            aSelf.setParentElementNeedsUpdateIfPresent()
                            aSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                        }
                        else
                        {
                            aSelf.showAlertWithTitle("Warning.", message: "Could not update SIGNAL value of element.", cancelButtonTitle: "Ok")
                        }
                    }
                }
            }
        }
    }
    
    func elementEditingToggled()
    {
        startEditingElement(nil)
    }
    
    func elementAddNewSubordinatePressed()
    {
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            newElementCreator.editingStyle = .AddNew
            if let anElement = self.currentElement, rootId = anElement.elementId?.integerValue
            {
                newElementCreator.composingDelegate = self
                newElementCreator.rootElementID = rootId//.integerValue
                
                self.navigationController?.pushViewController(newElementCreator, animated: true)
            }
        }
    }
    
    func elementArchivePressed()
    {
        print("Archive element tapped.")
        
        if let element = self.currentElement
        {
            let copyElement = element.createCopyForServer()
            
            let currentDate = NSDate()
            if let string = currentDate.dateForServer()
            {
                let elementId = copyElement.elementId//?.integerValue
                if element.isArchived()
                {
                    //will unarchve
                    copyElement.archiveDate = NSDate.dummyDate()
                }
                else
                {
                    //will archive
                    copyElement.archiveDate = string
                }
                
                dispatch_async(getBackgroundQueue_DEFAULT()) {
                    DataSource.sharedInstance.editElement(copyElement) {[weak self] (edited) -> () in
                        if edited
                        {
                            if let weakSelf = self
                            {
                                dispatch_async(dispatch_get_main_queue()){ _ in
                                    
                                    weakSelf.setParentElementNeedsUpdateIfPresent()
                                    
                                    weakSelf.navigationController?.popViewControllerAnimated(true)
                                    if let int = elementId
                                    {
                                        NSNotificationCenter.defaultCenter().postNotificationName(kElementWasDeletedNotification, object: self, userInfo: ["elementId": NSNumber(integer:int)])
                                    }
                                }
                                
                            }
                        }
                        else
                        {
                            if let weakSelf = self
                            {
                                dispatch_async(dispatch_get_main_queue()) {
                                        weakSelf.showAlertWithTitle("Error", message: "Could not archive current element.", cancelButtonTitle: "Close")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func elementDeletePressed()
    {
        //print("Delete element tapped.")
        handleDeletingCurrentElement()
    }
    
    func elementIdeaPressed()
    {
        print("Idea tapped.")
        if let current = self.currentElement, elementType = current.type?.integerValue
        {
            if !current.isArchived()
            {
                let anOptionsConverter = ElementOptionsConverter()
                let newOptions = anOptionsConverter.toggleOptionChange(elementType, selectedOption: 1)
                let editingElement = current.createCopyForServer() // Element(info: self.currentElement!.toDictionary())
                editingElement.typeId = newOptions
                print("new element type id: \(editingElement.typeId)")
                self.handleEditingElementOptions(editingElement, newOptions: NSNumber(integer: newOptions))
            }
            else
            {
                self.showAlertWithTitle("Unauthorized.", message: "Unarchive element first", cancelButtonTitle: "close".localizedWithComment(""))
            }
        }
        
    }
    
    func elementTaskPressed()
    {
        print(" -> TASK tapped.")
        
        let anOptionsConverter = ElementOptionsConverter()
       
        if let element = self.currentElement
        {
            guard let typeId = element.type?.integerValue, finishState = element.finishState?.integerValue else  { return }
            
            if anOptionsConverter.isOptionEnabled(ElementOptions.Task, forCurrentOptions: typeId)
            {
                
                //1 - detect if element is owned
                //2 - if owned prompt owner to be sure to uncheck TASK
                //3 - if is not owned, but current user is responsible for this TASK
                //4- prompt to mark this TASK as finished with some result, or dismiss
                //5 - if now owned and current user is not responsible - do nothing
                if !element.isArchived()
                {
                    if element.isOwnedByCurrentUser()
                    {
                        //2 - if is owned prompt user to start creating TASK with responsible user and remind date
                        if let currentFinishState = ElementFinishState(rawValue: finishState)
                        {
                            switch currentFinishState
                            {
                            case .Default:
                                showPromptForBeginingAssigningTaskToSomebodyOrSelf(false)
                            case .FinishedBad, .FinishedGood:
                                showPromptForBeginingAssigningTaskToSomebodyOrSelf(true)
                            case .InProcess:
                                print(" Element is in process..\n")
                                showFinishTaskPrompt()
                            }
                        } 
                    }
                    else if element.isTaskForCurrentUser()
                    {
                        if let currentFinishState = ElementFinishState(rawValue: finishState)
                        {
                            switch currentFinishState
                            {
                            case .Default:
                                print("element is not owned. current user cannot assign task.")
                            case .FinishedBad , .FinishedGood:
                                print("element is already finished. current user cannot update task.")
                            case .InProcess:
                                showFinishTaskPrompt()
                            }
                        }
                    }
                }
                else
                {
                    if element.isOwnedByCurrentUser()
                    {
                        self.showAlertWithTitle("Unauthorized.", message: "Unarchive element first", cancelButtonTitle: "close".localizedWithComment(""))
                    }
                }
            }
            else
            {
                if !element.isArchived()
                {
                    //1 - detect if element is owned
                    if element.isOwnedByCurrentUser()
                    {
                        //2 - if is owned prompt user to start creating TASK with responsible user and remind date
                        if let currentFinishState = ElementFinishState(rawValue: finishState)
                        {
                            switch currentFinishState
                            {
                            case .Default:
                                showPromptForBeginingAssigningTaskToSomebodyOrSelf(false)
                            case .FinishedBad , .FinishedGood :
                                showPromptForBeginingAssigningTaskToSomebodyOrSelf(true)
                            case .InProcess:
                                print(" Element is in process..")
                                showFinishTaskPrompt()
                            }
                        }
                        
                        return
                    }
                    print("\n Error: Element is not owned by current user.")
                }
                else
                {
                    if element.isOwnedByCurrentUser()
                    {
                         self.showAlertWithTitle("Unauthorized", message: "Unarchive element first", cancelButtonTitle: "close".localizedWithComment(""))
                    }
                }
            }
        }
    }
    
    func elementDecisionPressed()
    {
        print("Decision tapped.")
        if let current = self.currentElement, type = current.type?.integerValue
        {
            if !current.isArchived()
            {
                let anOptionsConverter = ElementOptionsConverter()
                let newOptions = anOptionsConverter.toggleOptionChange(type, selectedOption: 3)
                let editingElement = current.createCopyForServer()
                editingElement.typeId = newOptions
                print("new element type id: \(editingElement.typeId)")
                self.handleEditingElementOptions(editingElement, newOptions: NSNumber(integer: newOptions))
            }
            else
            {
                self.showAlertWithTitle("Unauthorized", message: "Unarchive element first", cancelButtonTitle: "cancel".localizedWithComment(""))
            }
        }
    }
    
    func toggleMoreDetails(notification:NSNotification?)
    {
        if let simpleLayout = self.collectionView.collectionViewLayout as? SimpleElementDashboardLayout
        {
            simpleLayout.toggleDetailsTextVisibility()
            self.collectionView.reloadSections(NSIndexSet(index: 0))
        }
    }
    //MARK: top left menu popover
    func optionsBarButtonTapped(sender:AnyObject?)
    {
        guard let leftTopMenuPopupVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditingMenuPopupVC") as? EditingMenuPopupVC else
        {
            return
        }
            
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "popoverItemTapped:", name: kPopupMenuItemPressedNotification, object: leftTopMenuPopupVC)
        
        if #available (iOS 8.0, *)
        {
            
            leftTopMenuPopupVC.modalPresentationStyle = UIModalPresentationStyle.Popover
            leftTopMenuPopupVC.modalInPopover = false // `true` disables dismissing popover menu by tapping outside - in faded out parent VC`s view.
            
            let popoverObject = leftTopMenuPopupVC.popoverPresentationController
            popoverObject?.permittedArrowDirections = .Any
            popoverObject?.barButtonItem = self.navigationItem.rightBarButtonItem
            popoverObject?.delegate = self
            
            leftTopMenuPopupVC.preferredContentSize = CGSizeMake(200, 180.0)
            self.presentViewController(leftTopMenuPopupVC, animated: true, completion: nil)
        }
        else
        {
            if FrameCounter.getCurrentInterfaceIdiom() == .Pad
            {
                if let barItem = sender as? UIBarButtonItem
                {
                    let popoverController = UIPopoverController(contentViewController: leftTopMenuPopupVC)
                    popoverController.popoverContentSize = CGSizeMake(200, 180.0)
                    self.iOS7PopoverController = popoverController
                    
                    popoverController.presentPopoverFromBarButtonItem(barItem, permittedArrowDirections: .Any, animated: true)
                }
            }
            else
            {
                let ios7ActionSheet = UIActionSheet(title: "Choose Option", delegate: self, cancelButtonTitle: nil, destructiveButtonTitle: "cancel".localizedWithComment(""))
                
                ios7ActionSheet.addButtonWithTitle("Add Element".localizedWithComment(""))
                ios7ActionSheet.addButtonWithTitle("Add Attachment".localizedWithComment(""))
                ios7ActionSheet.addButtonWithTitle("Chat".localizedWithComment(""))
                
                ios7ActionSheet.showFromToolbar(self.navigationController!.toolbar)
            }
        }
        
    }
    //MARK: top left menu popover action
    func popoverItemTapped(notification:NSNotification?)
    {
        if let note = notification
        {
            NSNotificationCenter.defaultCenter().removeObserver(self, name:note.name, object: notification?.object)
            if let _ = note.object as? EditingMenuPopupVC
            {
                var target:String? = nil
                if let destinationTitle = note.userInfo?["title"] as? String
                {
                    target = destinationTitle
                }
                
                if #available (iOS 8.0, *)
                {
                    self.dismissViewControllerAnimated(false,completion: nil)
                    
                    if target != nil
                    {
                        switch target!
                        {
                        case "Add Element":
                            elementAddNewSubordinatePressed()
                        case "Add Attachment":
                            startAddingNewAttachFile(nil)
                        case "Chat":
                            showChatForCurrentElement()
                        default:
                            break
                        }
                    }
                }
                else
                {
                    if let popover = iOS7PopoverController //iPad
                    {
                        popover.dismissPopoverAnimated(false)
                        self.iOS7PopoverController = nil
                        if let targetString = target
                        {
                            switch targetString
                            {
                            case "Add Element":
                                self.elementAddNewSubordinatePressed()
                            case "Add Attachment":
                                self.startAddingNewAttachFile(nil)
                            case "Chat":
                                self.showChatForCurrentElement()
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: UIPopoverPresentationControllerDelegate
    @available(iOS 8.0, *)
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    //MARK: - UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != actionSheet.cancelButtonIndex
        {
            switch buttonIndex
            {
            case 1:
                elementAddNewSubordinatePressed()
            case 2:
                startAddingNewAttachFile(nil)
            case 3:
                showChatForCurrentElement()
            default:
                break
            }
        }
    }
    

    //MARK: ElementComposingDelegate

    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        //composer.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element) {
        self.navigationController?.popViewControllerAnimated(true)
    
        DataSource.sharedInstance.dataRefresher?.stopRefreshingElements()
        
        switch composer.editingStyle
        {
        case .AddNew:
            handleAddingNewElement(newElement)
        case .EditCurrent:
            handleEditingElement(newElement)
        }
    }
        
    //MARK: -----
    func handleAddingNewElement(element:Element)
    {
        // 1 - send new element to server
        // 3 - if new element successfully added - reload dashboard collectionView
      
        let rootID = element.rootElementId
        if rootID == 0
        {
            print("Some error occured.  Root elementId should be not ZERO")
            return
        }
        // 1
        DataSource.sharedInstance.submitNewElementToServer(element, completion: {[weak self] (newElementID, submitingError) -> () in
            
            dispatch_async(dispatch_get_main_queue()) {
                if let _ = newElementID,  let refreshedElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(rootID)
                {
                    if let weakSelf = self
                    {
                        weakSelf.currentElement = refreshedElement
                        weakSelf.prepareCollectionViewDataAndLayout()
                    }
                }
                else
                {
                    if let weakSelf = self
                    {
                        weakSelf.showAlertWithTitle("ERROR.", message: "Could not create new element.", cancelButtonTitle: "Ok")
                    }
                }
            }
            
            
            if let cancelledValue = DataSource.sharedInstance.dataRefresher?.isCancelled where cancelledValue == true
            {
//                if cancelledValue == true
//                {
                    DataSource.sharedInstance.dataRefresher?.startRefreshingElementsWithTimeoutInterval(30.0)
//                }
            }
            else
            {
                // no data refresher.
            }
        })
    }
    
    func handleEditingElementOptions(element:Element, newOptions:NSNumber)
    {
        guard let elementId = element.elementId else
        {
            return
        }
        
        DataSource.sharedInstance.editElement(element) {[weak self] (edited) -> () in
            if let aSelf = self
            {
                dispatch_async(dispatch_get_main_queue()) { _ in
                    if edited
                    {
                        aSelf.refreshCurrentElementFromLocalDatabase(elementId)
                        aSelf.setParentElementNeedsUpdateIfPresent()
                        aSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                    }
                    else
                    {
                        aSelf.showAlertWithTitle("Warning.", message: "Could not update current element.", cancelButtonTitle: "Ok")
                    }
                }

            }
        }
    }
    
    func handleEditingElement(editingElement:Element)
    {
        
        guard let currentTitle = editingElement.title ,  editedTitle = self.currentElement?.title, currentElementId = self.currentElement?.elementId?.integerValue, editingElementId = editingElement.elementId else
        {
            return
        }
        
        if currentElementId != editingElementId
        {
            return
        }
        
        var shouldEditWholeElement = true
        
        if let details = self.currentElement?.details, editingDetails = editingElement.details
        {
            if currentTitle == editedTitle && details == editingDetails
            {
                //do ton edit the whole element
                shouldEditWholeElement = false
                // perform step 2: edit passWhomIDs if changed
            }
        }
        
        if shouldEditWholeElement
        {
            DataSource.sharedInstance.editElement(editingElement) {[weak self] (edited) -> () in
                if let aSelf = self
                {
                    dispatch_async(dispatch_get_main_queue()) { _ in
                        
                        if edited
                        {
                            if let updatedElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(currentElementId)
                            {
                                aSelf.currentElement = updatedElement
                                aSelf.prepareCollectionViewDataAndLayout()
                                aSelf.setParentElementNeedsUpdateIfPresent()
                            }
                        }
                        else
                        {
                            aSelf.showAlertWithTitle("Warning.", message: "Could not update current element.", cancelButtonTitle: "Ok")
                        }
                    }
                }
                
                if let cancelledValue = DataSource.sharedInstance.dataRefresher?.isCancelled
                {
                    if cancelledValue
                    {
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 2.0))
                        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
                            DataSource.sharedInstance.dataRefresher?.startRefreshingElementsWithTimeoutInterval(30.0)
                        })
                    }
                }
            }
        }

        
        let newPassWhomIDs = Set(editingElement.passWhomIDs)
        guard let existingPassWhonIDs = DataSource.sharedInstance.participantIDsForElement[currentElementId] else
        {
            if newPassWhomIDs.isEmpty
            {
                return
            }
            
            print(" -> handleEditingElement  adding ALL NEW contacts to EDITING element")
            DataSource.sharedInstance.addSeveralContacts(newPassWhomIDs, toElement: editingElementId, completion: nil)
            
            return
        }
        
        
        if newPassWhomIDs.isEmpty && existingPassWhonIDs.isEmpty
        {
            return
        }
        else
        {
            let idsToAdd = newPassWhomIDs.subtract(existingPassWhonIDs)
            let idsToRemove = existingPassWhonIDs.subtract(newPassWhomIDs)
            
            
            let bgOpQueue = NSOperationQueue()
            bgOpQueue.maxConcurrentOperationCount = 2
            
            if !idsToAdd.isEmpty
            {
                print(" handleEditingElement -> Adding new contacts to element: \(idsToAdd)")
                let addOperation = NSBlockOperation() { _ in
                    DataSource.sharedInstance.addSeveralContacts(idsToAdd, toElement: editingElementId, completion: nil)
                }
                
                bgOpQueue.addOperation(addOperation)
            }
            if !idsToRemove.isEmpty
            {
                print(" handleEditingElement -> Removing contacts from element: \(idsToRemove)")
                
                let removeOperation = NSBlockOperation() {_ in
                    DataSource.sharedInstance.removeSeveralContacts(idsToRemove, fromElement: editingElementId, completion: nil)
                }
                
                bgOpQueue.addOperation(removeOperation)
            }
        }
    }
    
    func handleDeletingCurrentElement()
    {
        if let elementId = self.currentElement?.elementId?.integerValue
        {
            DataSource.sharedInstance.deleteElementFromServer(elementId, completion: { [weak self] (deleted, error) -> () in

                DataSource.sharedInstance.localDatadaseHandler?.deleteElementById(elementId, completion: { (didSaveContext, error) -> () in
                    if didSaveContext
                    {
                        
                    }
                    else
                    {
                        
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.setParentElementNeedsUpdateIfPresent()
                            weakSelf.navigationController?.popViewControllerAnimated(true)
                        }
                    })
                })
            })
        }
    }
    //MARK: - 
 
    //MARK: handling notifications
    func elementWasDeleted(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo, _/*deletedElementId*/ = userInfo["elementId"] as? Int
        {
            prepareCollectionViewDataAndLayout()
        }
    }
    
    func refreshSubordinatesAfterNewElementWasAddedFromChatOrChildElement(notification:NSNotification)
    {
        if let info = notification.userInfo, /*elementIdNumbersSet*/ _ = info["IDs"] as? Set<NSNumber>
        {
            //FIXME: delete designated rows from layout and datasource
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.prepareCollectionViewDataAndLayout()
                }
            })
        }
    }
    
    func singleAttachDataWasLoaded(notification:NSNotification)
    {
        if notification.name == kAttachDataDidFinishLoadingNotification
        {
            if let info = notification.userInfo, attachName = info["fileName"] as? String
            {
                print(" -> did Recieve Notification for saving Single attach file: \(attachName)")
//                if let attaches = self.collectionDataSource?.currentAttaches
//                {
//                    if attaches.count > 0
//                    {
                        dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                            if let weakSelf = self
                            {
                                weakSelf.prepareCollectionViewDataAndLayout()
                            }
                        })
//                    }
//                }
            }
        }
    }
    
    func refreshCurrentElementAfterElementChangedNotification(notif:NSNotification?)
    {
        if let currentElement = self.currentElement,
            elementIdInt = currentElement.elementId?.integerValue,
            existingOurElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementIdInt)
        {

            dispatch_async(dispatch_get_main_queue(), { [weak self]() -> Void in
                if let weakSelf = self
                {
                    let oldItemsCount = weakSelf.collectionView.numberOfItemsInSection(0)
                    print("items in section old count: \(oldItemsCount)")
                    weakSelf.currentElement = existingOurElement
                    weakSelf.collectionDataSource?.handledElement = weakSelf.currentElement
                    
                    let newItemsCount = weakSelf.collectionDataSource?.countAllItems()
                    print("items in section newCount: \(newItemsCount)")
                    if oldItemsCount != newItemsCount
                    {
                        weakSelf.prepareCollectionViewDataAndLayout()
                    }
                }
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let aSelf = self
                {
                    aSelf.navigationController?.popToRootViewControllerAnimated(true)
                }
            })
        }
    }
    
    func checkoutParentAndRefreshIfPresent()
    {
        if let navController = self.navigationController
        {
            let currentVCs = navController.viewControllers
            let countVCs = currentVCs.count
            if countVCs > 2 //currently visible a subordinate element dashboard
            {
                if let parentSelf = currentVCs[(countVCs - 1)] as? SingleElementDashboardVC
                {
                    parentSelf.refreshCurrentElementAfterElementChangedNotification(nil)
                }
            }
        }
    }
    
    //MARK: ElementSelectionDelegate
    func didTapOnElement(elementId: Int) {
        if let foundElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
        {
            let nextViewController = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as! SingleElementDashboardVC
            nextViewController.currentElement = foundElement
            self.navigationController?.pushViewController(nextViewController, animated: true)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementWasDeleted:", name:kElementWasDeletedNotification , object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshSubordinatesAfterNewElementWasAddedFromChatOrChildElement:", name: kNewElementsAddedNotification, object: nil)
        }
    
    }
    
    //MARK: AttachmentSelectionDelegate
    func attachedFileTapped(attachFile:AttachFile)
    {
        if attachFile.attachID > 0
        {
            showAttachentDetailsVC(attachFile)
        }
    }
    
    func showAttachentDetailsVC(file:AttachFile)
    {
        self.collectionView.userInteractionEnabled = false
        //if it is image - get full image from disc and display in new view controller
        
        guard let name = file.fileName else
        {
            return
        }
        
        let lvAttachId = file.attachID
        
        guard lvAttachId > 0 else
        {
            return
        }
        
        let lvFileHandler = FileHandler()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            NSOperationQueue().addOperationWithBlock
                { () -> Void in
            
                lvFileHandler.loadFileNamed(name) /* completion:*/ {[weak self] (fileData, loadingError) -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let weakSelf = self
                {
                    weakSelf.collectionView.userInteractionEnabled = true
                }
                
                if let imageData = fileData, _ = UIImage(data: imageData)
                {
                    if let _ = self
                    {
                        if let fileToDisplay = AttachToDisplay(type: .Image, fileData: fileData, fileName:file.fileName, creator: file.creatorID)
                        {
                            dispatch_async(dispatch_get_main_queue(),
                            { [weak self]() -> Void in
                                if let weakSelf = self
                                {
                                    switch fileToDisplay.type
                                    {
                                    case .Image:
                                        if let destinationVC = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("AttachImageViewer") as? AttachImageViewerVC
                                        {
                                            destinationVC.delegate = weakSelf
                                            weakSelf.currentShowingAttachInfo = (fileName:name,id:lvAttachId)
                                            
                                            destinationVC.imageToDisplay = UIImage(data: fileToDisplay.data)
                                            destinationVC.title = fileToDisplay.name
                                            destinationVC.fileCreatorId = fileToDisplay.creatorId // to allow deleting file
                                            weakSelf.navigationController?.pushViewController(destinationVC, animated: true)
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
                            })
                        }
                    }
                }
//                else
//                {
//                    if let weakSelf = self
//                    {
//                        weakSelf.startLoadingDataForMissingAttaches([file])
//                    }
//                }
            }
            }
        
        
    }
    
    //MARK: - AttachViewerDelegate
    func attachViewerShouldAllowDeletion(viewer: UIViewController) -> Bool {

        // Only the Attach Creator can delete files from elements.
        if let attachViewer = viewer as? AttachImageViewerVC, currentUserId = DataSource.sharedInstance.user?.userId
        {
            let fileCreatorId = attachViewer.fileCreatorId
            
            if currentUserId == fileCreatorId
            {
                return true
            }
        }
        
        return false
    }
    
    func attachViewerDeleteAttachButtonTapped(viewer: UIViewController)
    {
        defer {
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        guard let currentAttachInfo = self.currentShowingAttachInfo, elementIdInt = self.currentElement?.elementId?.integerValue else
        {
            return
        }
                
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
            DataSource.sharedInstance.deleteAttachedFileNamed(currentAttachInfo, fromElement: elementIdInt, completion:{[weak self] (success, error) in
                if let weakSelf = self, existingElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementIdInt)
                {
                    weakSelf.currentElement = existingElement
                    weakSelf.prepareCollectionViewDataAndLayout()
                   // weakSelf.collectionDataSource?.deleteAttachByAttachId(attachIdLocal)
                }
            })
        })
    }
    
    func startAddingNewAttachFile(notification:NSNotification?)
    {
        if let attachImagePickerVC = self.storyboard?.instantiateViewControllerWithIdentifier("ImagePickerVC") as? ImagePickingViewController
        {
            attachImagePickerVC.attachPickingDelegate = self
            
            //self.presentViewController(attachImagePickerVC, animated: true, completion: nil)
//            if #available (iOS 8.0, *)
//            {
                self.navigationController?.pushViewController(attachImagePickerVC, animated: true)
//            }
//            else
//            {
//                var vcs = self.navigationController!.viewControllers
//                vcs.append(attachImagePickerVC)
//                
//                self.navigationController!.setViewControllers(vcs, animated: true)
//            }
        }
    }
    
    //MARK: AttachPickingDelegate
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    {
        defer {
             self.navigationController?.popViewControllerAnimated(true)
        }
        
        guard let _ = picker as? ImagePickingViewController , elementId = self.currentElement?.elementId?.integerValue else
        {
            return
        }
        
        DataSource.sharedInstance.attachFile(mediaFile, toElementId: elementId) { (success, error) -> () in
           dispatch_async(dispatch_get_main_queue()) { [weak self]  in
                if !success
                {
                    if let lvError = error as? OrigamiError
                    {
                        print("Error Adding attach file: \n \(error)")
                        if let weakSelf = self
                        {
                            var message = "Unknown Error."
                            
                            switch lvError
                            {
                                case .NotFoundError(message: let aMessage):
                                    message = aMessage ?? "Unknown Error"
                                case .PreconditionFailure(message: let aMessage):
                                    message = aMessage ?? "Unknown Error"
                                case .UnknownError :
                                    break
                            }
                            
                            weakSelf.showAlertWithTitle("Could not attach file:", message: message, cancelButtonTitle: "close".localizedWithComment(""))
                        }
                    }
                    return
                }
                if let aSelf = self//, elementId_ToRefresh = aSelf.currentElement?.elementId?.integerValue
                {
                    aSelf.prepareCollectionViewDataAndLayout()
                }
            }
        }
    }
    
    func mediaPickerDidCancel(picker:AnyObject)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func mediaPickerShouldAllowEditing(picker: AnyObject) -> Bool {
        return false
    }
    
    func mediaPickerPreferredImgeSize(picker: AnyObject) -> CGSize? {
        return CGSizeMake(800.0, 800.0)
    }
    //MARK: Chat stuff
    func showChatForCurrentElement()
    {
        if let chatVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChatVC") as? ChatVC
        {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshSubordinatesAfterNewElementWasAddedFromChatOrChildElement:", name: kNewElementsAddedNotification, object: nil)
            
            print(" -- > Added self to observe new element added\n")
            chatVC.currentElement = self.currentElement
            self.navigationController?.pushViewController(chatVC, animated: true)
            self.afterViewDidLoad = true //later when user returns from chat reload will be triggered - (suppose heor she did  add new subordinate element on a few)
        }
    }
    
    //MARK: - MessageTapDelegate
    func chatMessageWasTapped(message: Message?) {
        showChatForCurrentElement()
    }
    
    //MARK: - Element Task workflow START
    private func showPromptForBeginingAssigningTaskToSomebodyOrSelf(shouldRestart:Bool)
    {
        var alertTitle = "startTaskPrompt".localizedWithComment("")
        var alertMessage = "startTaskMessage".localizedWithComment("")
        let okButtonTitle = "start".localizedWithComment("")
        if shouldRestart
        {
            alertTitle = "restartTaskPrompt".localizedWithComment("")
            alertMessage = "restartTaskMessage".localizedWithComment("")
        }
        let cancelButtonTitle = "cancel".localizedWithComment("")
        
        if #available(iOS 8.0, *)
        {
            let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .Cancel, handler: { (alertAction) -> Void in
                
            })
            
            let startTaskAction = UIAlertAction(title: okButtonTitle, style: .Default, handler: {[weak self] (alertAction) -> Void in
                if let weakSelf = self
                {
                    weakSelf.showStartTaskVC()
                }
                })
            let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
            alertController.addAction(cancelAction)
            alertController.addAction(startTaskAction)
            
            self.presentViewController(alertController, animated: false, completion: { () -> Void in
                
            })
        }
        else
        {
            let alertView = UIAlertView(title: alertTitle, message: alertMessage, delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles: okButtonTitle)
            alertView.tag = 0x7AF1
            alertView.show()
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        
        let alertViewTag = alertView.tag
        if alertViewTag == 0x7AF1
        {
            if alertView.cancelButtonIndex != buttonIndex
            {
                showStartTaskVC()
            }
        }
    }
    
    private func showStartTaskVC()
    {
        // when current user is owner of currentElement
        if let _ = self.currentElement
        {
            DataSource.sharedInstance.localDatadaseHandler?.readAllMyContacts({[weak self] (myContacts) -> () in
                if let weakSelf = self, myContactsPresent = myContacts
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let contactsPicker = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("ContactsPickerVC") as? ContactsPickerVC
                        {
                            contactsPicker.delegate = weakSelf
                            
                            contactsPicker.ableToPickFinishDate = true
                            
                            contactsPicker.contactsToSelectFrom = myContactsPresent
                            
                            weakSelf.navigationController?.pushViewController(contactsPicker, animated: true)
                        }
                    })
                }
            })
        }
    }
    
    private func showFinishTaskPrompt()
    {
        //when current user is responsible for TASK finishing (either he is owner of currentElement or not)
        
        //show popup with dismiss button and "good"-"bad" buttons
        
//        if let prompt = NSBundle.mainBundle().loadNibNamed("FinishTaskResultView", owner: nil, options: nil).first as? FinishTaskResultView
//        {
//            
//        }
        //let prompt = FinishTaskResultView.instance()
        let prompt = FinishTaskResultView(frame: CGRectMake(0, 0, 300.0, 200.0))
        prompt.center = CGPointMake( CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds) )
        prompt.delegate = self
        prompt.titleLabel?.text = "FinishTaskPromptText".localizedWithComment("")
        
        self.view.addSubview(prompt)
        prompt.showAnimated(true)
    }
    
    //MARK: FinishTaskResultViewDelegate
    func finishTaskResultViewDidCancel(resultView: FinishTaskResultView!) {
        resultView.hideAnimated(true)
    }
    
    func finishTaskResultViewDidPressBadButton(resultView: FinishTaskResultView!) {
        resultView.hideAnimated(true)
        
        self.finishElementWithFinishState(.FinishedBad)
    }
    
    func finishTaskResultViewDidPressGoodButton(resultView: FinishTaskResultView!) {
        resultView.hideAnimated(true)
        
        self.finishElementWithFinishState(.FinishedGood)

    }
    
    func finishElementWithFinishState(state:ElementFinishState)
    {
        if let current = self.currentElement, elementIdInt = current.elementId?.integerValue
        {
            let finishState = state.rawValue
            DataSource.sharedInstance.setElementFinishState(elementIdInt, newFinishState: finishState, completion: {[weak self] (edited) -> () in
                if edited
                {
                    DataSource.sharedInstance.setElementFinishDate(elementIdInt, date: NSDate(), completion: {[weak self] (success) -> () in
                        if let weakSelf = self
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                weakSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                                weakSelf.checkoutParentAndRefreshIfPresent()
                            })
                            if !success
                            {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    weakSelf.showAlertWithTitle("Warning", message:" Finish date was not set", cancelButtonTitle: "close".localizedWithComment(""))
                                })
                            }
                        }
                    })
                }
            })
        }
    }
    
    
    
    //MARK: TableItemPickerDelegate
    func itemPickerDidCancel(itemPicker: AnyObject) {
        //did
        
        if let contactsPickerVC = itemPicker as? ContactsPickerVC,  userId = DataSource.sharedInstance.user?.userId, finishDate = contactsPickerVC.finishDate
        {
            do
            {
                try sendElementTaskNewResponsiblePerson(userId, finishDate:finishDate)
            }
            catch let error
            {
                print(error)
            }
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject) {
        if let contactsPickerVC = itemPicker as? ContactsPickerVC, contactPicked = item as? DBContact, contactId = contactPicked.contactId?.integerValue, finishDate = contactsPickerVC.finishDate
        {
            do
            {
                try sendElementTaskNewResponsiblePerson(contactId, finishDate:finishDate)
            }
            catch let error
            {
                print(error)
            }
        }
       
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    
    //MARK: -
    /**
     Sends "*editElement*" to server with updated "*responsible*" value and "*typeId*" value.
        - if successfull sends "*setElementFinishState*" if previous query for editing element was successfull
        - if successfull sends "*setElementFinishDate*" to server
     
     - Precondition: `responsiblePersonId` shoild be more than zero

    */
    private func sendElementTaskNewResponsiblePerson(responsiblePersonId:Int, finishDate:NSDate) throws
    {
        guard responsiblePersonId > 0 else
        {
            let error:ErrorType = OrigamiError.PreconditionFailure(message: "responsiblePersonId is not more than zero.")
            throw error
        }
        
        guard let element = self.currentElement else
        {
            let error = OrigamiError.PreconditionFailure(message: "Curent element not found.")
            throw error
        }
        
        guard let elementId = element.elementId?.integerValue else
        {
            let error = OrigamiError.PreconditionFailure(message: "Current Element Id not found.")
            throw error
        }
        
        let copy = element.createCopyForServer()
        copy.responsible =  responsiblePersonId
        copy.finishDate = finishDate
        let optionsConverter = ElementOptionsConverter()
        
        if !optionsConverter.isOptionEnabled(ElementOptions.Task, forCurrentOptions: copy.typeId)
        {
            let newOptions = optionsConverter.toggleOptionChange(copy.typeId, selectedOption: 2)
            copy.typeId = newOptions
        }

        let newState = ElementFinishState.InProcess.rawValue
        copy.finishState = newState
        
        var operations = [NSBlockOperation]()
        
        let editingOp = NSBlockOperation() { _ in
            
            print(" -> sendElementTaskNewResponsiblePerson    Setting New Element Responsible AND Task Type ...")
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let editingSemaphore = dispatch_semaphore_create(0)
            
            DataSource.sharedInstance.editElement(copy) {[weak self] (edited) -> () in
                if edited
                {
                    if let weakSelf = self
                    {
                        dispatch_async(dispatch_get_main_queue()) { _ in
                            if let editedElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementId)
                            {
                                weakSelf.currentElement = editedElement
                                
                                weakSelf.prepareCollectionViewDataAndLayout()
//                                weakSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                            }
                            weakSelf.checkoutParentAndRefreshIfPresent() //for immediate refreshing parent`s subordinates sells if any
                        }
                    }
                }
                
                dispatch_semaphore_signal(editingSemaphore)
            }
            
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 5.0))
            
            dispatch_semaphore_wait(editingSemaphore, timeout)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
        
        operations.append(editingOp)
        
        if let lvFinishDateToSet = copy.finishDate//?.dateForRequestURL()
        {
            let setFinishDateOp = NSBlockOperation() { _ in
                
                print(" -> sendElementTaskNewResponsiblePerson    Setting New Element Finish Date ...")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                DataSource.sharedInstance.setElementFinishDate(elementId, date: lvFinishDateToSet) { [weak self] (success) -> () in
                    
                    if let _ = self
                    {
                        if success
                        {
                            print(" -> sendElementTaskNewResponsiblePerson -> Element finish date WAS UPDATED.\n")
                        }
                        else
                        {
                            print(" -> sendElementTaskNewResponsiblePerson -> Element finish date WAS NOT updated.\n")
                        }
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
            }
            
            setFinishDateOp.addDependency(editingOp)
            
            operations.append(setFinishDateOp)
        }
        
        let bgQueue = NSOperationQueue()
        bgQueue.maxConcurrentOperationCount = 2
        
        bgQueue.addOperations(operations, waitUntilFinished: false)
       
    }
    
    //MARK: Element Task workflow FINISH -
}
