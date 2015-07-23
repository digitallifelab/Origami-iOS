//
//  HomeNavigationController.swift
//  Origami
//
//  Created by CloudCraft on 16.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//



/*
        NOTE!

This subclass is created mostly to handle custom appearance ob tabbar controller`s button.

According to design it should be at the right instead of center

AnyWay tapping on tabbar at the center still has effect of returning to Home Screen, also as tapping on "Home" image

*/
import UIKit

class HomeNavigationController: UINavigationController {

//    var previousTrait:UITraitCollection?
//    var shouldRepositionTabBarItem = false
//    
    override func viewDidLoad() {
        super.viewDidLoad()
       // configureTabbarButtonItem(nil)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated:Bool)
    {
        super.viewWillAppear(animated)
        //if let tabbarController = self.tabBarController
        //{
           // configureTabbarButtonItem(nil)
            
        //    tabbarController.tabBar.layoutSubviews()
            
        //}
//        previousTrait = FrameCounter.getCurrentTraitCollection()
    }
//
    func configureTabbarButtonItem(newSize:CGSize?)
    {
        
//        var bounds = self.tabBarController!.tabBar.bounds
//        
//        if let saidSize = newSize
//        {
//            bounds.size = saidSize
//        }
//        
//        let width = CGRectGetWidth(bounds)
//        
//        let right = CGRectGetMaxX(bounds)
//        
//        let center = CGRectGetMidX(bounds)
//        
//        let threeQuarter = width / 4 * 3
//        let offset = threeQuarter - center
        
//        var checkCurrentItem = self.tabBarItem
//        var currentInset = checkCurrentItem.imageInsets
//        if currentInset.left < 0
//        {
//            return
//        }
//        checkCurrentItem.imageInsets = UIEdgeInsetsMake(-5, -5, -5, -5)
        //checkCurrentItem.setTitlePositionAdjustment(UIOffsetMake(/*offset*/0, 50.0)) //moving title down and to the right also image is moving right
    }
//
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//        if FrameCounter.getCurrentTraitCollection().userInterfaceIdiom == .Pad
//        {
//            shouldRepositionTabBarItem = true
//            configureTabbarButtonItem(size)
//            self.tabBarController?.tabBar.layoutSubviews()
//            
//            shouldRepositionTabBarItem = false
//        }
//    }
//    
//    override func viewDidLayoutSubviews() {
//        
//          previousTrait = FrameCounter.getCurrentTraitCollection()
//    }
//    
//    
//    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
//    {
//        if let prevTraitCollection = previousTrait
//        {
//            if newCollection.userInterfaceIdiom == .Phone
//            {
//                println("previous size class: \(prevTraitCollection.horizontalSizeClass.rawValue)")
//                println("new size class: \(newCollection.horizontalSizeClass.rawValue)")
//                
//                if prevTraitCollection.horizontalSizeClass != newCollection.horizontalSizeClass //deal iphone "6 plus"
//                {
//                    shouldRepositionTabBarItem = true
//                }
//                else if prevTraitCollection.horizontalSizeClass == .Compact && newCollection.horizontalSizeClass == .Compact //deal iphone "4","5","6"
//                {
//                    shouldRepositionTabBarItem = true
//                }
//                else
//                {
//                    shouldRepositionTabBarItem = false
//                }
//            }
//        }
//    }
//    
//    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
//        if shouldRepositionTabBarItem
//        {
//            configureTabbarButtonItem(nil)
//            self.tabBarController?.tabBar.layoutSubviews()
//            previousTrait = FrameCounter.getCurrentTraitCollection()
//            shouldRepositionTabBarItem = false
//        }
//    }
}
