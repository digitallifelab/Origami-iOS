//
//  HomeVC.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//
import UIKit

typealias dashboardDBElementsInfoTuple = (signals:[DBElement]?, favourites:[DBElement]?, other:[DBElement]?)


class HomeVC: UIViewController, ElementSelectionDelegate, MessageObserver, ElementComposingDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate/*, MessageObserver*/
{

    @IBOutlet var collectionDashboard:UICollectionView!
    //@IBOutlet var bottomHomeToolBarButton:UIBarButtonItem!
    var newElementDetailsInfo:String?
    var collectionSource:HomeCollectionHandler?
    var customTransitionAnimator:UIViewControllerAnimatedTransitioning?
    
    private var refreshControl:UIRefreshControl?
    var shouldReloadCollection = false
    
//    deinit
//    {
//        print("\n -> removing HomeVC from NotificationCenter ->\n")
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.title = "Home"
        configureNavigationTitleView()// to remove "Home" from navigation bar.
        
        self.collectionDashboard.registerClass(DashHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "DashHeader")
        configureTestVisualisationTitleButton()
        configureRightBarButtonItem()
        configureLeftBarButtonItem()
        configureNavigationControllerToolbarItems()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "recievedMessagesFinishedNotification:", name: FinishedLoadingMessages, object: nil)        
        
        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        if let _ = DataSource.sharedInstance.user
        {
            nightModeDidChange(nil)
        }
        
        DataSource.sharedInstance.addObserverForNewMessagesForElement(self, elementId: All_New_Messages_Observation_ElementId)
        
        
        startReadingHomeScreenData(1)
//        if let dashInfo = DataSource.sharedInstance.dashBoardInfo
//        {
//            reloadDashBoardViewWithDBElementsInfo(dashInfo)
//        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if let _ = DataSource.sharedInstance.user
        {
            //register for night-day modes switching
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "nightModeDidChange:", name: kMenu_Switch_Night_Mode_Changed, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didTapOnChatMessage:", name: kHomeScreenMessageTappedNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementWasDeleted:", name:kElementWasDeletedNotification , object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementsWereAdded:", name: kNewElementsAddedNotification, object: nil)
            
            
            if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
            {
                self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
            }
        }
        else
        {
            collectionDashboard.dataSource = nil
        }
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Switch_Night_Mode_Changed, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kHomeScreenMessageTappedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kElementWasDeletedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kNewElementsAddedNotification, object: nil)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.removeGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        DataSource.sharedInstance.removeObserverForNewMessagesForElement(All_New_Messages_Observation_ElementId)
    }

    
    func recievedMessagesFinishedNotification(notification:NSNotification)
    {
        if let currentElementsDataRefresher = DataSource.sharedInstance.dataRefresher
        {
            if currentElementsDataRefresher.isCancelled
            {
                currentElementsDataRefresher.startRefreshingElementsWithTimeoutInterval(30.0)
            }
        }
        else if let _ = DataSource.sharedInstance.user?.userId
        {
            DataSource.sharedInstance.dataRefresher = DataRefresher()
            DataSource.sharedInstance.dataRefresher?.startRefreshingElementsWithTimeoutInterval(30.0)
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: notification.name, object: notification.object)
    }
    
    //MARK: ----- NavigationBarButtons
    
    func configureRightBarButtonItem()
    {
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "showElementCreationVC:")
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func configureTestVisualisationTitleButton()
    {
        #if SHEVCHENKO
        #else
            let titleButton = UIButton(type: .System)
            titleButton.frame = CGRectMake(0,0,60.0,40.0)
            let titleAttributed = NSAttributedString(string: "Graph", attributes: [NSForegroundColorAttributeName:kWhiteColor, NSFontAttributeName:UIFont(name: "SegoeUI", size: 15)!])
            titleButton.setAttributedTitle(titleAttributed, forState: .Normal)
            titleButton.titleEdgeInsets = UIEdgeInsetsMake(3, 3, 3, 3)
            
            titleButton.addTarget(self, action: "showGraphViewController:", forControlEvents: .TouchUpInside)
            self.navigationItem.titleView = titleButton
        #endif
    }
    
    func showGraphViewController(sender:UIButton)
    {
        let graphBoard = UIStoryboard(name: "Visualization", bundle: nil)
        guard let visualVC = graphBoard.instantiateViewControllerWithIdentifier("VisualizationVC") as? VisualizationViewController else
        {
            return
        }
        self.navigationController?.pushViewController(visualVC, animated: true)
    }
    
    func configureLeftBarButtonItem()
    {
        let leftButton = UIButton(type:.Custom)
        leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
        leftButton.setImage(UIImage(named: "icon-options")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        leftButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        leftButton.tintColor = UIColor.whiteColor()
        
        let leftBarButton = UIBarButtonItem(customView: leftButton)
        
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func configureNavigationTitleView()
    {
        #if SHEVCHENKO
            let titleImageView = UIImageView(image:UIImage(named: "title-home"))
            titleImageView.contentMode = .ScaleAspectFit
            titleImageView.frame = CGRectMake(0, 0, 200, 40)
            self.navigationItem.titleView = titleImageView
        #else
            let titleLabel = UILabel()
            self.navigationItem.titleView = titleLabel
        #endif
    }
    
    
    func configureNavigationControllerToolbarItems()
    {
        //....
        let homeButton = UIButton(type:.System)
       
        homeButton.setImage(UIImage(named: kHomeButtonImageName)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
       
        homeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        homeButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        homeButton.frame = CGRectMake(0, 0, 44.0, 44.0)
    
        let homeImageButton = UIBarButtonItem(customView: homeButton)
        
        let buttonImageInsets = UIEdgeInsetsMake(5, 5, 5, 5)
        
        //....
        let filterButton = UIButton(type:.System)
        filterButton.setImage(UIImage(named: "menu-icon-sorting")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        //filterButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        filterButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        filterButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        filterButton.addTarget(self, action: "showSortedElements:", forControlEvents: .TouchUpInside)
        filterButton.imageEdgeInsets = buttonImageInsets
        let filterButtonItem = UIBarButtonItem(customView: filterButton)
        
        //....
        let recentActivityButton = UIButton(type:.System)
        recentActivityButton.setImage(UIImage(named: "menu-icon-recent")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        //recentActivityButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        recentActivityButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        recentActivityButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        recentActivityButton.addTarget(self, action: "showRecentActivity:", forControlEvents: .TouchUpInside)
        recentActivityButton.imageEdgeInsets = buttonImageInsets
        let recentBarButton = UIBarButtonItem(customView: recentActivityButton)
        
        //.
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let currentToolbarItems:[UIBarButtonItem] = [filterButtonItem, flexibleSpace, homeImageButton, flexibleSpace, recentBarButton]
        
        //
        self.setToolbarItems(currentToolbarItems, animated: false)
    }
    
    //MARK: UIRefreshControl
    func startRefreshing(sender:UIRefreshControl)
    {
        refreshMainDashboard {[weak sender] () -> () in
            
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                if let weakRefreshControl = sender
                {
                    weakRefreshControl.endRefreshing()
                }
            })
        }
    }
    
    private func refreshMainDashboard(completion:(()->())?)
    {
        
        DataSource.sharedInstance.localDatadaseHandler?.readHomeDashboardElements(true) {[weak self] (info) -> () in
            
            if let weakSelf = self, dashInfo = DataSource.sharedInstance.dashBoardInfo
            {
                if dashInfo.signals == nil && dashInfo.favourites == nil && dashInfo.other == nil
                {
                    return
                }
                
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    weakSelf.reloadDashBoardViewWithDBElementsInfo(info)
                })
            }
        }
        
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
        dispatch_after(timeout, dispatch_get_main_queue(), { () -> Void in
            completion?()
        })
        
    }
    
    private func configureRefreshControl()
    {
        let refreshControlTintColor = (self.view.backgroundColor == kWhiteColor) ? kDayNavigationBarBackgroundColor : kWhiteColor
        if let refresher = refreshControl
        {
            refresher.attributedTitle = NSAttributedString(string: "refreshing".localizedWithComment(""), attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 13)!, NSForegroundColorAttributeName:refreshControlTintColor])
            refresher.tintColor = refreshControlTintColor
        }
        else
        {
            refreshControl = UIRefreshControl()
            
            refreshControl?.attributedTitle = NSAttributedString(
                string: "refreshing".localizedWithComment(""),
                attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 13)!, NSForegroundColorAttributeName:refreshControlTintColor])
            
            refreshControl?.tintColor = refreshControlTintColor
            
            refreshControl?.addTarget(self,
                action: "startRefreshing:",
                forControlEvents: .ValueChanged)
            
            self.collectionDashboard.addSubview(refreshControl!)
        }
        
        if !refreshControl!.refreshing
        {
            refreshControl?.endRefreshing()
        }
    }
    
    //MARK:-----
    
    func reloadDashBoardViewWithDBElementsInfo(info:dashboardDBElementsInfoTuple)
    {
        if info.signals == nil && info.favourites == nil && info.other == nil
        {
            return
        }

        if let tapView = self.view.viewWithTag(0xAD12) as? TapGreetingView
        {
            tapView.removeFromSuperview()
        }
        
        self.collectionSource = HomeCollectionHandler(info: info)
        self.collectionSource?.elementSelectionDelegate = self
        let layoutInfoStruct = HomeSignalsHiddenFlowLayout.prepareLayoutStructWithInfo(info)
        
        let hiddenSignalsLayout = HomeSignalsHiddenFlowLayout(layoutInfoStruct: layoutInfoStruct)
        
        self.collectionDashboard.delegate = self.collectionSource
        self.collectionDashboard.dataSource = self.collectionSource
        
        self.collectionDashboard.reloadData()
        
        self.collectionDashboard.setCollectionViewLayout(hiddenSignalsLayout, animated: false)
    }
    
    
    func showElementCreationVC(sender:AnyObject)
    {
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {            
            newElementCreator.composingDelegate = self

            self.navigationController?.pushViewController(newElementCreator, animated: true)
            newElementCreator.editingStyle = .AddNew //- switched to be default
            if let tapView = self.view.viewWithTag(0xAD12)
            {
                tapView.removeFromSuperview()
            }
        }
    }
    
    func showAddTheVeryFirstElementPlus()
    {
        if let tapView = self.view.viewWithTag(0xAD12)
        {
            tapView.removeFromSuperview()
        }
        
        self.collectionSource?.deleteAllElements()
        let numberOfSections =  self.collectionDashboard.numberOfSections()
        if numberOfSections > 1
        {
            let collectionLayout = self.collectionDashboard.collectionViewLayout
            if let hiddenLayout = collectionLayout as? HomeSignalsHiddenFlowLayout
            {
                hiddenLayout.clearAllElements()
                self.collectionDashboard.reloadData()
            }
            else if let visibleLayout = collectionLayout as? HomeSignalsVisibleFlowLayout
            {
                visibleLayout.clearAllElements()
                self.collectionDashboard.reloadData()
            }
            
            collectionDashboard.dataSource = nil
            collectionDashboard.delegate = nil
            collectionDashboard.collectionViewLayout.invalidateLayout()
        }
        
        let tapView = TapGreetingView(frame: CGRectMake(0, 0, 200.0, 200.0))
        tapView.userInteractionEnabled = true
        tapView.opaque = true
        tapView.tag = 0xAD12
        
//        let imageView = UIImageView(frame: CGRectMake(50.0, 50.0, 100.0, 100.0))
//        imageView.contentMode = .ScaleAspectFit
//        imageView.image = UIImage(named: "icon-add")?.imageWithRenderingMode(.AlwaysTemplate)
//        imageView.tintColor = kDayNavigationBarBackgroundColor
//        imageView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]// UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
//        tapView.addSubview(imageView)
        var userName = "User"
        if let realUserName = DataSource.sharedInstance.user?.firstName
        {
            userName = realUserName
        }
        //let greetingLabel = UILabel(frame: tapView.bounds)
        //greetingLabel.numberOfLines = 0
        let greetingString = "Добро пожаловать, \(userName)\nНажмите здесь для создания первого элемента."
//        let attributedWelcome = NSAttributedString(string: greetingString, attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 15.0)!, NSForegroundColorAttributeName:kDayCellBackgroundColor])
//        greetingLabel.attributedText = attributedWelcome
        tapView.text = greetingString
        //tapView.addSubview(greetingLabel)
        
        let tapButton = UIButton(type:.System)
        tapButton.frame = tapView.bounds
        tapButton.addTarget(self, action: "showElementCreationVC:", forControlEvents: UIControlEvents.TouchUpInside)
        tapButton.backgroundColor = UIColor.clearColor()
        tapButton.opaque = true
        tapButton.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        
        tapView.addSubview(tapButton)
        
        tapView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
        
        self.view.addSubview(tapView)
    }
    
    //MARK: - MessageObserver
    func newMessagesWereAdded()
    {
        if let currentDataSource = self.collectionSource
        {
            if !currentDataSource.isSignalsToggled
            {
                dispatch_async(dispatch_get_main_queue()){ [weak self] in
                    if let weakSelf = self
                    {
                        weakSelf.collectionDashboard.reloadItemsAtIndexPaths([NSIndexPath(forItem: 1, inSection: 0)])
                    }
                }
            }
        }
    }
    // MARK: - Navigation
    
    func menuButtonTapped(sender:AnyObject?)
    {
        if let _ = sender as? UIButton //menu button
        {
            NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self.navigationController, userInfo: nil)
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    
    func leftEdgePan(recognizer:UIScreenEdgePanGestureRecognizer)
    {
        if recognizer.state == UIGestureRecognizerState.Began
        {
            print("left pan.")
            let translationX = round(recognizer.translationInView(recognizer.view!).x)
            let velocityX = round(recognizer.velocityInView(recognizer.view!).x)
            print(" Horizontal Velocity: \(velocityX)")
            print(" Horizontal Translation: \(translationX)")
        
//            if translationX > 60.0
//            {
                let ratio = ceil(velocityX / translationX)
                if  ratio > 3
                {
                    menuButtonTapped(nil)
                }
//            }
        }
    }
  
    //MARK: ElementSelectionDelegate
    func didTapOnElement(elementId:Int)
    {
        self.presentNewSingleElementVC(elementId)
    }
    
    func presentNewSingleElementVC(elementId:Int)
    {
        DataSource.sharedInstance.localDatadaseHandler?.readElementByIdAsync(elementId, completion: {[weak self] (foundElement) -> () in
            if let dbElement = foundElement
            {
                if let weakSelf = self
                {
                    var viewControllersToAppend = [UIViewController]()
                    if let rootElementsTree = DataSource.sharedInstance.localDatadaseHandler?.readRootElementTreeForElementManagedObjectId(dbElement.objectID)//DataSource.sharedInstance.getRootElementTreeForElement(rootElementId)
                    {
                        for anElement in rootElementsTree
                        {
                            if let elementController = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                            {
                                elementController.currentElement = anElement
                                viewControllersToAppend.append(elementController)
                            }
                        }
                    }
                    
                    if let newVC = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                    {
                        newVC.currentElement = dbElement
                        viewControllersToAppend.append(newVC)
                    }
                    
                    if let currentVCs = weakSelf.navigationController?.viewControllers
                    {
                        viewControllersToAppend.insert(currentVCs.first!, atIndex: 0)
                        weakSelf.navigationController?.setViewControllers(viewControllersToAppend, animated: true)
                    }        

                }
            }
        })
    }
    
    //MARK: ElementComposingDelegate

    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element)
    {
        handleAddingNewElement(newElement)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK: -----
    func handleAddingNewElement(element:Element)
    {
        // 1 - send new element to server
        // 2 - send passWhomIDs, if present
        // 3 - if new element successfully added - reload dashboard collectionView
        var passWhomIDs:Set<Int>?
         let nsNumberArray = element.passWhomIDs
        if !nsNumberArray.isEmpty
        {
            passWhomIDs = Set<Int>()
            for number in nsNumberArray
            {
                passWhomIDs!.insert(number)
            }
        }
        
        DataSource.sharedInstance.submitNewElementToServer(element, completion: {[weak self] (newElementID, submitingError) -> () in
            if let lvElementId = newElementID
            {
                
                if let passWhomIDsSet = passWhomIDs
                {
                    
                    DataSource.sharedInstance.addSeveralContacts(passWhomIDsSet, toElement: lvElementId, completion: { (succeededIDs, failedIDs) -> () in
                        if !failedIDs.isEmpty
                        {
                            print(" added to \(succeededIDs)")
                            print(" failed to add to \(failedIDs)")
                        }
                        else
                        {
                            print(" added to \(succeededIDs)")
                        }
                    })
                }
                
                DataSource.sharedInstance.localDatadaseHandler?.readHomeDashboardElements(true, completion: { [weak self] (info) -> () in
                    if let aSelf = self
                    {
                        aSelf.reloadDashBoardViewWithDBElementsInfo(info)
                    }
                })
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
    
    func elementWasDeleted(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo, _ = userInfo["elementIdInts"] as? [Int]
        {
            DataSource.sharedInstance.localDatadaseHandler?.readHomeDashboardElements(true) { (info) -> () in
                dispatch_async(dispatch_get_main_queue()) {[weak self] () -> Void in
                    if let weakSelf = self
                    {
                        weakSelf.reloadDashBoardViewWithDBElementsInfo(info)
                    }
                }
            }
        }
    }
    
    func elementsWereAdded(notification:NSNotification?)
    {
        if let _ = notification
        {
            DataSource.sharedInstance.localDatadaseHandler?.readHomeDashboardElements(true) { (info) -> () in
                dispatch_async(dispatch_get_main_queue()) {[weak self] () -> Void in
                    if let weakSelf = self
                    {
                        weakSelf.reloadDashBoardViewWithDBElementsInfo(info)
                    }
                }
            }
        }
    }
    
    //MARK: UIViewControllerTransitioningDelegate
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let fadeInTransitor = customTransitionAnimator as? FadeOpaqueAnimator
        {
            fadeInTransitor.transitionDirection = .FadeIn
            return fadeInTransitor
        }
        else if let menuShowTransitor = customTransitionAnimator as? MenuTransitionAnimator
        {
            menuShowTransitor.transitionDirection = .FadeIn
            return menuShowTransitor
        }
        
        print(" Will not animate view controller transitioning")
        return nil
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let fadeInTransitor = customTransitionAnimator as? FadeOpaqueAnimator
        {
            fadeInTransitor.transitionDirection = .FadeOut
            return fadeInTransitor
        }
        else if let menuShowTransitor = customTransitionAnimator as? MenuTransitionAnimator
        {
            menuShowTransitor.transitionDirection = .FadeOut
            return menuShowTransitor
        }
        
        print(" Will not animate view controller transitioning")
        return nil
    }

    
    //MARK:  Handling Notifications
    
    func nightModeDidChange(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo
        {
            if let nightModeEnabled = userInfo["mode"] as? Bool
            {
                print(" New Night Mode Value: \(nightModeEnabled)")
                setAppearanceForNightModeToggled(nightModeEnabled)
                self.collectionSource?.turnNightModeOn(nightModeEnabled)
                self.collectionDashboard.reloadData()
            }
        }
        else
        {
            // handle recieving call not from notification centre
            let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
            setAppearanceForNightModeToggled(nightModeOn)
            self.collectionSource?.turnNightModeOn(nightModeOn)
            //self.collectionDashboard.reloadData()
        }
        
        configureRefreshControl()
    }
    
    func didTapOnChatMessage(notification:NSNotification?)
    {
        
        if let
                elementIdNumber = notification?.object as? NSNumber,
                foundDbElement = DataSource.sharedInstance.localDatadaseHandler?.readElementById(elementIdNumber.integerValue),
                currentVCs = self.navigationController?.viewControllers
        {
            var viewControlelrsToShow = currentVCs
            if let roots = DataSource.sharedInstance.localDatadaseHandler?.readRootElementTreeForElementManagedObjectId(foundDbElement.objectID)
            {
                for aRootElement in roots
                {
                    if let singleElementVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                    {
                        singleElementVC.currentElement = aRootElement
                        viewControlelrsToShow.append(singleElementVC)
                    }
                }
            }
            
            if let
                singleElementVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC,
                chatVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChatVC") as? ChatVC
            {
                singleElementVC.currentElement = foundDbElement
                chatVC.currentElement = foundDbElement
                viewControlelrsToShow.append(singleElementVC)
                viewControlelrsToShow.append(chatVC)
            }
            
            self.navigationController?.setViewControllers(viewControlelrsToShow, animated:true)
        }
    }
    
    func showRecentActivity(sender:AnyObject?)
    {
        self.performSegueWithIdentifier("ShowRecentActivitySegue", sender: nil)
    }
    
    func showSortedElements(sender:AnyObject?)
    {
        self.performSegueWithIdentifier("ShowSortedElements", sender: sender)
    }
    
    //MARK: ------ menu displaying
    func handleDisplayingMenuAnimated(animated:Bool, completion completionBlock:(()->())? = nil)
    {

        // hide MenuTableVC
        if let menuPresentedVC = self.presentedViewController as? MenuVC
        {
            let menuAnimator = MenuTransitionAnimator()
            menuAnimator.shouldAnimate = animated
            customTransitionAnimator = menuAnimator
            
            menuPresentedVC.transitioningDelegate = self
            menuPresentedVC.dismissViewControllerAnimated(true, completion: { () -> Void in
                if let compBlock = completionBlock
                {
                    compBlock()
                }
                
            }) //NOTE! this does not dismiss TabBarController, but dismisses menu VC from Tabbar`s presented view controller. the same could be achieved by calling "menuPresendedVC.dismissViewControllerAnimated ...."
            return
        }
        if let contactsOrProfileNavHolderVC = self.presentedViewController as? UINavigationController
        {
            contactsOrProfileNavHolderVC.dismissViewControllerAnimated(true, completion: { () -> Void in
                completionBlock?()
            })
            return
        }
        
        // present MenuTableVC
        if let menuVC = self.storyboard?.instantiateViewControllerWithIdentifier("MenuVC") as? MenuVC
        {
            let menuAnimator = MenuTransitionAnimator()
            menuAnimator.shouldAnimate = animated
            customTransitionAnimator = menuAnimator
            
            menuVC.modalPresentationStyle = .Custom
            menuVC.transitioningDelegate = self
            
            self.presentViewController(menuVC, animated: true, completion: { () -> Void in
                if let compBlock = completionBlock
                {
                    compBlock()
                }
            })
        }
    }
    
    //MARK: - On Initial start
    func startReadingHomeScreenData(attemptCount:Int)
    {
        if attemptCount > 2
        {
            dispatch_async(dispatch_get_main_queue()){[weak self] in
                if let weakSelf = self
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    weakSelf.showAddTheVeryFirstElementPlus()
                    
                    if let refresher =  DataSource.sharedInstance.dataRefresher
                    {
                        if !refresher.isCancelled && !refresher.isInProgress
                        {
                            refresher.startRefreshingElementsWithTimeoutInterval(30.0)
                        }
                    }
                    else{
                        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 5.0))
                        dispatch_after(timeout, getBackgroundQueue_UTILITY(), { () -> Void in
                            DataSource.sharedInstance.dataRefresher = DataRefresher()
                            DataSource.sharedInstance.dataRefresher?.startRefreshingElementsWithTimeoutInterval(30.0)
                            
                        })
                    }
                }
            }
            return
        }
        let fetchDashboardOp = NSBlockOperation() { _ in
            
            let fetchSemaphore = dispatch_semaphore_create(0)
            
            DataSource.sharedInstance.localDatadaseHandler?.readHomeDashboardElements(true) {[weak self] (info) -> () in
                    
                    DataSource.sharedInstance.dashBoardInfo = info
                    
                    
                    if let weakSelf = self, dashInfo = DataSource.sharedInstance.dashBoardInfo
                    {
                        if dashInfo.signals == nil && dashInfo.favourites == nil && dashInfo.other == nil
                        {
                            DataSource.sharedInstance.loadAllElementsInfo({ (success, failure) -> () in
//                                if success
//                                {
                                    /// refetch dashboard elements
                                    if let weakSelf = self
                                    {
                                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                            weakSelf.startReadingHomeScreenData(attemptCount + 1)
                                        })
                                        
                                    }
//                                }
                            })
                            
                            return
                        }
                        
                        if let refresher =  DataSource.sharedInstance.dataRefresher
                        {
                            if !refresher.isCancelled && !refresher.isInProgress
                            {
                                refresher.startRefreshingElementsWithTimeoutInterval(30.0)
                            }
                        }
                        else{
                            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 5.0))
                            dispatch_after(timeout, getBackgroundQueue_UTILITY(), { () -> Void in
                                DataSource.sharedInstance.dataRefresher = DataRefresher()
                                DataSource.sharedInstance.dataRefresher?.startRefreshingElementsWithTimeoutInterval(30.0)
                                
                            })
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            weakSelf.reloadDashBoardViewWithDBElementsInfo(dashInfo)
                        })
                    }
                dispatch_semaphore_signal(fetchSemaphore)
            }
            
            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 3.0))
            
            dispatch_semaphore_wait(fetchSemaphore, timeout )
           
        }
        
        fetchDashboardOp.completionBlock = { _ in
            
            if DataSource.sharedInstance.operationQueue.suspended && DataSource.sharedInstance.operationQueue.operationCount > 0
            {
                DataSource.sharedInstance.operationQueue.suspended = false  //starts loading stuff from network
            }
        }
        
        
        NSOperationQueue().addOperation(fetchDashboardOp)
    }
    
}
