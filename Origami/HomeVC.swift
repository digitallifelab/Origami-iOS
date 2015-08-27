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
 
    var shouldReloadCollection = false
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
        DataSource.sharedInstance.loadAllElementsInfo {[weak self] (success, failure) -> () in
            if let wSelf = self
            {
                if success
                {
                   // wSelf.reloadDashboardView()
                    
                    if let wSelf = self
                    {
                        //println(" \(wSelf) Loaded elements")
                        wSelf.loadingAllElementsInProgress = false
                        wSelf.shouldReloadCollection = true
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
                   // #if DEBUG
                    wSelf.showAlertWithTitle("Failed", message: " this is a non production error message. \n Did not load Elements for dashboard.", cancelButtonTitle: "Ok")
                    //#endif
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementWasDeleted:", name:kElementWasDeletedNotification , object: nil)
        
        configureRightBarButtonItem()
        configureLeftBarButtonItem()
        
        DataSource.sharedInstance.startRefreshingNewMessages()
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didTapOnChatMessage:", name: kHomeScreenMessageTappedNotification, object: nil)
        
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kHomeScreenMessageTappedNotification, object: nil)
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
        var leftButton = UIButton.buttonWithType(.Custom) as! UIButton
        leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
        leftButton.setImage(UIImage(named: "icon-options")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        leftButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        leftButton.tintColor = UIColor.whiteColor()
        
        var leftBarButton = UIBarButtonItem(customView: leftButton)
        
        //let menuButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: self, action: "menuButtonTapped:")
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func configureNavigationTitleView()
    {
        let titleImageView = UIImageView(image:UIImage(named: "title-home"))
        titleImageView.contentMode = .ScaleAspectFit
        titleImageView.frame = CGRectMake(0, 0, 200, 40)
        
        self.navigationItem.titleView = titleImageView
    }
    
    //MARK:-----
    func reloadDashboardView()
    {
        loadingAllElementsInProgress = true
            
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
                                
                                if aSelf.shouldReloadCollection
                                {
                                    hiddenLayout.privSignals = newSignalsCount
                                    
                                    hiddenLayout.privFavourites = newFavs
                                    
                                    hiddenLayout.privOther = newOther
                                    
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: newSignals, favourites: newFavs, other: newOther)
                                   
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    aSelf.collectionDashboard.reloadData()
                                    aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    aSelf.collectionDashboard.collectionViewLayout.invalidateLayout()
                                    aSelf.shouldReloadCollection = false
                                }
                                else
                                {
                                    println(" ->  hiddenLayout. Will not reload Home CollectionView.")
                                }
                            
                                
                                
                                //customLayout.invalidateLayout() // to recalculate position of home elements
                            }
                            else if let visibleLayout = aSelf.collectionDashboard?.collectionViewLayout as? HomeSignalsVisibleFlowLayout
                            {
                                if aSelf.shouldReloadCollection
                                {
                                    aSelf.collectionDashboard.collectionViewLayout.invalidateLayout()
                                    
                                    let newLayout = HomeSignalsHiddenFlowLayout(signals: newSignalsCount , favourites: newFavs, other: newOther)
                                    
                                    //                                aSelf.collectionDashboard?.performBatchUpdates({ () -> Void in
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: newSignals, favourites: newFavs, other: newOther)
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    aSelf.collectionDashboard.reloadData()
                                    aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    
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
                                    println(" -> visibleLayout. Will not reload Home CollectionView.")
                                }
                            }
                            else
                            {
                                println(" -> Hone VC. New Layout.")
                                let newLayout = HomeSignalsHiddenFlowLayout(signals: newSignalsCount , favourites: newFavs, other: newOther)
                                
                                aSelf.collectionDashboard?.performBatchUpdates({ () -> Void in
                                    
                                    aSelf.collectionSource = HomeCollectionHandler(signals: newSignals, favourites: newFavs, other: newOther)
                                    println(" -> did assign collection datasource")
                                    aSelf.collectionSource!.elementSelectionDelegate = aSelf
                                    
                                    aSelf.collectionDashboard!.dataSource = aSelf.collectionSource
                                    aSelf.collectionDashboard!.delegate = aSelf.collectionSource
                                    //aSelf.collectionDashboard.reloadData()
                                    aSelf.collectionDashboard.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: false)
                                    
                                    }, completion: { (finished) -> Void in
                                        //                                    if shouldReloadCollection
                                        //                                    {
                                        aSelf.collectionDashboard?.setCollectionViewLayout(newLayout, animated: false)
                                        //                                    }
                                })
                                
                            }
                            
                            aSelf.loadingAllElementsInProgress = false
                            aSelf.shouldReloadCollection = false
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
            customTransitionAnimator = FadeOpaqueAnimator()
            
            newElementCreator.composingDelegate = self
            newElementCreator.modalPresentationStyle = .Custom
            newElementCreator.transitioningDelegate = self
            
            
            self.presentViewController(newElementCreator, animated: true, completion: { () -> Void in
                newElementCreator.editingStyle = .AddNew
                
                if let tapView = self.view.viewWithTag(0xAD12)
                {
                    tapView.removeFromSuperview()
                }
            })
        }
    }
    
    func showAddTheVeryFirstElementPlus()
    {
        var tapView = UIView(frame: CGRectMake(0, 0, 200.0, 200.0))
        tapView.userInteractionEnabled = true
        tapView.backgroundColor = UIColor.whiteColor()
        tapView.opaque = true
        tapView.tag = 0xAD12
        
        var imageView = UIImageView(frame: CGRectMake(50.0, 50.0, 100.0, 100.0))
        imageView.contentMode = .ScaleAspectFit
        imageView.image = UIImage(named: "icon-add")
        imageView.tintColor = kDayNavigationBarBackgroundColor
        imageView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        tapView.addSubview(imageView)
        
        var tapButton = UIButton.buttonWithType(.Custom) as! UIButton
        tapButton.frame = tapView.bounds
        tapButton.addTarget(self, action: "showElementCreationVC:", forControlEvents: UIControlEvents.TouchUpInside)
        tapButton.backgroundColor = UIColor.clearColor()
        tapButton.opaque = true
        tapButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        //tapButton.layer.borderWidth = 1.0
        
        tapView.addSubview(tapButton)
        
        tapView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
        
        self.view.addSubview(tapView)
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
        presentNewSingleElementVC(element)
    }
    
    func presentNewSingleElementVC(element:Element)
    {
        let rootId = element.rootElementId.integerValue

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
        var passWhomIDs:Set<Int>?
         let nsNumberArray = element.passWhomIDs
        if !nsNumberArray.isEmpty
        {
            passWhomIDs = Set<Int>()
            for number in nsNumberArray
            {
                passWhomIDs!.insert(number.integerValue)
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
        if let note = notification, userInfo = note.userInfo, elementId = userInfo["elementId"] as? NSNumber
        {
            if let currentDataSource = self.collectionSource, foundIndexPaths = currentDataSource.indexpathForElementById(elementId.integerValue, shouldDelete:true)
            {
                self.collectionDashboard.reloadData()
                
                self.reloadDashboardView()
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
    
//    //MARK: Alert
//    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
//    {
//        let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
//        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
//        alertController.addAction(closeAction)
//        
//        self.presentViewController(alertController, animated: true, completion: nil)
//    }
    
    
    
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
                    case 2:
                        aSelf.showContactsVC()
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
      
        
        if nightModeOn
        {
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar

            //self.tabBarController?.tabBar.tintColor = kWhiteColor
            self.tabBarController?.tabBar.backgroundColor = UIColor.blackColor()
        }
        else
        {
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
            self.navigationBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
            UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
            
            self.tabBarController?.tabBar.backgroundColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(1.0)

            //self.tabBarController?.tabBar.tintColor = kDayCellBackgroundColor
        }
        
        self.collectionSource?.turnNightModeOn(nightModeOn)
        self.collectionDashboard.reloadData()
        
    }
    
    func didTapOnChatMessage(notification:NSNotification?)
    {
        // 1 - instantiate SinglElementDashboardVC
        // 2 - instantiate ChatVC
        // 3 - set viewControllers for self.navigationController
        if let tappedMessage = notification?.object as? Message
        {
            if let targetElement = DataSource.sharedInstance.getElementById(tappedMessage.elementId!.integerValue)
            {
                if let
                    singleElementVC = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC,
                    chatVC = self.storyboard?.instantiateViewControllerWithIdentifier("ChatVC") as? ChatVC
                {
                    singleElementVC.currentElement = targetElement
                    chatVC.currentElement = targetElement
                    
                    var toShowVCs = [UIViewController]()
                    if let viewControllers = self.navigationController?.viewControllers as? [UIViewController]
                    {
                        toShowVCs += viewControllers
                    }
                    
                    toShowVCs.append(singleElementVC)
                    toShowVCs.append(chatVC)
                    
                    self.navigationController?.setViewControllers(toShowVCs, animated: true)
                }
            }
        }
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
            let profileNavHolder = UINavigationController(rootViewController: userProfileVC)
            
            profileNavHolder.modalPresentationStyle = .Custom
            profileNavHolder.transitioningDelegate = self
            
            customTransitionAnimator = FadeOpaqueAnimator()
            
            self.presentViewController(profileNavHolder, animated: true, completion: nil)
        }
    }
    
    func showContactsVC()
    {
        if let contactsVC = self.storyboard?.instantiateViewControllerWithIdentifier("MyContactsListVC") as? MyContactsListVC
        {
            let contactsNavHolderVC = UINavigationController(rootViewController: contactsVC)
            
            contactsNavHolderVC.modalPresentationStyle = .Custom
            contactsNavHolderVC.transitioningDelegate = self
            
            customTransitionAnimator = FadeOpaqueAnimator()
            
            self.presentViewController(contactsNavHolderVC, animated: true, completion: nil)
        }
    }
    
}
