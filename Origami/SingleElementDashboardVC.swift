//
//  SingleElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDashboardVC: UIViewController {

    var currentElement:Element?
    var collectionDataSource:SingleElementCollectionViewDataSource?
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
        
        setAppearanceForNightModeToggled(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
        
        collectionDataSource = SingleElementCollectionViewDataSource(element: currentElement) // both can be nil
        collectionDataSource!.handledElement = currentElement
        collectionDataSource!.displayMode = self.displayMode
        if collectionDataSource != nil
        {
            collectionView.dataSource = collectionDataSource!
        }
        
        if let layout = prepareCollectionLayoutForElement(currentElement)
        {
            collectionView.setCollectionViewLayout(layout, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementFavouriteToggled:", name: kElementFavouriteButtonTapped, object: nil)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
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

    
    
    //MARK: Handling buttons and other elements tap in collection view
    func elementFavouriteToggled(notification:NSNotification)
    {
        if let element = currentElement,  favourite = element.isFavourite
        {
            var isFavourite = !favourite.boolValue
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
                        weakSelf.currentElement!.isFavourite = NSNumber(bool: isFavourite)
                        titleCell?.favourite = isFavourite
                    }
                }
            }
            
        }
    }
    
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


}
