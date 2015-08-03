//
//  CollectionViewCell.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementTitleCell: UICollectionViewCell {
    
    var displayMode:DisplayMode = .Day {
        didSet{
            switch self.displayMode{
            case .Day:
                self.backgroundColor = kDayCellBackgroundColor
                //avouriteButton.backgroundColor = kDaySignalColor
            case .Night:
                self.backgroundColor = UIColor.blackColor()
                //favouriteButton.backgroundColor = kNightSignalColor
            }
        }
    }
    
    var favourite:Bool = false {
        didSet{
            
            if favourite
            {
                favouriteButton.tintColor = UIColor.yellowColor()
            }
            else
            {
                favouriteButton.tintColor = kWhiteColor
            }
        }
    }
    
    
    
    @IBOutlet var labelTitle:UILabel!
    @IBOutlet var labelDate:UILabel!
    @IBOutlet var favouriteButton:UIButton!
    
    @IBAction func favoutireButtonTap(sender:UIButton)
    {
        var tapNotification = NSNotification(name: kElementFavouriteButtonTapped, object: self)

        NSNotificationCenter.defaultCenter().postNotification(tapNotification)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //apply shadow to fav button
//        let buttonBounds = favouriteButton.bounds
//        
//        let roundedLeftBottomPath = UIBezierPath(roundedRect: buttonBounds, byRoundingCorners: UIRectCorner.BottomRight | UIRectCorner.TopRight, cornerRadii: CGSizeMake(5, 5))
//        var shape = CAShapeLayer()
//        shape.frame = buttonBounds
//        shape.path = roundedLeftBottomPath.CGPath
//        favouriteButton.layer.mask = shape
        
        self.layer.masksToBounds = false
        //apply bottom rounded corners to us (CollectionViewCell)
        let selfBounds = self.bounds
        
        //apply shadow to us
    
        let shadowColor = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? UIColor.grayColor().CGColor : UIColor.blackColor().CGColor
        let shadowOpacity:Float = 0.5
        let shadowOffset = CGSizeMake(0.0, 5.0)
        let offsetShadowFrame = CGRectOffset(selfBounds, 0, shadowOffset.height)
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = 3.0
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadii: CGSizeMake(5.0, 5.0))
        self.layer.shadowPath = offsetPath.CGPath
        
        //self.layer.shouldRasterize = true
        self.layer.zPosition = 1000
    }
    
//    deinit
//    {
//        cleanShadow()
//    }
    
    
    func cleanShadow()
    {
        for aLayer in self.superview!.layer.sublayers
        {
            if let layer = aLayer as? CALayer
            {
                if layer.zPosition == 900
                {
                    layer.removeFromSuperlayer()
                    break
                }
            }
        }
    }
}
