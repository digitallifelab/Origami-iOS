//
//  SingleElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDashboardVC: UIViewController, ElementComposingDelegate ,UIViewControllerTransitioningDelegate, ElementSelectionDelegate, AttachmentSelectionDelegate, AttachPickingDelegate, UIPopoverPresentationControllerDelegate , MessageTapDelegate {

    weak var currentElement:Element?
    var collectionDataSource:SingleElementCollectionViewDataSource?
    var fadeViewControllerAnimator:FadeOpaqueAnimator?
    
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
        println(" ->removed observer  SingleDashVC from Deinit.")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
     
        //println(" ...viewDidLoad....")
        
        //prepare our appearance
        self.fadeViewControllerAnimator = FadeOpaqueAnimator()
        configureRightBarButtonItem()
        configureNavigationControllerToolbarItems()
        setAppearanceForNightModeToggled(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
        
        
        
        queryAttachesDataAndShowAttachesCellOnCompletion()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadingAttachFileDataCompleted:", name: kAttachFileDataLoadingCompleted, object: nil)
        
        if let ourElement = self.currentElement
        {
            //println("pass Whom IDs old: \(ourElement.passWhomIDs)")
            DataSource.sharedInstance.loadPassWhomIdsForElement(ourElement, comlpetion: {[weak self] (finished) -> () in
                if let aSelf = self
                {
                    if finished
                    {
                        aSelf.currentElement = DataSource.sharedInstance.getElementById(ourElement.elementId!.integerValue)
                        //println("pass Whom IDs new: \(aSelf.currentElement?.passWhomIDs)")
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kNewElementsAddedNotification, object: nil)
        println(" --- Removed From observing new elements added...")
        super.viewWillAppear(animated)
        if afterViewDidLoad
        {
            prepareCollectionViewDataAndLayout()
            afterViewDidLoad = false
        }
        
        var currentAttachesInDataSource = DataSource.sharedInstance.getAttachesForElementById(self.currentElement?.elementId)
        DataSource.sharedInstance.refreshAttachesForElement(self.currentElement, completion: { [weak self] (attachesArray) -> () in
            if let weakSelf = self
            {
                if let recievedAttaches = attachesArray
                {
                    if let existAttaches = currentAttachesInDataSource
                    {
                        var setOfExisting = Set(existAttaches)
                        var setOfNew = Set(recievedAttaches)
                        
                        let remainderSet = setOfNew.subtract(setOfExisting)
                        if remainderSet.isEmpty
                        {
                            println("-> No new attach files loaded")
                        }
                        else
                        {
                            println("-> Loaded \(remainderSet.count) new attaches")
                            weakSelf.prepareCollectionViewDataAndLayout()
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementFavouriteToggled:", name: kElementFavouriteButtonTapped, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementActionButtonPressed:", name: kElementActionButtonPressedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startEditingElement:", name: kElementEditTextNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "toggleMoreDetails:", name: kElementMoreDetailsNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementWasDeletedNotification, object: nil)
        
        let chatPath = NSIndexPath(forItem: 1, inSection: 0)
        var chatCell = self.collectionView.cellForItemAtIndexPath(chatPath) as? SingleElementLastMessagesCell
        
        var currentLastMessages = DataSource.sharedInstance.getChatPreviewMessagesForElementId(self.currentElement!.elementId!.integerValue)
        if chatCell == nil && currentLastMessages != nil
        {
            prepareCollectionViewDataAndLayout()
        }
        else if chatCell != nil && currentLastMessages != nil
        {
            if currentLastMessages!.last !== chatCell!.messages?.last
            {
                chatCell!.messages = currentLastMessages
                self.collectionView.reloadItemsAtIndexPaths([chatPath])
            }
        }
        
//        if self.view.hasAmbiguousLayout()
//        {
//            println("\(self) view has ambiguous layout.\n")
//            //self.view.exerciseAmbiguityInLayout()
//        }
        
        //configureNavigationControllerToolbarItems()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementFavouriteButtonTapped, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementActionButtonPressedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementEditTextNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementMoreDetailsNotification, object: nil)
     
    }
    
    override func viewDidDisappear(animated: Bool)
    {
        super.viewDidDisappear(animated)
    }
    //MARK: Appearance --
    func configureRightBarButtonItem()
    {
        var addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "optionsBarButtonTapped:")
        self.navigationItem.rightBarButtonItem = addButton
    }
    
    func configureNavigationControllerToolbarItems()
    {
        let homeButton = UIButton.buttonWithType(.System) as! UIButton
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
    
    func homeButtonPressed(sender:UIBarButtonItem)
    {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    //MARK: -----
    func queryAttachesPreviewData()
    {
        DataSource.sharedInstance.loadAttachesForElement(self.currentElement!, completion: { (attachFileArray) -> () in
            if let attaches = attachFileArray
            {
                let countAttaches = attaches.count
                println("Loaded \(countAttaches) attaches for current element.")
                
                println(" Starting to load attaches previewImages...")
                let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
                
                dispatch_async(bgQueue, {[weak self] () -> Void in
                    if let previewImageDatas = DataSource.sharedInstance.getSnapshotsArrayForAttaches(attaches)
                    {
                        let countPreviews = previewImageDatas.count
                        
                        if countAttaches != countPreviews
                        {
                            println(" starting to load missing attach file datas...")
                            assert(false, "load missing attaches")
                        }
                        else
                        {
                            println(" Loaded all previews for attaches from local storage.")
                            if let weakSelf = self
                            {
                                var attachDataHolder = [AttachFile:MediaFile]()
                                for var i = 0; i < countAttaches; i++
                                {
                                    let lvAttachFile = attaches[i]
                                    let lvAttachDataDict = previewImageDatas[i]
                                    if let fileData = lvAttachDataDict[lvAttachFile]
                                    {
                                        var lvMediaFile = MediaFile()
                                        lvMediaFile.data = fileData
                                        lvMediaFile.name = lvAttachFile.fileName ?? ""
                                        lvMediaFile.type = .Image
                                        attachDataHolder[lvAttachFile] = lvMediaFile
                                    }
                                }
                                
                                let mediaCount = attachDataHolder.count
                                println("\n ->prepared \(mediaCount) attachFilePairs\n")
                                
                                if let attachesCollectionHandler = weakSelf.collectionDataSource?.attachesHandler
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        println("\n Reloading attaches collection view \n")
                                        weakSelf.collectionDataSource?.attachesHandler?.reloadCollectionWithData(attachDataHolder)
                                    })
                                }
                                else
                                {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        
                                        println("\n Assigning new  attaches handler and reloading collection view \n")
                                        var attachesHandler = ElementAttachedFilesCollectionHandler(items: attaches)
                                        weakSelf.collectionDataSource?.attachesHandler = attachesHandler
                                        weakSelf.collectionDataSource?.handledElement = weakSelf.currentElement
                                        weakSelf.collectionView.dataSource = weakSelf.collectionDataSource
                                        weakSelf.collectionView.delegate = weakSelf.collectionDataSource
                                        weakSelf.collectionView.reloadData()
                                        
                                        weakSelf.collectionView.performBatchUpdates({ () -> Void in
                                            
                                            weakSelf.collectionView.reloadSections(NSIndexSet(index: 0)) //this another one reload needed for changing subordinateCcell into attachesCell bug fixing.
                                            
                                        }, completion: { (finished) -> Void in
                                            
                                            if let layout = weakSelf.prepareCollectionLayoutForElement(weakSelf.currentElement)
                                            {
                                                weakSelf.collectionView.setCollectionViewLayout(layout, animated: false)
                                            }
                                            else
                                            {
                                                println(" ERROR . \nCould not generate new layout for loaded attaches.")
                                            }
                                            weakSelf.collectionDataSource?.attachesHandler?.reloadCollectionWithData(attachDataHolder)
                                            
                                        })
                                    })
                                }
                            }
                        }
                    }
                    else
                    {
                        if let weakSelf = self
                        {
                            weakSelf.startLoadingDataForMissingAttaches(attaches)
                        }
                    }
                })
            }
            else
            {
#if DEBUG
                println("Loaded No Attaches for current element")
#endif
             }
        })
    }
    
    func queryAttachesDataAndShowAttachesCellOnCompletion()
    {
        if let existingAttaches = DataSource.sharedInstance.getAttachesForElementById(self.currentElement?.elementId)
        {
            var attachesHandler = ElementAttachedFilesCollectionHandler(items: existingAttaches)
            collectionDataSource?.attachesHandler = attachesHandler
            collectionDataSource?.handledElement = currentElement
            collectionView.dataSource = collectionDataSource
            collectionView.delegate = collectionDataSource
           
            collectionView.reloadData()
            
            if let layout = self.prepareCollectionLayoutForElement(currentElement)
            {
                collectionView.setCollectionViewLayout(layout, animated: false)
                //collectionView.reloadSections(NSIndexSet(index: 0))
            }
            else
            {
                println(" ERROR . \nCould not generate new layout for loaded attaches.")
            }
           
            return
        }
        
        DataSource.sharedInstance.loadAttachesForElement(self.currentElement!, completion: { [weak self](attaches) -> () in
            if let arrayOfAttaches = attaches
            {
                if !arrayOfAttaches.isEmpty
                {
                    if let weakSelf = self
                    {
                        println("\n--> recieved \(arrayOfAttaches.count) attaches for current element\n")
                        if let existingAttachesHandler = weakSelf.collectionDataSource?.getElementAttachesHandler()
                        {
                            if let attachesCellPath = weakSelf.collectionDataSource?.indexPathForAttachesCell()
                            {
                                weakSelf.collectionView.reloadItemsAtIndexPaths([attachesCellPath])
                            }
                            return
                        }
                        var attachesHandler = ElementAttachedFilesCollectionHandler(items: arrayOfAttaches)
                        weakSelf.collectionDataSource?.attachesHandler = attachesHandler
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
                            println(" ERROR . \nCould not generate new layout for loaded attaches.")
                        }
                    }
                }
                else
                {
                    println("\n-->Loaded Empty Attaches array for current element\n")
                }
            }
            else
            {
                println("\n-->Loaded No Attaches for current element\n")
            }
        })
    }
    
    func startLoadingDataForMissingAttaches(attaches:[AttachFile])
    {
        DataSource.sharedInstance.loadAttachFileDataForAttaches(attaches, completion: { () -> () in
            NSNotificationCenter.defaultCenter().postNotificationName(kAttachFileDataLoadingCompleted, object: nil)
        })
    }
    
    func loadingAttachFileDataCompleted(notification:NSNotification)
    {
        println(" Recieved notification about finishing of loading missing attach file datas")
        queryAttachesPreviewData()
    }
    
    //MARK: Day/Night Mode
    func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .Any, barMetrics: .Default)
        
        if nightModeOn
        {
            self.displayMode = .Night
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
            self.navigationController?.toolbar.tintColor = kWhiteColor
            self.navigationController?.toolbar.backgroundColor = kBlackColor
        }
        else
        {
            self.displayMode = .Day
            self.view.backgroundColor = kDayViewBackgroundColor//kDayCellBackgroundColor
            self.navigationBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            self.navigationController?.toolbar.tintColor = kDayNavigationBarBackgroundColor
            self.navigationController?.toolbar.backgroundColor = kWhiteColor
        }
        
        self.collectionView.reloadData()
        
    }

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
                println(" ! -> Some error occured while reloading collectionView with new lyout.")
            }
            collectionView.performBatchUpdates({ [weak self]() -> Void in
                
            }, completion: {[unowned self] (finished) -> Void in
               
            })

        }
    }
    
    //MARK: Custom CollectionView Layout
    func prepareCollectionLayoutForElement(element:Element?) -> UICollectionViewFlowLayout?
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
        if let editingVC = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController //
        {
            if let rootElementId = self.currentElement?.rootElementId
            {
                editingVC.rootElementID = rootElementId.integerValue
            }
            
            
            editingVC.modalPresentationStyle = .Custom
            editingVC.transitioningDelegate = self
            let copyElement = Element(info:  self.currentElement!.toDictionary())
            editingVC.composingDelegate = self
            
            self.collectionView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .Top)
            self.presentViewController(editingVC, animated: true, completion: {[weak self] () -> Void in
                editingVC.newElement =  copyElement
                editingVC.editingStyle = ElementEditingStyle.EditCurrent
                
//                if let weakSelf = self
//                {
//                    weakSelf.collectionView.selectItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), animated: false, scrollPosition: .Top)
//                }
            })
        }
    }
    
    func elementFavouriteToggled(notification:NSNotification)
    {
        if let element = currentElement
        {
            let favourite = element.isFavourite.boolValue
            var isFavourite = !favourite
            var elementCopy = Element(info: element.toDictionary())
            var titleCell:SingleElementTitleCell?
            if let titleCellCheck = notification.object as? SingleElementTitleCell
            {
                titleCell = titleCellCheck
            }
            DataSource.sharedInstance.updateElement(elementCopy, isFavourite: isFavourite) { [weak self] (edited) -> () in
                
                if let weakSelf = self
                {
                    if edited
                    {
                        weakSelf.currentElement!.isFavourite = isFavourite
                        titleCell?.favourite = isFavourite
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
                case .CheckMark:
                    elementTaskPressed()
                case .Idea:
                    elementIdeaPressed()
                case .Solution:
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
        //println("Signal element toggled.")
        
        if let theElement = currentElement
        {
            let isSignal = theElement.isSignal.boolValue
            var elementCopy = Element(info: theElement.toDictionary())
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
                newElementCreator.modalPresentationStyle = .Custom
                newElementCreator.transitioningDelegate = self
                
                self.presentViewController(newElementCreator, animated: true, completion: { () -> Void in
                    newElementCreator.editingStyle = .AddNew
                })
            }
        }
    }
    
    func elementArchivePressed()
    {
        println("Archive element tapped.")
    }
    
    func elementDeletePressed()
    {
        //println("Delete element tapped.")
        handleDeletingCurrentElement()
    }
    
    func elementIdeaPressed()
    {
        println("Idea tapped.")
        let anOptionsConverter = ElementOptionsConverter()
        let newOptions = anOptionsConverter.toggleOptionChange(self.currentElement!.typeId.integerValue, selectedOption: 1)
        var editingElement = Element(info: self.currentElement!.toDictionary())
        editingElement.typeId = NSNumber(integer: newOptions)
        println("new element type id: \(editingElement.typeId)")
        self .handleEditingElementOptions(editingElement, newOptions: NSNumber(integer: newOptions))
    }
    
    func elementTaskPressed()
    {
        println("CheckMark tapped.")
        let anOptionsConverter = ElementOptionsConverter()
        let newOptions = anOptionsConverter.toggleOptionChange(self.currentElement!.typeId.integerValue, selectedOption: 2)
        var editingElement = Element(info: self.currentElement!.toDictionary())
        editingElement.typeId = NSNumber(integer: newOptions)
        println("new element type id: \(editingElement.typeId)")
        self .handleEditingElementOptions(editingElement, newOptions: NSNumber(integer: newOptions))
        
    }
    
    func elementDecisionPressed()
    {
        println("Decision tapped.")
        let anOptionsConverter = ElementOptionsConverter()
        let newOptions = anOptionsConverter.toggleOptionChange(self.currentElement!.typeId.integerValue, selectedOption: 3)
        var editingElement = Element(info: self.currentElement!.toDictionary())
        editingElement.typeId = NSNumber(integer: newOptions)
        println("new element type id: \(editingElement.typeId)")
        self .handleEditingElementOptions(editingElement, newOptions: NSNumber(integer: newOptions))
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
            
            if FrameCounter.isLowerThanIOSVersion("8.0")
            {
                if FrameCounter.getCurrentInterfaceIdiom() == .Pad
                {
                    if let barItem = sender as? UIBarButtonItem
                    {
                        var popoverController = UIPopoverController(contentViewController: leftTopMenuPopupVC)
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
            else
            {
                leftTopMenuPopupVC.modalPresentationStyle = UIModalPresentationStyle.Popover
                leftTopMenuPopupVC.modalInPopover = false//true // true disables dismissing popover menu by tapping outside - in faded out parent VC`s view.
                
                
                //var aPopover:UIPopoverController = UIPopoverController(contentViewController: leftTopMenuPopupVC)
                var popoverObject = leftTopMenuPopupVC.popoverPresentationController
                popoverObject?.permittedArrowDirections = .Any
                popoverObject?.barButtonItem = self.navigationItem.rightBarButtonItem
                popoverObject?.delegate = self
                
                //leftTopMenuPopupVC.popoverPresentationController?.sourceRect = CGRectMake(0, 0, 200, 160.0)
                leftTopMenuPopupVC.preferredContentSize = CGSizeMake(200, 180.0)
                self.presentViewController(leftTopMenuPopupVC, animated: true, completion: { () -> Void in
                    
                })
            }
        }
    }
    //MARK: top left menu popover action
    func popoverItemTapped(notification:NSNotification?)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "PopupMenuItemPressed", object: notification?.object)
        if let note = notification
        {
            if let vc = note.object as? EditingMenuPopupVC
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
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    //MARK: ElementComposingDelegate

    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        composer.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element) {
        composer.dismissViewControllerAnimated(true, completion: nil)
        
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
                            println(" added to \(succeededIDs)")
                            println(" failed to add to \(failedIDs)")
                            if let weakSelf = self
                            {
                                weakSelf.showAlertWithTitle("ERROR.", message: "Could not add contacts to new element.", cancelButtonTitle: "Ok")
                            }
                        }
                        else
                        {
                            println(" added to \(succeededIDs)")
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
                    aSelf.currentElement?.typeId = newOptions //the options target
                    aSelf.collectionDataSource?.handledElement = aSelf.currentElement
                    aSelf.collectionView.reloadData()
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
        DataSource.sharedInstance.editElement(editingElement, completionClosure: {[weak self] (edited) -> () in
            if let aSelf = self
            {
                if edited
                {
                    
                    aSelf.currentElement?.title = editingElement.title
                    aSelf.currentElement?.details = editingElement.details
                    aSelf.collectionDataSource?.handledElement = aSelf.currentElement
                   
                    aSelf.collectionView.collectionViewLayout.invalidateLayout()
                    aSelf.collectionView.performBatchUpdates({ () -> Void in
                        aSelf.collectionView.reloadSections(NSIndexSet(index: 0))
                    }, completion: { ( _ ) -> Void in
                        if let layout = aSelf.prepareCollectionLayoutForElement(aSelf.currentElement)
                        {
                            aSelf.collectionView.setCollectionViewLayout(layout, animated: false)
                        }
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
                println("\n----->ContactIDs ADDED: \n \(succeededIDs)\n failed to ADD:\(failedIDs)")
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
                println("\n----->ContactIDs REMOVED: \n \(succeededIDs)\n failed to REMOVE:\(failedIDs)")
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
                                                                            
                    println("\n----->ContactIDs REMOVED: \n \(succeededIDs)\n failed to REMOVE:\(failedIDs)")
                                                                            
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
                        
                    println("\n----->ContactIDs ADDED: \n \(succeededIDs)\n failed to ADD:\(failedIDs)")
                    
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
                            
                            println("\n----->ContactIDs ADDED: \n \(succeededIDs)\n failed to ADD:\(failedIDs)")
                            
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
                            DataSource.sharedInstance.deleteElementFromLocalStorage(elementID)
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
        if let note = notification, userInfo = note.userInfo, elementId = userInfo["elementId"] as? NSNumber
        {
           self.prepareCollectionViewDataAndLayout()
        }
    }
    
    func refreshSubordinatesAfterNewElementWasAddedFromChatOrChildElement(notification:NSNotification)
    {
        if let info = notification.userInfo, elementIdNumbersSet = info["IDs"] as? Set<NSNumber>
        {
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.prepareCollectionViewDataAndLayout()
                }
            })
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
        if let attachId = attachFile.attachID
        {
            showAttachentDetailsVC(attachFile)
        }
    }
    
    func showAttachentDetailsVC(file:AttachFile)
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
                            if let aSelf = self
                            {
                                if let fileToDisplay = AttachToDisplay(type: .Image, fileData: fileData, fileName:file.fileName)
                                {
                                    switch fileToDisplay.type
                                    {
                                    case .Image:
                                        if let destinationVC = aSelf.storyboard?.instantiateViewControllerWithIdentifier("AttachImageViewer") as? AttachImageViewerVC
                                        {
                                            destinationVC.imageToDisplay = UIImage(data: fileToDisplay.data)
                                            destinationVC.title = fileToDisplay.name
                                            
                                            aSelf.navigationController?.pushViewController(destinationVC, animated: true)
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
                        })
                    }
                }
            })
        }
    }
    
    func startAddingNewAttachFile(notification:NSNotification?)
    {
        if let attachImagePickerVC = self.storyboard?.instantiateViewControllerWithIdentifier("ImagePickerVC") as? ImagePickingViewController
        {
            attachImagePickerVC.attachPickingDelegate = self
            
            self.presentViewController(attachImagePickerVC, animated: true, completion: nil)
        }
    }
    
    //MARK: AttachPickingDelegate
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    {
        if picker is ImagePickingViewController
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
        
        DataSource.sharedInstance.attachFile(mediaFile, toElementId: self.currentElement!.elementId!) { (success, error) -> () in
            NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] () -> Void in
                if !success
                {
                    if error != nil
                    {
                        println("Error Adding attach file: \n \(error)")
                    }
                    return
                }
                
                if let aSelf = self, currentElementToRefresh = aSelf.currentElement
                {
                    DataSource.sharedInstance.refreshAttachesForElement(currentElementToRefresh, completion: {[weak self] (attaches) -> () in
                        if let attachObjects = attaches
                        {
                            if let aSelf = self
                            {
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.5) ), dispatch_get_main_queue(), { () -> Void in
                                    //aSelf.queryAttachesPreviewData()
                                    aSelf.queryAttachesDataAndShowAttachesCellOnCompletion()
                                })
                                //aSelf.queryAttachesDataAndShowAttachesCellOnCompletion()
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
            
            println(" -- > Added self to observe new element added")
            
            chatVC.currentElement = self.currentElement
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
    }
    
    //MARK: MessageTapDelegate
    func chatMessageWasTapped(message: Message?) {
        showChatForCurrentElement()
    }

}
