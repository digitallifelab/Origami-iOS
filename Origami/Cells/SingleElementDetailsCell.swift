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
            switch self.displayMode
            {
            case .Day:
                self.textLabel.textColor = UIColor.blackColor()
                self.moreLessButton.tintColor = kDayCellBackgroundColor
                self.backgroundColor = UIColor.whiteColor()
            case .Night:
                self.textLabel.textColor = UIColor.grayColor()
                self.moreLessButton.tintColor = kWhiteColor
                self.backgroundColor = UIColor.blackColor()
            }
        }
    }
    
    @IBOutlet var textLabel:UILabel!
    @IBOutlet var moreLessButton:UIButton!
    @IBAction func moreLessButtonTap(sender:UIButton)
    {
        // send event to upper views - need to recalculate self`s dimensions in collectionViewLayout subclass
        NSNotificationCenter.defaultCenter().postNotificationName(kElementMoreDetailsNotification, object: nil)
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
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: [UIRectCorner.BottomLeft , UIRectCorner.BottomRight], cornerRadii: CGSizeMake(5.0, 5.0))
        self.layer.shadowPath = offsetPath.CGPath
        
        if selfBounds.size.height < 120
        {
            self.moreLessButton.hidden = true
        }
        else if selfBounds.size.height > 120
        {
            self.moreLessButton.hidden = false
            self.moreLessButton.setTitle("Less".localizedWithComment(""), forState: .Normal)
        }
        else if lround(Double(selfBounds.size.height)) == 120
        {
            self.moreLessButton.hidden = false
            self.moreLessButton.setTitle("More".localizedWithComment(""), forState: .Normal)
        }
    }
    

}