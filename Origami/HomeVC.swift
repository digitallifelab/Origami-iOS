//
//  HomeVC.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, ElementSelectionDelegate, ElementComposingDelegate, UIViewControllerTransitioningDelegate
{

    @IBOutlet var collectionDashboard:UICollectionView!
    @IBOutlet var navigationBackgroundView:UIView!
    
    var collectionSource:HomeCollectionHandler?
    var customTransitionAnimator:UIViewControllerAnimatedTransitioning?
    
    private var loadingAllElementsInProgress = false
 
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        DataSource.sharedInstance.loadExistingDashboardElementsFromLocalDatabaseCompletion { (elements, error) -> () in
            
            if let elementsDict = elements
            {
                if let signals = elementsDict["signals"]
                {
                    for aSignalElement in signals
                    {
                        println("Signal: \(aSignalElement.title)")
                    }
                }
                if let favourites = elementsDict["favor"]
                {
                    for aFavorite in favourites
                    {
                        println("Favourite: \(aFavorite.title)")
                    }
                }
                if let other = elementsDict["usual"]
                {
                    for anUsual in other
                    {
                        println("Usual: \(anUsual.title)")
                    }
                }
            }
        }
        
        self.title = "Home"
        configureNavigationTitleView()// to remove "Home" from navigation bar.

        self.collectionDashboard.registerClass(DashHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "DashHeader")
        self.collectionSource = HomeCollectionHandler()
        self.collectionDashboard.dataSource = self.collectionSource
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        loadingAllElementsInProgress = true
        DataSource.sharedInstance.loadAllElements {[weak self] (success, failure) -> () in
            if let wSelf = self
            {
                if success
                {
                   // wSelf.reloadDashboardView()
                    
                    if let wSelf = self
                    {
                        println(" \(wSelf) Loaded elements")
                        wSelf.loadingAllElementsInProgress = false
                        wSelf.reloadDashboardView()
                    }
                }
            }
            else
            {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let wSelf = self
                {
                    wSelf.loadingAllElementsInProgress = false
                    #if DEBUG
                    wSelf.showAlertWithTitle("Failed", message: " this is a non production error message. \n Did not load Elements for dashboard.", cancelButtonTitle: "Ok")
                    #endif
                }
            }
        }
        
        configureRightBarButtonItem()
        configureLeftBarButtonItem()        
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        nightModeDidChange(nil)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //register for night-day modes switching
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "nightModeDidChange:", name: kMenu_Switch_Night_Mode_Changed, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processMenuDisplaying:", name: kMenu_Buton_Tapped_Notification_Name, object: nil)
        if DataSource.sharedInstance.isMessagesEmpty()
        {
            DataSource.sharedInstance.loadAllMessagesFromServer()
        }
        
        if !loadingAllElementsInProgress
        {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            reloadDashboardView()
        }
        
        self.tabBarController?.tabBar.layoutSubviews()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Buton_Tapped_Notification_Name, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kMenu_Switch_Night_Mode_Changed, object: nil)
    }
    
    //MARK: -- --
    
    func configureRightBarButtonItem()
    {
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "showElementCreationVC:")
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func configureLeftBarButtonItem()
    {
//        let menuButton = UIButton.buttonWithType(.Custom) as! UIButton
//        menuButton.frame = CGRectMake(0, 0, 35 , 35)
//        menuButton.tintColor = UIColor.whiteColor()
//        menuButton.setImage(UIImage(named: "icon-menu"), forState: UIControlState.Normal)
//        menuButton.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2)
//        menuButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        
        var rightButton = UIButton.buttonWithType(.Custom) as! UIButton
        rightButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
        rightButton.setImage(UIImage(named: "icon-options"), forState: .Normal)
        rightButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        rightButton.tintColor = UIColor.whiteColor()
        
        var leftBarButton = UIBarButtonItem(customView: rightButton)
        
        //let menuButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: self, action: "menuButtonTapped:")
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func configureNavigationTitleView()
    {
        let blankLabel = UILabel()
        blankLabel.font = UIFont(name: "SegoeUI-Semibold", size: 25.0)
        blankLabel.text = "Origami"
        blankLabel.sizeToFit()
        blankLabel.textColor = UIColor.whiteColor()
        self.navigationItem.titleView = blankLabel
    }
    
    //MARK:-----
    func reloadDashboardView()
    {
        loadingAllElementsInProgress = true
        
        NSOperationQueue().addOperationWithBlock({ [weak self] () -> Void in
            
            DataSource.sharedInstance.getDashboardElements({(dashboardElements) -> () in
                
                NSOperationQueue.mainQueue().addOperationWithBlock({[weak self] () -> Void in
                    if let aSelf = self
                    {
                        var shouldReloadCollection = false
                        if let currentCollectionDataSource = aSelf.collectionSource
                        {
                            if dashboardElements[1]!.count != currentCollectionDataSource.countSignals()
                            {
                                shouldReloadCollection = true
                            }
                            else if dashboardElements[2]!.count != currentCollectionDataSource.favourites!.count
                            {
                                shouldReloadCollection = true
                            }
                            else if dashboardElements[3]!.count != currentCollectionDataSource.other!.count
                            {
                                shouldReloadCollection = true
                            }
                        }
                        if let customLayout = aSelf.collectionDashboard!.collectionViewLayout as? HomeSignalsHiddenFlowLayout
                        {
                            if shouldReloadCollection
                            {
                                aSelf.collectionSource = HomeCollectionHandler(signals: dashboardElements[1]!, favourites: dashboardElements[2]!, other: dashboardElements[3]!)
                                aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                
                                aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                aSelf.collectionDashboard.reloadData()
                                //set new layout
                            }
                            
                            customLayout.privSignals = dashboardElements[1]!.count
                            customLayout.privFavourites = dashboardElements[2]!
                            customLayout.privOther = dashboardElements[3]!
                            
                            //customLayout.invalidateLayout() // to recalculate position of home elements
                        }
                        else if let visibleLayout = aSelf.collectionDashboard?.collectionViewLayout as? HomeSignalsVisibleFlowLayout
                        {
                            if shouldReloadCollection
                            {
                                //aSelf.collectionDashboard.collectionViewLayout.invalidateLayout()
                                
                                let newLayout = HomeSignalsHiddenFlowLayout(signals: dashboardElements[1]!.count , favourites: dashboardElements[2]!, other: dashboardElements[3]!)
                                
                             
                                
                                aSelf.collectionDashboard?.performBatchUpdates({ () -> Void in
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: dashboardElements[1]!, favourites: dashboardElements[2]!, other: dashboardElements[3]!)
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    aSelf.collectionDashboard.reloadData()
                                    aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    
                                }, completion: { (finished) -> Void in
                                    if shouldReloadCollection
                                    {
                                        aSelf.collectionDashboard?.setCollectionViewLayout(newLayout, animated: true)
                                    }
                                })
                            }
                        }
                        
                        aSelf.loadingAllElementsInProgress = false
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    }
                })
            })
        })
    }
    
    
    
    func showElementCreationVC(sender:AnyObject)
    {
        if let newElementCreator = self.storyboard?.instantiateViewControllerWithIdentifier("NewElementComposingVC") as? NewElementComposerViewController
        {
            customTransitionAnimator = FadeOpaqueAnimator()
            
            newElementCreator.composingDelegate = self
            newElementCreator.modalPresentationStyle = .Custom
            newElementCreator.transitioningDelegate = self
            
            self.presentViewController(newElementCreator, animated: true, completion: { () -> Void in
                newElementCreator.editingStyle = .AddNew
            })
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
//        if sender is Element
//        {
//            if let destinationVC = segue.destinationViewController as? ElementDashboardVC
//            {
//                destinationVC.element = sender as! Element
//            }
//        }
    }
    
    func menuButtonTapped(sender:AnyObject?)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self.navigationController, userInfo: nil)
    }

    //MARK: ElementSelectionDelegate
    func didTapOnElement(element: Element)
    {
//        let rootId = element.rootElementId
//        if rootId.boolValue
//        {
            presentNewSingleElementVC(element)
//        }
    }
    
    func presentNewSingleElementVC(element:Element)
    {
        let rootId = element.rootElementId.integerValue
        
        if rootId == 0
        {
            if let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
            {
                newVC.currentElement = element
                self.navigationController?.pushViewController(newVC, animated: true)
            }
        }
        else
        {
            //calculate all the subordinates tree
            if let elementsTree = DataSource.sharedInstance.getRootElementTreeForElement(element)
            {
                var viewControllers = [UIViewController]()
                
                //create viewControllers for all elements
                
                for lvElement in elementsTree.reverse()
                {
                    if let dashboardVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                    {
                        dashboardVC.currentElement = lvElement
                        viewControllers.append(dashboardVC)
                    }
                }
                //append last view controller on top of the navigation controller`s stack
                if let targetVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                {
                    targetVC.currentElement = element
                    viewControllers.append(targetVC)
                }
                //show last
                if let currentVCs = self.navigationController?.viewControllers as? [UIViewController]
                {
                    var vcS = currentVCs
                    vcS += viewControllers
                    self.navigationController?.setViewControllers(vcS, animated: true)
                }
            }
        }
    }
    
    //MARK: ElementComposingDelegate

    func newElementComposerWantsToCancel(composer: NewElementComposerViewController) {
        
        if let fadeAnimator = customTransitionAnimator as? FadeOpaqueAnimator
        {
            composer.dismissViewControllerAnimated(true, completion: nil)
            return
        }
        // no animator. create one to dismiss nicely
        customTransitionAnimator = FadeOpaqueAnimator()
        composer.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func newElementComposer(composer: NewElementComposerViewController, finishedCreatingNewElement newElement: Element)
    {
        // no animator. create one to dismiss nicely
        customTransitionAnimator = FadeOpaqueAnimator()
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
         let nsNumberArray = element.passWhomIDs
        if !nsNumberArray.isEmpty
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
                    
                    DataSource.sharedInstance.addSeveralContacts(passWhomIDsArray, toElement: lvElementId, completion: { (succeededIDs, failedIDs) -> () in
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
                        weakSelf.reloadDashboardView()
                    }
                }
                else
                {
                    if let weakSelf = self
                    {
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
        
        println(" Will not animate view controller transitioning")
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
        
        println(" Will not animate view controller transitioning")
        return nil
    }
    
    //MARK: Alert
    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
        alertController.addAction(closeAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    
    //MARK:  Handling Notifications
    
    func processMenuDisplaying(notification:NSNotification?)
    {
        handleDisplayingMenuAnimated(true, completion: {[weak self] () -> () in
            if let info = notification?.userInfo as? [String:Int], numberTapped = info["tapped"]
            {
                if let aSelf = self
                {
                    switch numberTapped
                    {
                    case 1:
                        aSelf.showUserProfileVC()
                    default:
                        break
                    }
                }
            }
        })
    }
    
    func nightModeDidChange(notification:NSNotification?)
    {
        if let note = notification, userInfo = note.userInfo
        {
            if let nightModeEnabled = userInfo["mode"] as? Bool
            {
                println(" New Night Mode Value: \(nightModeEnabled)")
                setAppearanceForNightModeToggled(nightModeEnabled)
            }
        }
        else
        {
            // handle recieving call not from notification centre
            let nightModeOn = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)
            setAppearanceForNightModeToggled(nightModeOn)
        }
    }
    
    func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.tabBarController?.tabBar.tintColor = kWhiteColor
        
        if nightModeOn
        {
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar

            
            self.tabBarController?.tabBar.backgroundColor = UIColor.blackColor()
        }
        else
        {
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
            self.navigationBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
            
            self.tabBarController?.tabBar.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.8)

        }
        
        self.collectionSource?.turnNightModeOn(nightModeOn)
        self.collectionDashboard.reloadData()
        
    }
    
    
    //MARK: ------ menu displaying
    func handleDisplayingMenuAnimated(animated:Bool, completion completionBlock:(()->())? = nil)
    {

        // hide MenuTableVC
        if let menuPresentedVC = self.presentedViewController as? MenuVC//MenuTableViewController
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
        
        if !animated
        {
            if let compBlock = completionBlock
            {
                compBlock()
            }
            return
        }
        // present MenuTableVC
        if let menuVC = self.storyboard?.instantiateViewControllerWithIdentifier("MenuVC") as? MenuVC//MenuTableViewController
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
    
    func showUserProfileVC()
    {
        if let userProfileVC = self.storyboard?.instantiateViewControllerWithIdentifier("UserProfileVC") as? UserProfileVC
        {
            userProfileVC.modalPresentationStyle = .Custom
            userProfileVC.transitioningDelegate = self
            
            customTransitionAnimator = FadeOpaqueAnimator()
            
            self.presentViewController(userProfileVC, animated: true, completion: nil)
        }
    }
    
}
