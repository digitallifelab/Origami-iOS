//
//  SingleElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDashboardVC: UIViewController, ElementComposingDelegate ,UIViewControllerTransitioningDelegate, ElementSelectionDelegate, AttachmentSelectionDelegate, AttachPickingDelegate, UIPopoverPresentationControllerDelegate , MessageTapDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, TableItemPickerDelegate , FinishTaskResultViewDelegate, AttachViewerDelegate {

    var currentElement:Element?
    var collectionDataSource:SingleElementCollectionViewDataSource?
    var fadeViewControllerAnimator:FadeOpaqueAnimator?
    var currentShowingAttachName:String = ""
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
    @IBOutlet var navigationBackgroundView:UIView!
    
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
        self.fadeViewControllerAnimator = FadeOpaqueAnimator()
        configureRightBarButtonItem()
        configureNavigationControllerToolbarItems()
        let nightMode = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
        setAppearanceForNightModeToggled(nightMode)
        self.displayMode = (nightMode) ? .Night : .Day
       
        
        
        if let ourElementIdInt = self.currentElement?.elementId?.integerValue
        {
            DataSource.sharedInstance.loadPassWhomIdsForElement(ourElementIdInt, comlpetion: {[weak self] (finished) -> () in
                // background queue here
                if let aSelf = self
                {
                    if finished
                    {
                        print("Pass whom ids after. \(aSelf.currentElement?.passWhomIDs)")
                        aSelf.currentElement = DataSource.sharedInstance.getElementById(ourElementIdInt)
                        print("pass Whom IDs new: \(aSelf.currentElement?.passWhomIDs)")
                    }
                    else
                    {
                        
                    }
                }
            })
        }
        
       // prepareCollectionViewDataAndLayout()
        
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
            prepareCollectionViewDataAndLayout()
            afterViewDidLoad = false
        }
        
        let currentAttachesInDataSource = DataSource.sharedInstance.getAttachesForElementById(self.currentElement?.elementId)
        print("\n Refreshing attaches in viewWillAppear...")
        if let elementIdInt = self.currentElement?.elementId?.integerValue
        {
            DataSource.sharedInstance.refreshAttachesForElement(elementIdInt, completion: { [weak self] (attachesArray) -> () in
                if let weakSelf = self
                {
                    if let recievedAttaches = attachesArray
                    {
                        if let existAttaches = currentAttachesInDataSource
                        {
                            let setOfExisting = Set(existAttaches)
                            let setOfNew = Set(recievedAttaches)
                            
                            let remainderSet = setOfNew.subtract(setOfExisting)
                            if remainderSet.isEmpty
                            {
                                print("-> No new attach files loaded")
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                    print("\n Starting to Query attach previews in background..")
                                    weakSelf.startLoadingDataForMissingAttaches(recievedAttaches)
                                })
                                
                            }
                            else
                            {
                                print("-> Loaded \(remainderSet.count) new attaches")
                                weakSelf.prepareCollectionViewDataAndLayout()
                                
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                                    print("\n Starting to Query EXIST attachInfo previews in background..")
                                    weakSelf.startLoadingDataForMissingAttaches(existAttaches)
                                })
                                
                            }
                            
                        }
                        else
                        {
                            weakSelf.prepareCollectionViewDataAndLayout()
                        }
                    }
                    
                }
                })

        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementActionButtonPressed:", name: kElementActionButtonPressedNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementFavouriteToggled:", name: kElementFavouriteButtonTapped, object: nil)
      
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "startEditingElement:", name: kElementEditTextNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleMoreDetails:", name: kElementMoreDetailsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadingAttachFileDataCompleted:", name: kAttachFileDataLoadingCompleted, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "singleAttachDataWasLoaded:", name: kAttachDataDidFinishLoadingNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementWasDeletedNotification, object: nil)
        
        let chatPath = NSIndexPath(forItem: 1, inSection: 0)
        let chatCell = self.collectionView.cellForItemAtIndexPath(chatPath) as? SingleElementLastMessagesCell
        if let elementId = self.currentElement?.elementId?.integerValue
        {
            let currentLastMessages = DataSource.sharedInstance.getChatPreviewMessagesForElementId(elementId) //Optional
            if chatCell == nil && currentLastMessages != nil
            {
                prepareCollectionViewDataAndLayout()
            }
            else if let cell = chatCell, messages = currentLastMessages
            {
                if messages.last !== cell.messages?.last
                {
                    chatCell!.messages = messages
                    self.collectionView.reloadItemsAtIndexPaths([chatPath])
                }
            }
        }
        
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementFavouriteButtonTapped, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementActionButtonPressedNotification, object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementEditTextNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementMoreDetailsNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kAttachFileDataLoadingCompleted, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kAttachDataDidFinishLoadingNotification, object:nil)
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
        homeButton.setImage(UIImage(named: "icon-home-SH")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
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

    
    
    func queryAttachesDataAndShowAttachesCellOnCompletion()
    {
        let bgQueue = dispatch_queue_create("Attaches.Request.Queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue, {[weak self] () -> Void in
            if let weakSelf = self
            {
                if let existingAttaches = DataSource.sharedInstance.getAttachesForElementById(weakSelf.currentElement?.elementId)
                {
                    if let attachesHandler = ElementAttachedFilesCollectionHandler(items: existingAttaches)
                    {
                        weakSelf.collectionDataSource?.attachesHandler = attachesHandler
                        weakSelf.collectionDataSource?.handledElement = weakSelf.currentElement
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakSelf.collectionView.dataSource = weakSelf.collectionDataSource
                        weakSelf.collectionView.delegate = weakSelf.collectionDataSource
                        weakSelf.collectionView.reloadData()
                        
                        if let layout = weakSelf.prepareCollectionLayoutForElement(weakSelf.currentElement)
                        {
                            weakSelf.collectionView.setCollectionViewLayout(layout, animated: true)
                        }
                        else
                        {
                            print(" ERROR . \nCould not generate new layout for loaded attaches.")
                        }
                    })
                    print("\n SingleElementDashboardVC. ONLY FOE EXISTING INFO - startLoadingDataForMissingAttaches. \n")
                    weakSelf.startLoadingDataForMissingAttaches(existingAttaches)
                    return
                }
                // - else
                if let weakerSelf = self
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakerSelf.prepareCollectionViewDataAndLayout()
                    })
                    
                    
                    
                    if let elementId = weakerSelf.currentElement?.elementId?.integerValue
                    {
                        DataSource.sharedInstance.loadAttachesInfoForElement(elementId, completion: { [weak self](attaches) -> () in
                            
                            if let arrayOfAttaches = attaches
                            {
                                if !arrayOfAttaches.isEmpty
                                {
                                    if let weakSelf = self
                                    {
                                        print("\n--> recieved \(arrayOfAttaches.count) attaches for current element\n")
                                        if let _ = weakSelf.collectionDataSource?.getElementAttachesHandler()
                                        {
                                            if let attachesCellPath = weakSelf.collectionDataSource?.indexPathForAttachesCell()
                                            {
                                                weakSelf.collectionView.reloadItemsAtIndexPaths([attachesCellPath])
                                            }
                                            //return
                                        }
                                        if let attachesHandler = ElementAttachedFilesCollectionHandler(items: arrayOfAttaches)
                                        {
                                            weakSelf.collectionDataSource?.attachesHandler = attachesHandler
                                            //attachesHandler.startLoadingAllAttachedFileData()
                                        }
                                        
                                        weakSelf.collectionDataSource?.handledElement = weakSelf.currentElement
                                        
                                        weakSelf.collectionView.dataSource = weakSelf.collectionDataSource
                                        weakSelf.collectionView.delegate = weakSelf.collectionDataSource
                                        weakSelf.collectionView.reloadData()
                                        
                                        if let layout = weakSelf.prepareCollectionLayoutForElement(weakSelf.currentElement)
                                        {
                                            weakSelf.collectionView.setCollectionViewLayout(layout, animated: false)
                                            weakSelf.collectionView.reloadData()
                                        }
                                        else
                                        {
                                            print(" ERROR . \nCould not generate new layout for loaded attaches.")
                                            
                                        }
                                        
                                        print("\n SingleElementDashboardVC. FOR FRESHLY DOWNLOADED INFO startLoadingDataForMissingAttaches. \n")
                                        weakSelf.startLoadingDataForMissingAttaches(arrayOfAttaches)
                                    }
                                }
                                else
                                {
                                    print("\n-->Loaded Empty Attaches array for current element\n")
                                    weakSelf.prepareCollectionViewDataAndLayout()
                                }
                            }
                            else
                            {
                                print("\n-->Loaded No Attaches for current element\n")
                                weakSelf.prepareCollectionViewDataAndLayout()
                            }
                        })

                    }
                }
            }
        })
      
        
    }
    
    func startLoadingDataForMissingAttaches(attaches:[AttachFile])
    {
        DataSource.sharedInstance.loadAttachFileDataForAttaches(attaches, completion:nil)
    }
    
    
    
    //MARK: Day/Night Mode

    func prepareCollectionViewDataAndLayout()
    {
        collectionDataSource = SingleElementCollectionViewDataSource(element: currentElement) // both can be nil
        collectionDataSource?.handledElement = currentElement
        collectionDataSource?.displayMode = self.displayMode
        collectionDataSource?.subordinateTapDelegate = self
        collectionDataSource?.attachTapDelegate = self
        collectionDataSource?.messageTapDelegate = self
        
        if collectionDataSource != nil
        {
            collectionView.dataSource = collectionDataSource!
            collectionView.delegate = collectionDataSource!
            
            if let layout = self.prepareCollectionLayoutForElement(self.currentElement)
            {
                self.collectionView.setCollectionViewLayout(layout, animated: false)
            }
            else
            {
                print(" ! -> Some error occured while reloading collectionView with new lyout.")
            }
            collectionView.performBatchUpdates({ () -> Void in
                
            }, completion: {[weak self] (finished) -> Void in
                if let weakSelf = self
                {
                    weakSelf.collectionView.reloadData()
                }
            })

        }
    }
    
    //MARK: Custom CollectionView Layout
    func prepareCollectionLayoutForElement(element:Element?) -> SimpleElementDashboardLayout?
    {
        if element == nil
        {
            return nil
        }
        
        if let readyDataSource = self.collectionDataSource
        {
            if let infoStruct = readyDataSource.getLayoutInfo()
            {
                if let layout = SimpleElementDashboardLayout(infoStruct: infoStruct)
                {
                    return layout
                }
            }
        }
        return nil
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
    
    //MARK: Handling buttons and other elements tap in collection view
    func startEditingElement(notification:NSNotification?)
    {
        if let
            editingVC = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController ,
            currentEl = self.currentElement,
            selfNav = self.navigationController
        {
            editingVC.rootElementID = currentEl.rootElementId.integerValue
            editingVC.composingDelegate = self
            selfNav.delegate = self
            self.collectionView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .Top)
            #if (arch(i386) || arch(x86_64)) && os(iOS) //detect iOS Simulator, because of some unknown bug
                var currentVCs = selfNav.viewControllers
                currentVCs.append(editingVC)
                //selfNav.viewControllers = currentVCs
                selfNav.setViewControllers( currentVCs, animated: true)
                //arghhh. !  Still does not work in simulator
                #else
                selfNav.pushViewController(editingVC, animated: true)
            #endif
        }
    }
    
    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        if let editingVC = viewController as? NewElementComposerViewController
        {
            if let copyElement = self.currentElement?.createCopy()
            {
                editingVC.newElement = copyElement
                editingVC.editingStyle = .EditCurrent
            }
        }
    }
    
    func elementFavouriteToggled(notification:NSNotification)
    {
        if let element = currentElement, _ = element.elementId?.integerValue
        {
            if element.isArchived()
            {
                self.showAlertWithTitle("Unauthorized", message: "Unarchive element first", cancelButtonTitle: "close".localizedWithComment(""))
                return
            }
            let favourite = element.isFavourite.boolValue
            let isFavourite = !favourite
            let elementCopy = Element(info: element.toDictionary())

            DataSource.sharedInstance.updateElement(elementCopy, isFavourite: isFavourite) { [weak self] (edited) -> () in
                
                if let weakSelf = self
                {
                    if edited
                    {
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
        //print("Signal element toggled.")
        
        if let theElement = currentElement
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
            
            let isSignal = theElement.isSignal.boolValue
            let elementCopy = theElement.createCopy()
            let isCurrentlySignal = !isSignal
            elementCopy.isSignal = isCurrentlySignal
            
            DataSource.sharedInstance.editElement(elementCopy, completionClosure: {[weak self] (edited) -> () in
                if let aSelf = self
                {
                    if edited
                    {
                        aSelf.currentElement?.isSignal = isCurrentlySignal
                        aSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                    }
                    else
                    {
                        aSelf.showAlertWithTitle("Warning.", message: "Could not update SIGNAL value of element.", cancelButtonTitle: "Ok")
                    }
                }
            })
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
            if let elementId = currentElement?.elementId
            {
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
//                newElementCreator.modalPresentationStyle = .Custom
//                newElementCreator.transitioningDelegate = self

                self.navigationController?.pushViewController(newElementCreator, animated: true)
//                self.presentViewController(newElementCreator, animated: true, completion: { () -> Void in
//                    newElementCreator.editingStyle = .AddNew
//                })
            }
        }
    }
    
    func elementArchivePressed()
    {
        print("Archive element tapped.")
        
        if let element = self.currentElement
        {
            let copyElement = element.createCopy()
            let currentDate = NSDate()
            if let string = currentDate.dateForServer()
            {
                let elementId = copyElement.elementId?.integerValue
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
                DataSource.sharedInstance.editElement(copyElement,
                    completionClosure:{[weak self] (edited) -> () in
                    if edited
                    {
                        if let weakSelf = self
                        {
                            weakSelf.navigationController?.popViewControllerAnimated(true)
                            if let int = elementId
                            {
                                NSNotificationCenter.defaultCenter().postNotificationName(kElementWasDeletedNotification, object: self, userInfo: ["elementId": NSNumber(integer:int)])
                            }
                        }
                    }
                })
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
        if let current = self.currentElement
        {
            if !current.isArchived()
            {
                
                let anOptionsConverter = ElementOptionsConverter()
                let newOptions = anOptionsConverter.toggleOptionChange(self.currentElement!.typeId.integerValue, selectedOption: 1)
                let editingElement = current.createCopy() // Element(info: self.currentElement!.toDictionary())
                editingElement.typeId = NSNumber(integer: newOptions)
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
        print("CheckMark tapped.")
        
        let anOptionsConverter = ElementOptionsConverter()
       
        if let element = self.currentElement
        {
            if anOptionsConverter.isOptionEnabled(ElementOptions.Task, forCurrentOptions: element.typeId.integerValue)
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
                        if let currentFinishState = ElementFinishState(rawValue: element.finishState.integerValue)
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
                        if let currentFinishState = ElementFinishState(rawValue: element.finishState.integerValue)
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
                        if let currentFinishState = ElementFinishState(rawValue: element.finishState.integerValue)
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
        if let current = self.currentElement
        {
            if !current.isArchived()
            {
                let anOptionsConverter = ElementOptionsConverter()
                let newOptions = anOptionsConverter.toggleOptionChange(current.typeId.integerValue, selectedOption: 3)
                let editingElement = current.createCopy()
                editingElement.typeId = NSNumber(integer: newOptions)
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
        if let leftTopMenuPopupVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditingMenuPopupVC") as? EditingMenuPopupVC
        {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "popoverItemTapped:", name: "PopupMenuItemPressed", object: leftTopMenuPopupVC)
            
            if #available (iOS 8.0, *)//FrameCounter.isLowerThanIOSVersion("8.0")
            {
                
                leftTopMenuPopupVC.modalPresentationStyle = UIModalPresentationStyle.Popover
                leftTopMenuPopupVC.modalInPopover = false//true // true disables dismissing popover menu by tapping outside - in faded out parent VC`s view.
                
                
                //var aPopover:UIPopoverController = UIPopoverController(contentViewController: leftTopMenuPopupVC)
                let popoverObject = leftTopMenuPopupVC.popoverPresentationController
                popoverObject?.permittedArrowDirections = .Any
                popoverObject?.barButtonItem = self.navigationItem.rightBarButtonItem
                popoverObject?.delegate = self
                
                //leftTopMenuPopupVC.popoverPresentationController?.sourceRect = CGRectMake(0, 0, 200, 160.0)
                leftTopMenuPopupVC.preferredContentSize = CGSizeMake(200, 180.0)
                self.presentViewController(leftTopMenuPopupVC, animated: true, completion: { () -> Void in
                    
                })

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
                    self.presentViewController(leftTopMenuPopupVC, animated: true, completion: nil)
                }
                
            }
        }
    }
    //MARK: top left menu popover action
    func popoverItemTapped(notification:NSNotification?)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "PopupMenuItemPressed", object: notification?.object)
        if let note = notification
        {
            if let _ = note.object as? EditingMenuPopupVC
            {
                var target:String? = nil
                if let destinationTitle = note.userInfo?["title"] as? String
                {
                    target = destinationTitle
                }
                if let popover = iOS7PopoverController
                {
                    popover.dismissPopoverAnimated(true)
                    self.iOS7PopoverController = nil
                    if target != nil
                    {
                        switch target!
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
                else
                {
                    self.dismissViewControllerAnimated(true, completion: { [weak self]() -> Void in
                        if let weakSelf = self
                        {
                            if target != nil
                            {
                                switch target!
                                {
                                case "Add Element":
                                    weakSelf.elementAddNewSubordinatePressed()
                                case "Add Attachment":
                                    weakSelf.startAddingNewAttachFile(nil)
                                case "Chat":
                                    weakSelf.showChatForCurrentElement()
                                default:
                                    break
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    //MARK: UIPopoverPresentationControllerDelegate
    @available(iOS 8.0, *)
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    //MARK: ElementComposingDelegate

    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        //composer.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element) {
        self.navigationController?.popViewControllerAnimated(true)
        
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
        // 2 - send passWhomIDs, if present
        // 3 - if new element successfully added - reload dashboard collectionView
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
        
        // 1
        DataSource.sharedInstance.submitNewElementToServer(element, completion: {[weak self] (newElementID, submitingError) -> () in
            if let lvElementId = newElementID
            {
                if let passWhomIDsArray = passWhomIDs // 2
                {
                    let passWhomSet = Set(passWhomIDsArray)
                    DataSource.sharedInstance.addSeveralContacts(passWhomSet, toElement: lvElementId, completion: { (succeededIDs, failedIDs) -> () in
                        if !failedIDs.isEmpty
                        {
                            print(" added to \(succeededIDs)")
                            print(" failed to add to \(failedIDs)")
                            if let weakSelf = self
                            {
                                weakSelf.showAlertWithTitle("ERROR.", message: "Could not add contacts to new element.", cancelButtonTitle: "Ok")
                            }
                        }
                        else
                        {
                            print(" added to \(succeededIDs)")
                        }
                    })
                    
                    if let weakSelf = self // 3
                    {
                        weakSelf.prepareCollectionViewDataAndLayout()
                    }
                }
                else // 3
                {
                    if let weakSelf = self
                    {
                       weakSelf.prepareCollectionViewDataAndLayout()
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
    
    func handleEditingElementOptions(element:Element, newOptions:NSNumber)
    {
        DataSource.sharedInstance.editElement(element, completionClosure: {[weak self] (edited) -> () in
            if let aSelf = self
            {
                if edited
                {
                    aSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                }
                else
                {
                    aSelf.showAlertWithTitle("Warning.", message: "Could not update current element.", cancelButtonTitle: "Ok")
                }
            }
            })
    }
    
    func handleEditingElement(editingElement:Element)
    {
//        var hasDetails = false
//        if let _ = self.currentElement?.details as? String
//        {
//            hasDetails = true
//        }
        DataSource.sharedInstance.editElement(editingElement, completionClosure: {[weak self] (edited) -> () in
            if let aSelf = self
            {
                if edited
                {
                    aSelf.currentElement?.title = editingElement.title
                    aSelf.currentElement?.details = editingElement.details
                    
                    aSelf.collectionDataSource?.handledElement = aSelf.currentElement
                   
                    //aSelf.collectionView.collectionViewLayout.invalidateLayout()
                    if let layout = aSelf.prepareCollectionLayoutForElement(aSelf.currentElement)
                    {
                        aSelf.collectionView.setCollectionViewLayout(layout, animated: false)
                    }
                    aSelf.collectionView.performBatchUpdates({ () -> Void in
                        aSelf.collectionView.reloadSections(NSIndexSet(index: 0))
                    }, completion: { ( _ ) -> Void in
                        
                    })
                    
                    
                }
                else
                {
                    aSelf.showAlertWithTitle("Warning.", message: "Could not update current element.", cancelButtonTitle: "Ok")
                }
            }
        })
        
        
        
        let newPassWhomIDs = editingElement.passWhomIDs
        let existingPassWhonIDs = self.currentElement!.passWhomIDs
        
        if newPassWhomIDs.isEmpty && existingPassWhonIDs.isEmpty
        {
            return
        }
        
        //prepare sets for later use
        var newIDsSet = Set<Int>()
        for aNumber in newPassWhomIDs
        {
            newIDsSet.insert(aNumber.integerValue)
        }
        
        var existingIDsSet = Set<Int>()
        for aNumber in existingPassWhonIDs
        {
            existingIDsSet.insert(aNumber.integerValue)
        }
        
        if existingPassWhonIDs.isEmpty && !newPassWhomIDs.isEmpty
        {
            // add contacts to element
            DataSource.sharedInstance.addSeveralContacts(newIDsSet, toElement: editingElement.elementId!.integerValue, completion: {[weak self] (succeededIDs, failedIDs) -> () in
                print("\n----->ContactIDs ADDED: \n \(succeededIDs)\n failed to ADD:\(failedIDs)")
                if let aSelf = self
                {
                    aSelf.currentElement?.passWhomIDs = Array(newPassWhomIDs)
                }
                
            })
        }
        else if !existingPassWhonIDs.isEmpty && newPassWhomIDs.isEmpty
        {
            //remove all contacts from element
            DataSource.sharedInstance.removeSeveralContacts(existingIDsSet, fromElement: editingElement.elementId!.integerValue, completion: {[weak self] (succeededIDs, failedIDs) -> () in
                print("\n----->ContactIDs REMOVED: \n \(succeededIDs)\n failed to REMOVE:\(failedIDs)")
                if let aSelf = self
                {
                    aSelf.currentElement?.passWhomIDs.removeAll(keepCapacity: false)
                }
            })
        }
        else
        {
            let allContactIDsSet = existingIDsSet.union(newIDsSet)
            let contactIDsToRemoveSet = allContactIDsSet.subtract(newIDsSet)
            
            if !contactIDsToRemoveSet.isEmpty
            {
                //remove all contacts from element
                DataSource.sharedInstance.removeSeveralContacts(contactIDsToRemoveSet,
                                                                        fromElement: editingElement.elementId!.integerValue,
                                                                         completion: { [weak self](succeededIDs, failedIDs) -> () in
                                                                            
                    print("\n----->ContactIDs REMOVED: \n \(succeededIDs)\n failed to REMOVE:\(failedIDs)")
                                                                            
                    if let aSelf = self
                    {
                        var numbersSet = Set<NSNumber>()
                        for anInt in contactIDsToRemoveSet
                        {
                            numbersSet.insert(NSNumber(integer: anInt))
                        }
                        let newSet = Set(existingPassWhonIDs).subtract(numbersSet)
                        
                        aSelf.currentElement?.passWhomIDs = Array(newSet)
                    }
                })
            }
            
         
            
            if !newIDsSet.isEmpty && newIDsSet.isDisjointWith(existingIDsSet)
            {
                // add contacts to element
                DataSource.sharedInstance.addSeveralContacts(newIDsSet,
                                                            toElement: editingElement.elementId!.integerValue,
                                                           completion: {[weak self] (succeededIDs, failedIDs) -> () in
                        
                    print("\n----->ContactIDs ADDED: \n \(succeededIDs)\n failed to ADD:\(failedIDs)")
                    
                    if let aSelf = self
                    {
                        var numbersSet = Set<NSNumber>()
                        for anInt in newIDsSet
                        {
                            numbersSet.insert(NSNumber(integer: anInt))
                        }
                        let newSet = Set(existingPassWhonIDs).union(numbersSet)
                        
                        aSelf.currentElement?.passWhomIDs = Array(newSet)
                    }
                })
            }
            else
            {
                let contactIDsToAdd = newIDsSet.subtract(existingIDsSet)
                if !contactIDsToAdd.isEmpty
                {
                    
                    // add contacts to element
                    DataSource.sharedInstance.addSeveralContacts(contactIDsToAdd,
                        toElement: editingElement.elementId!.integerValue,
                        completion: {[weak self] (succeededIDs, failedIDs) -> () in
                            
                            print("\n----->ContactIDs ADDED: \n \(succeededIDs)\n failed to ADD:\(failedIDs)")
                            
                            if let aSelf = self
                            {
                                var numbersSet = Set<NSNumber>()
                                for anInt in newIDsSet
                                {
                                    numbersSet.insert(NSNumber(integer: anInt))
                                }
                                let newSet = Set(existingPassWhonIDs).union(numbersSet)
                                
                                aSelf.currentElement?.passWhomIDs = Array(newSet)
                            }
                        })

                }
            }
            
        }
        
    }
    
    func handleDeletingCurrentElement()
    {
        if let elementId = self.currentElement?.elementId?.integerValue
        {
            DataSource.sharedInstance.deleteElementFromServer(elementId, completion: { [weak self] (deleted, error) -> () in
                if let weakSelf = self
                {
                    if deleted
                    {
                        if let elementID = weakSelf.currentElement?.elementId?.integerValue
                        {
                            weakSelf.currentElement = Element() //breaking our link to element in datasource
                            DataSource.sharedInstance.deleteElementFromLocalStorage(elementID, shouldNotify:true)
                            weakSelf.navigationController?.popViewControllerAnimated(true)
                        }
                    }
                    else
                    {
                        //show error alert
                        weakSelf.showAlertWithTitle("Error".localizedWithComment(""), message: "Colud not delete current element".localizedWithComment(""), cancelButtonTitle: "Ok")
                    }
                }
            })
        }
    }
    //MARK: handling notifications
    func elementWasDeleted(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo, _/*deletedElementId*/ = userInfo["elementId"] as? Int
        {
            //FIXME: delete designated rows from layout and datasource
           self.prepareCollectionViewDataAndLayout()
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
                if let currentDataSource = self.collectionDataSource?.attachesHandler
                {
                    if currentDataSource.attachedItems.count > 0
                    {
                       currentDataSource.startLoadingAttachedFileSnapshot(attachName)
                    }
                    
                }
//                else
//                {
//                    if let collectionDataSource = self.collectionDataSource
//                    {
//                        let attachesHandler = ElementAttachedFilesCollectionHandler()
//                    }
//                }
            }
        }
    }
    
  
    
    //MARK: ElementSelectionDelegate
    func didTapOnElement(element: Element) {
        
        let nextViewController = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as! SingleElementDashboardVC
        nextViewController.currentElement = element
        self.navigationController?.pushViewController(nextViewController, animated: true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementWasDeleted:", name:kElementWasDeletedNotification , object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshSubordinatesAfterNewElementWasAddedFromChatOrChildElement:", name: kNewElementsAddedNotification, object: nil)
    }
    
    //MARK: AttachmentSelectionDelegate
    func attachedFileTapped(attachFile:AttachFile)
    {
        if let _ = attachFile.attachID?.integerValue
        {
            showAttachentDetailsVC(attachFile)
        }
    }
    
    func showAttachentDetailsVC(file:AttachFile)
    {
        //if it is image - get full image from disc and display in new view controller
        NSOperationQueue().addOperationWithBlock { () -> Void in
            let lvFileHandler = FileHandler()
            if let name = file.fileName, _ = file.attachID?.integerValue
            {
                lvFileHandler.loadFileNamed(name, completion: {[weak self] (fileData, loadingError) -> Void in
                    if let imageData = fileData, _ = UIImage(data: imageData)
                    {
                        if let _ = self
                        {
                            if let fileToDisplay = AttachToDisplay(type: .Image, fileData: fileData, fileName:file.fileName)
                            {
                                NSOperationQueue.mainQueue().addOperationWithBlock({ [weak self]() -> Void in
                                    if let weakSelf = self
                                    {
                                        switch fileToDisplay.type
                                        {
                                        case .Image:
                                            if let destinationVC = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("AttachImageViewer") as? AttachImageViewerVC
                                            {
                                                destinationVC.delegate = weakSelf
                                                weakSelf.currentShowingAttachName = fileToDisplay.name
                                                destinationVC.imageToDisplay = UIImage(data: fileToDisplay.data)
                                                destinationVC.title = fileToDisplay.name
                                                
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
                    })
                

            }
        }
    }
    
    //MARK: - AttachViewerDelegate
    func attachViewerShouldAllowDeletion(viewer: UIViewController) -> Bool {
        if let element = self.currentElement
        {
            return element.isOwnedByCurrentUser()
        }
        return false
    }
    
    func attachViewerDeleteAttachButtonTapped(viewer: UIViewController)
    {
        if !self.currentShowingAttachName.isEmpty
        {
            if let elementIdInt = self.currentElement?.elementId?.integerValue
            {
                DataSource.sharedInstance.deleteAttachedFileNamed(self.currentShowingAttachName, fromElement: elementIdInt, completion: { [weak self](success, error) -> () in
                    if let weakSelf = self
                    {
                        if success
                        {
                            weakSelf.prepareCollectionViewDataAndLayout()
                            weakSelf.navigationController?.popViewControllerAnimated(true)
                        }
                        else if let anError = error
                        {
                            NSLog(" -> Error while trying to delete an attachment.  LocalizedDescription: \n \(anError.localizedDescription) \n")
                            weakSelf.navigationController?.popViewControllerAnimated(true)
                        }
                    }
                })
            }
        }
    }
    
    func startAddingNewAttachFile(notification:NSNotification?)
    {
        if let attachImagePickerVC = self.storyboard?.instantiateViewControllerWithIdentifier("ImagePickerVC") as? ImagePickingViewController
        {
            attachImagePickerVC.attachPickingDelegate = self
            
            //self.presentViewController(attachImagePickerVC, animated: true, completion: nil)
            
            self.navigationController?.pushViewController(attachImagePickerVC, animated: true)
        }
    }
    
    //MARK: AttachPickingDelegate
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    {
        if picker is ImagePickingViewController
        {
            //picker.dismissViewControllerAnimated(true, completion: nil)
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        DataSource.sharedInstance.attachFile(mediaFile, toElementId: self.currentElement!.elementId!) { (success, error) -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] () -> Void in
                if !success
                {
                    if error != nil
                    {
                        print("Error Adding attach file: \n \(error)")
                    }
                    return
                }
                
                if let aSelf = self, elementId_ToRefresh = aSelf.currentElement?.elementId?.integerValue
                {
                    DataSource.sharedInstance.refreshAttachesForElement(elementId_ToRefresh, completion: {[weak self] (attaches) -> () in
                        
                        if let _ = attaches
                        {
                            if let lvSelf = self
                            {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.5) ), dispatch_get_main_queue(), { () -> Void in
                                    
                                    lvSelf.queryAttachesDataAndShowAttachesCellOnCompletion()
                                })
                            }
                        }
                    })
                }
            })
        }
    }
    
    func mediaPickerDidCancel(picker:AnyObject)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
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
        
        if #available(iOS 8.0, *) // FrameCounter.isLowerThanIOSVersion("8.0")
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
            if let contactsPicker = self.storyboard?.instantiateViewControllerWithIdentifier("ContactsPickerVC") as? ContactsPickerVC
            {
        
                contactsPicker.delegate = self
            
                contactsPicker.shouldShowDatePicker = true
                
                contactsPicker.contactsToSelectFrom = DataSource.sharedInstance.getMyContacts()
                
                self.navigationController?.pushViewController(contactsPicker, animated: true)
            }
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
        if let current = self.currentElement, elementIdInt = current.elementId?.integerValue, dateString = NSDate().dateForServer() as? String
        {
            let finishState = state.rawValue
            
            DataSource.sharedInstance.setElementFinishState(elementIdInt, newFinishState: finishState, completion: {[weak self] (edited) -> () in
                if edited
                {
                    DataSource.sharedInstance.setElementFinishDate(elementIdInt, date: dateString, completion: {[weak self] (success) -> () in
                        if let weakSelf = self
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                weakSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
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
        
        if let contactsPickerVC = itemPicker as? ContactsPickerVC,  aNumber = DataSource.sharedInstance.user?.userId, finishDate = contactsPickerVC.datePicker?.date
        {
            sendElementTaskNewResponsiblePerson(aNumber.integerValue, finishDate:finishDate)
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject) {
        if let contactsPickerVC = itemPicker as? ContactsPickerVC, contactPicked = item as? Contact, finishDate = contactsPickerVC.datePicker?.date, contactId = contactPicked.contactId
        {
           
            sendElementTaskNewResponsiblePerson(contactId.integerValue, finishDate:finishDate)
        }
       
        self.navigationController?.popViewControllerAnimated(true)
        
    }
    
    private func sendElementTaskNewResponsiblePerson(responsiblePersonId:Int, finishDate:NSDate)
    {
        if let element = self.currentElement
        {
            let copy = element.createCopy()
            copy.responsible = NSNumber(integer: responsiblePersonId)
            
            copy.finishDate = finishDate
            let optionsConverter = ElementOptionsConverter()
            if !optionsConverter.isOptionEnabled(ElementOptions.Task, forCurrentOptions: copy.typeId.integerValue)
            {
                let newOptions = optionsConverter.toggleOptionChange(copy.typeId.integerValue, selectedOption: 2)
                copy.typeId = NSNumber(integer: newOptions)
            }
            
            if let elementIdInt = copy.elementId?.integerValue
            {
                let newState = ElementFinishState.InProcess.rawValue
                
                DataSource.sharedInstance.editElement(copy, completionClosure: {[weak self] (edited) -> () in
                    if edited
                    {
                        DataSource.sharedInstance.setElementFinishState(elementIdInt, newFinishState: newState, completion: {[weak self] (success) -> () in
                            if success
                            {
                                if let weakSelf = self
                                {
                                    dispatch_async(dispatch_get_main_queue(), { [weak weakSelf]() -> Void in
                                       
                                        if let weakerSelf = weakSelf
                                        {
                                            weakerSelf.collectionDataSource?.handledElement?.finishState = NSNumber(integer: newState)
                                            weakerSelf.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                                        }
                                    })
                                }
                            }
                        })
                    }
                })
            
                if let dateString = copy.finishDate?.dateForServer() as? String
                {
                    DataSource.sharedInstance.setElementFinishDate(elementIdInt, date: dateString, completion: { [weak self](success) -> () in
                    
                        if let weakSelf = self
                        {
                            if success
                            {
                                print("\n -> Element finish date WAS updated.\n")
                                if let existElement = DataSource.sharedInstance.getElementById(elementIdInt)
                                {
                                    print("\n exist element finish date : \(existElement.finishDate)")
                                    print(" current element finish date : \(weakSelf.currentElement?.finishDate)")
                                    print(" current element in collectionDataSource finish date: \(weakSelf.collectionDataSource?.handledElement?.finishDate)")
                                }
                            }
                            else
                            {
                                print("\n -> Element finish date WAS NOT updated.\n")
                            }
                        }
                    })
                }
            }
        }
    }
    
    //MARK: Element Task workflow FINISH -
}
