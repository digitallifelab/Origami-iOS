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
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear(animated)
        nightModeDidChange(nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        
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
        let menuButton = UIButton.buttonWithType(.Custom) as! UIButton
        menuButton.frame = CGRectMake(0, 0, 35 , 35)
        menuButton.tintColor = UIColor.whiteColor()
        menuButton.setImage(UIImage(named: "icon-menu"), forState: UIControlState.Normal)
        menuButton.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2)
        menuButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        
        var leftBarButton = UIBarButtonItem(customView: menuButton)
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
                                aSelf.collectionSource!.elementSelectionDelegate = self
                                
                                aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                aSelf.collectionDashboard.reloadData()
                                //set new layout
                            }
                            
                            customLayout.privSignals = dashboardElements[1]!.count
                            customLayout.privFavourites = dashboardElements[2]!
                            customLayout.privOther = dashboardElements[3]!
                            
                            customLayout.invalidateLayout() // to recalculate position of home elements
                        }
                        else if let visibleLayout = aSelf.collectionDashboard?.collectionViewLayout as? HomeSignalsVisibleFlowLayout
                        {
                            if shouldReloadCollection
                            {
                                let newLayout = HomeSignalsHiddenFlowLayout(signals: dashboardElements[1]!.count , favourites: dashboardElements[2]!, other: dashboardElements[3]!)
                                
                                aSelf.collectionDashboard?.setCollectionViewLayout(newLayout, animated: false)
                                
                                aSelf.collectionDashboard?.performBatchUpdates({ () -> Void in
                                    
//                                     aSelf.collectionDashboard?.setCollectionViewLayout(newLayout, animated: false)
                                    
                                }, completion: { (finished) -> Void in
                                    if shouldReloadCollection
                                    {
                                        aSelf.collectionSource = HomeCollectionHandler(signals: dashboardElements[1]!, favourites: dashboardElements[2]!, other: dashboardElements[3]!)
                                        aSelf.collectionSource!.elementSelectionDelegate = self
                                        
                                        aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                        aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                        aSelf.collectionDashboard.reloadData()
                                        //set new layout
                                        
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
            
            self.presentViewController(newElementCreator, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if sender is Element
        {
            if let destinationVC = segue.destinationViewController as? ElementDashboardVC
            {
                destinationVC.element = sender as! Element
            }
        }
    }
    
    func menuButtonTapped(sender:AnyObject?)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: self.navigationController, userInfo: nil)
    }

    //MARK: ElementSelectionDelegate
    func didTapOnElement(element: Element)
    {
        if let rootId = element.rootElementId // we have to show breadcrumbs instead of back button in navigationItem
        {
            if rootId.integerValue == 0
            {
                //performSegueWithIdentifier("PresentChildElement", sender: element)
                testPresentNewSingleElementVC(element)
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
                        if let dashboardVC = self.storyboard?.instantiateViewControllerWithIdentifier("ElementDashboard") as? ElementDashboardVC
                        {
                            dashboardVC.element = lvElement
                            viewControllers.append(dashboardVC)
                        }
                    }
                    //append last view controller on top of the navigation controller`s stack
                    if let targetVC = self.storyboard?.instantiateViewControllerWithIdentifier("ElementDashboard") as? ElementDashboardVC
                    {
                        targetVC.element = element
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
        else
        {
           performSegueWithIdentifier("PresentChildElement", sender: element)
        }
    }
    
    func testPresentNewSingleElementVC(element:Element)
    {
        if let newVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
        {
            newVC.currentElement = element
            self.navigationController?.pushViewController(newVC, animated: true)
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
        if nightModeOn
        {
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar
//            self.navigationController?.navigationBar.backgroundColor = UIColor.blackColor()
//            self.navigationController?.navigationBar.barStyle = UIBarStyle.Black; //- See more at: http://motzcod.es/post/110755300272/ios-tip-change-status-bar-icon-text-colors#sthash.nnMUCkq5.dpuf
            
             self.tabBarController?.tabBar.tintColor = kWhiteColor
             self.tabBarController?.tabBar.backgroundColor = UIColor.blackColor()
        }
        else
        {
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
            self.navigationBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
//            self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
//            self.navigationController?.navigationBar.barStyle = UIBarStyle.Black; //- See more at: http://motzcod.es/post/110755300272/ios-tip-change-status-bar-icon-text-colors#sthash.nnMUCkq5.dpuf
            
            self.tabBarController?.tabBar.tintColor = kWhiteColor
            self.tabBarController?.tabBar.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.8)

        }
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()

        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
       
       
        
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
