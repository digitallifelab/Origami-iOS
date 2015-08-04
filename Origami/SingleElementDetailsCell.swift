//
//  SingleElementDetailsCell.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDetailsCell: UICollectionViewCell {
    
    var displayMode:DisplayMode = .Day{
        didSet{
            let old = oldValue
            if displayMode == old
            {
                return
            }
            switch self.displayMode
            {
            case .Day:
                self.textLabel.textColor = UIColor.blackColor()
                self.moreLessButton.tintColor = kDaySignalColor
                self.backgroundColor = UIColor.whiteColor()
            case .Night:
                self.textLabel.textColor = UIColor.grayColor()
                self.moreLessButton.tintColor = kNightSignalColor
                self.backgroundColor = UIColor.blackColor()
            }
        }
    }
    
    @IBOutlet var textLabel:UILabel!
    @IBOutlet var moreLessButton:UIButton!
    //var labelTapRecognizer:UITapGestureRecognizer?
    
    
    @IBAction func moreLeccButtonTap(sender:UIButton)
    {
        // send event to upper views - need to recalculate self`s dimensions in collectionViewLayout subclass
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        //apply shadow to us
        self.layer.masksToBounds = false
        let selfBounds = self.bounds
        
        let shadowColor = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? UIColor.grayColor().CGColor : UIColor.blackColor().CGColor
        let shadowOpacity:Float = 0.5
        let shadowOffset = CGSizeMake(0.0, 3.0)
        let offsetShadowFrame = CGRectOffset(selfBounds, 0, shadowOffset.height)
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = 3.0
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadii: CGSizeMake(5.0, 5.0))
        self.layer.shadowPath = offsetPath.CGPath
    }
    

}
