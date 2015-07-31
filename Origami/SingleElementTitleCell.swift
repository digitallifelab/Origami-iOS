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
                favouriteButton.backgroundColor = kDaySignalColor
            case .Night:
                self.backgroundColor = UIColor.clearColor()
                favouriteButton.backgroundColor = kNightSignalColor
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
        
        let bounds = favouriteButton.bounds
        let roundedLeftBottomPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: UIRectCorner.BottomRight | UIRectCorner.TopRight, cornerRadii: CGSizeMake(5, 5))
        
        var shape = CAShapeLayer()
        shape.frame = bounds
        shape.path = roundedLeftBottomPath.CGPath
        
        favouriteButton.layer.mask = shape
        
        self.layer.shadowOpacity = 0.7
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowRadius = 3.0
        self.layer.shadowOffset = CGSizeMake(0, 3)
        self.layer.zPosition = 1000
        self.layer.masksToBounds = false
    }
    
}
