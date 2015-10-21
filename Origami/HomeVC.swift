//
//  HomeVC.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, ElementSelectionDelegate, ElementComposingDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate/*, MessageObserver*/
{

    @IBOutlet var collectionDashboard:UICollectionView!
    //@IBOutlet var bottomHomeToolBarButton:UIBarButtonItem!
    
    var collectionSource:HomeCollectionHandler?
    var customTransitionAnimator:UIViewControllerAnimatedTransitioning?
    
    private var refreshControl:UIRefreshControl?
    var shouldReloadCollection = false
    
//    required init?(coder aDecoder: NSCoder)
//    {
//        super.init(coder: aDecoder)
//    }
    
    deinit
    {
        print("\n -> removing HomeVC from NotificationCenter ->\n")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
   
        //self.collectionDashboard.contentInset = UIEdgeInsetsMake(44.0, 0.0, 44.0, 0.0)
        //self.collectionDashboard.layer.borderWidth = 2.0
        self.title = "Home"
        configureNavigationTitleView()// to remove "Home" from navigation bar.
        
        self.collectionDashboard.registerClass(DashHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "DashHeader")
        self.collectionSource = HomeCollectionHandler()
        self.collectionDashboard.dataSource = self.collectionSource
        
        
        configureRightBarButtonItem()
        configureLeftBarButtonItem()
        configureNavigationControllerToolbarItems()
        


        print("\(self)  viewDidLoad")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "recievedMessagesFinishedNotification:", name: FinishedLoadingMessages, object: nil)
        
        if DataSource.sharedInstance.dataRefresher == nil && DataSource.sharedInstance.user != nil && DataSource.sharedInstance.loadingAllElementsInProgress == false
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            print("-> Starting to load AllElementsInfo ....")
            DataSource.sharedInstance.loadAllElementsInfo {[weak self] (success, failure) -> () in
                if let wSelf = self
                {
                    if success
                    {
                        // wSelf.reloadDashboardView()
                        
                        if let wSelf = self
                        {
                            //print(" \(wSelf) Loaded elements")
                            wSelf.shouldReloadCollection = true
                            print("reloadDashboardView from viewDidLoad - success TRUE")
                            wSelf.reloadDashboardView()
                        }
                    }
                    else
                    {
                        
                        print("reloadDashboardView from viewDidLoad - success FALSE")
                        wSelf.reloadDashboardView()
                    }
                    //wSelf.loadingAllElementsInProgress = false
                    
                    let bgQueue = dispatch_queue_create("backgroundQueue", DISPATCH_QUEUE_CONCURRENT)
                    let time: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.0))
                    dispatch_after(time, bgQueue, {/*[weak self]*/ () -> Void in
                        
                        if let _ = DataSource.sharedInstance.user?.userId
                        {
                            if DataSource.sharedInstance.isMessagesEmpty() && DataSource.sharedInstance.shouldLoadAllMessages
                            {
//                                DataSource.sharedInstance.loadAllMessagesFromServer()
                                //TODO: get last message id from LocalDataBase
                                DataSource.sharedInstance.syncLastMessages(0)  { (success, error) -> () in
                                    
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        NSNotificationCenter.defaultCenter().postNotificationName(FinishedLoadingMessages, object: DataSource.sharedInstance)
                                    })
                                    
                                    DataSource.sharedInstance.messagesLoader = MessagesLoader()
                                    DataSource.sharedInstance.startRefreshingNewMessages()
                                }
                            }
                        }
                    })
                }
                else
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if let wSelf = self
                    {
                        
                        // #if DEBUG
                        wSelf.showAlertWithTitle("Failed", message: " this is a non production error message. \n Did not load Elements for dashboard.", cancelButtonTitle: "Ok")
                        //#endif
//                        wSelf.loadingAllElementsInProgress = false
                    }
                }
                
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    @available(iOS 8.0, *)
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        
//        coordinator.animateAlongsideTransition({[unowned self] (context) -> Void in
//                if size.width > size.height
//                {
//                    self.collectionDashboard.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
//                }
//                else
//                {
//                    self.collectionDashboard.contentInset = UIEdgeInsetsZero
//                }
//            })
//            { (context) -> Void in
//                
//        }
//        
//        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//    }
//    
//    @available(iOS 8.0, *)
//    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        
//        
//        if self.traitCollection.horizontalSizeClass == .Compact && newCollection.horizontalSizeClass == .Regular
//        {
//            self.collectionDashboard.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
//            return
//        }
//        
//        if self.traitCollection.horizontalSizeClass == .Regular && newCollection.horizontalSizeClass == .Compact
//        {
//            self.collectionDashboard.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
//            return
//        }
//        
//        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
//        
//    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        if let _ = DataSource.sharedInstance.user
        {
            nightModeDidChange(nil)
        }
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
            
            if !DataSource.sharedInstance.loadingAllElementsInProgress
            {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                print("-> reloadDashboardView() from viewDidAppear")
                
                //if DataSource.sharedInstance.shouldReloadAfterElementChanged
                //{
                    reloadDashboardView()
                //}
            }
            
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
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let weakRefreshControl = sender
                {
                    weakRefreshControl.endRefreshing()
                }
            })
        }
    }
    
    private func refreshMainDashboard(completion:(()->())?)
    {
        let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 1.5))
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
    func reloadDashboardView()
    {
        print("-> reloadDashboardView")
        //loadingAllElementsInProgress = true
        //let currentOffset = self.collectionDashboard.contentOffset
        DataSource.sharedInstance.getDashboardElements({[weak self](dashboardElements) -> () in
            
                if let aSelf = self
                {
                    if let currentCollectionDataSource = aSelf.collectionSource
                    {
                        let countCurrentSignals = currentCollectionDataSource.countSignals()
                        let countCurrentFavs = currentCollectionDataSource.countFavourites()
                        let countCurrentOther = currentCollectionDataSource.countOther()
                        
                        if let recievedElements = dashboardElements
                        {
                            var newSignalsCount = 0
                            var newSignals:[Element]?
                            if let lvNewSignals = recievedElements[1]
                            {
                                newSignals = lvNewSignals
                                newSignalsCount = lvNewSignals.count
                            }
                            
                            var newFavouritesCount = 0
                            var newFavs:[Element]?
                            if let lvNewFavs = recievedElements[2]
                            {
                                newFavs = lvNewFavs
                                newFavouritesCount = lvNewFavs.count
                            }
                            
                            var newOtherCount = 0
                            var newOther:[Element]?
                            if let lvNewOther = recievedElements[3]
                            {
                                newOther = lvNewOther
                                newOtherCount = lvNewOther.count
                            }
                            
                            if newSignalsCount == 0 && newFavouritesCount == 0 && newOtherCount == 0
                            {
                                aSelf.showAddTheVeryFirstElementPlus()
                                return
                            }
                            
                            if newSignalsCount != countCurrentSignals || newFavouritesCount != countCurrentFavs || newOtherCount != countCurrentOther
                            {
                                aSelf.shouldReloadCollection = true
                            }
                            
                            if let hiddenLayout = aSelf.collectionDashboard!.collectionViewLayout as? HomeSignalsHiddenFlowLayout
                            {
                                if aSelf.shouldReloadCollection || DataSource.sharedInstance.shouldReloadAfterElementChanged
                                {
                                    DataSource.sharedInstance.shouldReloadAfterElementChanged = false
                                    
                                    hiddenLayout.privSignals = newSignalsCount + 1
                                    
                                    hiddenLayout.privFavourites = newFavs
                                    
                                    hiddenLayout.privOther = newOther
                                    
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: newSignals, favourites: newFavs, other: newOther)
                                   
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    aSelf.collectionDashboard.reloadData()
                                    //aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    //aSelf.collectionDashboard.collectionViewLayout.invalidateLayout()
                                    aSelf.collectionDashboard.setCollectionViewLayout(hiddenLayout, animated: true)
                                    aSelf.shouldReloadCollection = false
                               
                                }
                                else
                                {
                                    print(" ->  hiddenLayout. Will not reload Home CollectionView.")
                                }
                            
                                //customLayout.invalidateLayout() // to recalculate position of home elements
                            }
                            else if let _ = aSelf.collectionDashboard?.collectionViewLayout as? HomeSignalsVisibleFlowLayout
                            {
                                if aSelf.shouldReloadCollection || DataSource.sharedInstance.shouldReloadAfterElementChanged
                                {
                                    DataSource.sharedInstance.shouldReloadAfterElementChanged = false
                                    
                                    aSelf.collectionDashboard.collectionViewLayout.invalidateLayout()
                                    
                                    let newLayout = HomeSignalsHiddenFlowLayout(signals: newSignalsCount , favourites: newFavs, other: newOther)
                                    
                                    //                                aSelf.collectionDashboard?.performBatchUpdates({ () -> Void in
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: newSignals, favourites: newFavs, other: newOther)
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    aSelf.collectionDashboard.reloadData()
                                    //aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    
                                    //                                }, completion: { (finished) -> Void in
                                    if aSelf.shouldReloadCollection
                                    {
                                        aSelf.collectionDashboard?.setCollectionViewLayout(newLayout, animated: true)
                                    }
                                    //                                })
                                    
                                    aSelf.shouldReloadCollection = false
                                }
                                else
                                {
                                    print(" -> visibleLayout. Will not reload Home CollectionView.")
                                }
                            }
                            else
                            {
                                print(" -> Hone VC. New Layout.")
                                let newLayout = HomeSignalsHiddenFlowLayout(signals: newSignalsCount + 1 , favourites: newFavs, other: newOther)
                                
                                aSelf.collectionDashboard?.performBatchUpdates({ () -> Void in
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: newSignals, favourites: newFavs, other: newOther)
                                    print(" -> did assign collection datasource")
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    
                                    //aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    
                                    }, completion: { (finished) -> Void in
                                        
                                        aSelf.collectionDashboard?.setCollectionViewLayout(newLayout, animated: true)
                                        aSelf.collectionDashboard.collectionViewLayout.invalidateLayout()

                                })
                            }
                            
                            //aSelf.loadingAllElementsInProgress = false
                            aSelf.shouldReloadCollection = false
                        
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                          
                        }
                        else
                        {
                            if let _ = DataSource.sharedInstance.user?.token //as? String
                            {
                                aSelf.showAddTheVeryFirstElementPlus()
                            }
                            else if let weakSelf = self
                            {
                                weakSelf.showAlertWithTitle("Error", message: "Please relogin.", cancelButtonTitle: "Close")
                            }
                             UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        }
                    }
                }
            
        })
    }
    
    
    
    func showElementCreationVC(sender:AnyObject)
    {
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            //customTransitionAnimator = FadeOpaqueAnimator()
            //let composerHolder = UINavigationController(rootViewController: newElementCreator)
            
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
        self.collectionSource?.deleteAllElements()
        let numberOfSections =  self.collectionDashboard.numberOfSections()
        if numberOfSections > 1
        {
            let collectionLayout = self.collectionDashboard.collectionViewLayout
            if let hiddenLayout = collectionLayout as? HomeSignalsHiddenFlowLayout
            {
                hiddenLayout.clearAllElements()
                self.collectionDashboard.reloadData()
                //self.collectionDashboard.deleteSections(NSIndexSet(indexesInRange: NSMakeRange(1, numberOfSections - 1)))
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
        
       
        let tapView = UIView(frame: CGRectMake(0, 0, 200.0, 200.0))
        tapView.userInteractionEnabled = true
        tapView.backgroundColor = UIColor.whiteColor()
        tapView.opaque = true
        tapView.tag = 0xAD12
        
        let imageView = UIImageView(frame: CGRectMake(50.0, 50.0, 100.0, 100.0))
        imageView.contentMode = .ScaleAspectFit
        imageView.image = UIImage(named: "icon-add")?.imageWithRenderingMode(.AlwaysTemplate)
        imageView.tintColor = kDayNavigationBarBackgroundColor
        imageView.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]// UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        tapView.addSubview(imageView)
        
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
    func didTapOnElement(element: Element)
    {
        self.presentNewSingleElementVC(element)
    }
    
    func presentNewSingleElementVC(element:Element)
    {
        var viewControllersToAppend = [UIViewController]()
        if let rootElementsTree = DataSource.sharedInstance.getRootElementTreeForElement(element)
        {
            for anElement in rootElementsTree
            {
                if let elementController = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                {
                    elementController.currentElement = anElement
                    viewControllersToAppend.append(elementController)
                }
            }
        }
        
        if let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
        {
            newVC.currentElement = element
           viewControllersToAppend.append(newVC)
        }
        
        if let currentVCs = self.navigationController?.viewControllers
        {
            viewControllersToAppend.insert(currentVCs.first!, atIndex: 0)
            self.navigationController?.setViewControllers(viewControllersToAppend, animated: true)
        }        
    }
    
    //MARK: ElementComposingDelegate

    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element)
    {
        self.navigationController?.popViewControllerAnimated(true)
        
        handleAddingNewElement(newElement)
    }
    
    //MARK: - replace next 3 functions, or delete them after refactoring: ->  they are optional
//    func newElementComposerTitleForNewElement(composer: NewElementComposerViewController) -> String? {
//        return nil
//    }
//    
//    func newElementComposerDetailsForNewElement(composer: NewElementComposerViewController) -> String? {
//        return nil
//    }
//    
//    func newElementForComposer(composer: NewElementComposerViewController) -> Element? {
//        return nil
//    }
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
                    if let weakSelf = self
                    {
                        weakSelf.shouldReloadCollection = true
                        weakSelf.reloadDashboardView()
                    }
                }
                else
                {
                    if let weakSelf = self
                    {
                        weakSelf.shouldReloadCollection = true
                        weakSelf.reloadDashboardView()
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
    
    func elementWasDeleted(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo, _ = userInfo["elementIdInts"] as? [Int]
        {
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.reloadDashboardView()
                }
            })
            
        }
    }
    
    func elementsWereAdded(notification:NSNotification?)
    {
        if let _ = notification
        {
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.reloadDashboardView()
                }
            })
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
        // 1 - instantiate SinglElementDashboardVC
        // 2 - instantiate ChatVC
        // 3 - set viewControllers for self.navigationController
        if let tappedMessage = notification?.object as? Message, messageElementId = tappedMessage.elementId, targetElement = DataSource.sharedInstance.getElementById(messageElementId)
        {
            if let
                singleElementVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC,
                chatVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChatVC") as? ChatVC
            {
                singleElementVC.currentElement = targetElement
                chatVC.currentElement = targetElement
                
                var toShowVCs = [UIViewController]()
                if let viewControllers = self.navigationController?.viewControllers //as? [UIViewController]
                {
                    toShowVCs += viewControllers
                }
                
                toShowVCs.append(singleElementVC)
                toShowVCs.append(chatVC)
                
                self.navigationController?.setViewControllers(toShowVCs, animated: true)
            }
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
    
}
