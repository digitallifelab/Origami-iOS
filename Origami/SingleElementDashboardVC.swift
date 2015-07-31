//
//  SingleElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDashboardVC: UIViewController, ElementComposingDelegate ,UIViewControllerTransitioningDelegate, ElementSelectionDelegate, AttachmentSelectionDelegate, AttachPickingDelegate, UIPopoverPresentationControllerDelegate {

    var currentElement:Element?
    var collectionDataSource:SingleElementCollectionViewDataSource?
    var fadeViewControllerAnimator:FadeOpaqueAnimator?
    
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
                collectionView.reloadData()
            }
        }
    }
    
    @IBOutlet var collectionView:UICollectionView!
    @IBOutlet var navigationBackgroundView:UIView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.fadeViewControllerAnimator = FadeOpaqueAnimator()
        
        setAppearanceForNightModeToggled(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
        
        configureRightBarButtonItem()
        
        prepareCollectionViewDataAndLayout()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadingAttachFileDataCompleted:", name: kAttachFileDataLoadingCompleted, object: nil)
        
        queryAttachesPreviewData()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementFavouriteToggled:", name: kElementFavouriteButtonTapped, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "alementActionButtonPressed:", name: kElementActionButtonPressedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startEditingElement:", name: kElementEditTextNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "startAddingNewAttachFile:", name: kAddNewAttachFileTapped, object: nil)
        //prepareCollectionViewDataAndLayout()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func configureRightBarButtonItem()
    {
        //self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        var rightButton = UIButton.buttonWithType(.Custom) as! UIButton
        rightButton.frame = CGRectMake(0, 0, 44, 44)
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8)
        rightButton.setImage(UIImage(named: "icon-options"), forState: .Normal)
        rightButton.addTarget(self, action: "optionsBarButtonTapped:", forControlEvents: .TouchUpInside)
        rightButton.tintColor = UIColor.whiteColor()
        
        let rightBarButton = UIBarButtonItem(customView: rightButton)
        self.navigationItem.rightBarButtonItem = rightBarButton
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
                let bgQueue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                
                dispatch_async(bgQueue, {[weak self] () -> Void in
                    if let previewImageDatas = DataSource.sharedInstance.getSnapshotsArrayForAttaches(attaches)
                    {
                        let countPreviews = previewImageDatas.count
                        
                        if countAttaches != countPreviews
                        {
                            println(" starting to load missing attach file datas...")
                        }
                        else
                        {
                            println(" Loaded all previews for attaches from local storage.")
                            if let weakSelf = self, attachesCollectionHandler = weakSelf.collectionDataSource?.attachesHandler
                            {
                                var attachDataHolder = [AttachFile:MediaFile]()
                                for var i = 0; i < countAttaches; i++
                                {
                                    let lvAttachFile = attaches[i]
                                    let lvAttachData = previewImageDatas[i]
                                    
                                    var lvMediaFile = MediaFile()
                                    lvMediaFile.data = lvAttachData
                                    lvMediaFile.name = lvAttachFile.fileName ?? ""
                                    lvMediaFile.type = .Image
                                    
                                    attachDataHolder[lvAttachFile] = lvMediaFile
                                }
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    weakSelf.collectionDataSource?.attachesHandler?.reloadCollectionWithData(attachDataHolder)
                                })
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
                println("Loaded No Attaches for current element")
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
        if nightModeOn
        {
            self.displayMode = .Night
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
           // UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar
            
            //self.tabBarController?.tabBar.tintColor = kWhiteColor
            //self.tabBarController?.tabBar.backgroundColor = UIColor.blackColor()
        }
        else
        {
            self.displayMode = .Day
            self.view.backgroundColor = kDayViewBackgroundColor//kDayCellBackgroundColor
            //self.collectionView.backgroundColor = kDayViewBackgroundColor
            self.navigationBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            //UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
            
            //self.tabBarController?.tabBar.tintColor = kWhiteColor
            //self.tabBarController?.tabBar.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.8)
            
        }
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        self.collectionView.reloadData()
        
    }

    func prepareCollectionViewDataAndLayout()
    {
        collectionDataSource = SingleElementCollectionViewDataSource(element: currentElement) // both can be nil
        collectionDataSource!.handledElement = currentElement
        collectionDataSource!.displayMode = self.displayMode
        collectionDataSource!.subordinateTapDelegate = self
        collectionDataSource!.attachTapDelegate = self
        
        if collectionDataSource != nil
        {
            collectionView.dataSource = collectionDataSource!
            collectionView.delegate = collectionDataSource!
            
            if let attachesHandler = collectionDataSource!.attachesHandler
            {
//                if attachesHandler.attachedItems.count > 0
//                {
//                    
//                }
                
                if let layout = prepareCollectionLayoutForElement(currentElement)
                {
                    collectionView.setCollectionViewLayout(layout, animated: false)
                }
            }
            
        }
        
    }
    //MARK: Custom CollectionView Layout
    func prepareCollectionLayoutForElement(element:Element?) -> UICollectionViewFlowLayout?
    {
        if element == nil
        {
            return nil
        }
        
        if let readyDataSource = self.collectionDataSource, layout = SimpleElementDashboardLayout(infoStruct: readyDataSource.getLayoutInfo())
        {
            return layout
        }
        else
        {
            return nil
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
    
    //MARK: Handling buttons and other elements tap in collection view
    func startEditingElement(notification:NSNotification?)
    {
        if let editingVC = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController //self.storyboard?.instantiateViewControllerWithIdentifier("ElementEditingVC") as? ElementTitleAndDetailsEditingVC
        {
            editingVC.rootElementID = self.currentElement?.rootElementId
            
            editingVC.modalPresentationStyle = .Custom
            editingVC.transitioningDelegate = self
            //create copy of current element
            let copyElement = Element(info:  self.currentElement!.toDictionary())
            //editingVC.newElement =  copyElement
            editingVC.composingDelegate = self
            
            self.presentViewController(editingVC, animated: true, completion: { () -> Void in
                editingVC.editingStyle = ElementEditingStyle.EditCurrent
                editingVC.newElement =  copyElement
            })
        }
    }
    
    func elementFavouriteToggled(notification:NSNotification)
    {
        if let element = currentElement,  favourite = element.isFavourite
        {
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
    
    func alementActionButtonPressed(notification:NSNotification?)
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
                    elementCheckMarkPressed()
                case .Idea:
                    elementIdeaPressed()
                case .Solution:
                    elementSolutionPressed()
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
        println("Signal element toggled.")
        
        if let theElement = currentElement , isSignal = theElement.isSignal
        {
            var elementCopy = Element(info: theElement.toDictionary())
            let isCurrentlySignal = !isSignal
            elementCopy.isSignal = isCurrentlySignal
            
            DataSource.sharedInstance.editElement(elementCopy, completionClosure: {[weak self] (edited) -> () in
                if let aSelf = self
                {
                    if edited
                    {
                        aSelf.currentElement?.isSignal = isCurrentlySignal
                        aSelf.prepareCollectionViewDataAndLayout()
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
        println("Edit element toggled.")
        if let source = collectionDataSource
        {
            collectionDataSource!.editingEnabled = !source.editingEnabled
            
            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
        }
    }
    
    func elementAddNewSubordinatePressed()
    {
//        let semaphore = dispatch_semaphore_create(0)
//        
//        if let presentedPopover = self.presentedViewController
//        {
//           self.dismissViewControllerAnimated(true, completion: { () -> Void in
//                dispatch_semaphore_signal(semaphore)
//           })
//        }
//        else
//        {
//            dispatch_semaphore_signal(semaphore)
//        }
//        
//        
//        var timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)) )
//        dispatch_semaphore_wait(semaphore, timeout)
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            if let elementId = currentElement?.elementId
            {
                newElementCreator.composingDelegate = self
                newElementCreator.rootElementID = elementId
                if let passwhomIDs = currentElement?.passWhomIDs
                {
                    newElementCreator.contactIDsToPass = Set(passwhomIDs)// subordinate elements should automaticaly inherit current element`s assignet contacts..  Creator can add or delete contacts later, when creating element.
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
        println("Delete element tapped.")
        handleDeletingCurrentElement()
    }
    
    func elementCheckMarkPressed()
    {
        println("CheckMark tapped.")
    }
    
    func elementIdeaPressed()
    {
        println("Idea tapped.")
    }
    
    func elementSolutionPressed()
    {
        println("Solution tapped.")
    }
    
    //MARK: top left menu popover
    func optionsBarButtonTapped(sender:UIButton?)
    {
        if let leftTopMenuPopupVC = self.storyboard?.instantiateViewControllerWithIdentifier("EditingMenuPopupVC") as? EditingMenuPopupVC
        {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "popoverItemTapped:", name: "PopupMenuItemPressed", object: leftTopMenuPopupVC)
            leftTopMenuPopupVC.modalPresentationStyle = UIModalPresentationStyle.Popover
            leftTopMenuPopupVC.modalInPopover = false//true // true disables dismissing popover menu by tapping outside - in faded out parent VC`s view.
            //leftTopMenuPopupVC.view.frame = CGRectMake(0, 0, 200.0, 150.0)
            
            //var aPopover:UIPopoverController = UIPopoverController(contentViewController: leftTopMenuPopupVC)
            var popoverObject = leftTopMenuPopupVC.popoverPresentationController
            popoverObject?.permittedArrowDirections = .Any
            popoverObject?.barButtonItem = self.navigationItem.rightBarButtonItem
            popoverObject?.delegate = self
            
            //leftTopMenuPopupVC.popoverPresentationController?.sourceRect = CGRectMake(0, 0, 200, 160.0)
            leftTopMenuPopupVC.preferredContentSize = CGSizeMake(200, 150.0)
            self.presentViewController(leftTopMenuPopupVC, animated: true, completion: { () -> Void in
                
            })
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
        if let nsNumberArray = element.passWhomIDs
        {
            passWhomIDs = [Int]()
            for number in nsNumberArray
            {
                passWhomIDs!.append(number)
            }
        }
        
        // 1
        DataSource.sharedInstance.submitNewElementToServer(element, completion: {[weak self] (newElementID, submitingError) -> () in
            if let lvElementId = newElementID
            {
                if let passWhomIDsArray = passWhomIDs // 2
                {
                    DataSource.sharedInstance.addSeveralContacts(passWhomIDsArray, toElement: lvElementId, completion: { (succeededIDs, failedIDs) -> () in
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
    
    func handleEditingElement(element:Element)
    {
        
        
        DataSource.sharedInstance.editElement(element, completionClosure: {[weak self] (edited) -> () in
            if let aSelf = self
            {
                if edited
                {
                    aSelf.prepareCollectionViewDataAndLayout()
                }
                else
                {
                    aSelf.showAlertWithTitle("Warning.", message: "Could not update current element.", cancelButtonTitle: "Ok")
                }
            }
        })
        
        if let passWhomIDs = element.passWhomIDs
        {
            if let existingPassWhonIDs = self.currentElement?.passWhomIDs
            {
                let existingSet = Set(existingPassWhonIDs)
                let editedPassWhomIDs = Set(passWhomIDs)
                
                let exclusiveSet = existingSet.exclusiveOr(editedPassWhomIDs)
            }
            else
            {
                if let currentElementID = self.currentElement?.elementId
                {
                    DataSource.sharedInstance.addSeveralContacts(passWhomIDs, toElement: currentElementID, completion: {[weak self] (succeededIDs, failedIDs) -> () in
                        
                        if let weakSelf = self
                        {
                            if succeededIDs.count == passWhomIDs.count
                            {
                                
                                //weakSelf.currentElement?.passWhomIDs = succeededIDs
                                //commented because theese IDs are already set in "addSeveralContacts"  success method
                                println("PAssed IDS: \(passWhomIDs) to element")
                            }
                            else
                            {
                                weakSelf.showAlertWithTitle("Error", message: "Could not assign some contacts to element&", cancelButtonTitle: "Close")
                            }
                        }
                    })
                }
                else
                {
                    println("  -> Warning >> No Current Element Found....")
                }
              
            }
          
        }
    }
    
    func handleDeletingCurrentElement()
    {
        if let elementId = self.currentElement?.elementId
        {
            DataSource.sharedInstance.deleteElementFromServer(elementId, completion: { [weak self] (deleted, error) -> () in
                if let weakSelf = self
                {
                    if deleted
                    {
                        if let elementId = weakSelf.currentElement?.elementId
                        {
                            weakSelf.currentElement = Element() //breaking our link to element in datasource
                            DataSource.sharedInstance.deleteElementFromLocalStorage(elementId)
                            
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
    
    //MARK: ElementSelectionDelegate
    func didTapOnElement(element: Element) {
        
        let nextViewController = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as! SingleElementDashboardVC
        nextViewController.currentElement = element
        self.navigationController?.pushViewController(nextViewController, animated: true)
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
                               // dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.5) ), dispatch_get_main_queue(), { () -> Void in
                                    aSelf.queryAttachesPreviewData()
                                //})
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
            chatVC.currentElement = self.currentElement
            self.navigationController?.pushViewController(chatVC, animated: true)
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
}
