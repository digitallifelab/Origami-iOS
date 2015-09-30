//
//  DashHeaderView.swift
//  Origami
//
//  Created by CloudCraft on 10.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit
class DashHeaderView : UICollectionReusableView
{
    @IBOutlet var label:UILabel!
    
    var displayMode:DisplayMode = .Day {
        didSet {
            switch displayMode{
            case .Day:
                label.textColor = kDayCellBackgroundColor//UIColor.blackColor()
            case .Night:
                label.textColor = UIColor.whiteColor()
            }
        }
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        label = UILabel()
        //label.setTranslatesAutoresizingMaskIntoConstraints(false)
        label.numberOfLines = 1
        self.addSubview(label)
        configureLabel()
    }
    private func configureLabel()
    {
        let subViews = ["_label" : label]
        let horizontalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[_label]", options:.AlignAllLeft, metrics:nil, views:subViews /*as [NSObject:AnyObject]*/)
        
        addConstraints(horizontalConstraint)
        let verticalCenterConstraint = NSLayoutConstraint(item: label,
            attribute: .CenterY,
            relatedBy: .Equal,
            toItem: self,
            attribute: .CenterY,
            multiplier: 1.0, constant: 0.0)
        addConstraint(verticalCenterConstraint)
        
        label.font = UIFont(name: "SegoeUI-Semibold", size: 19.0)
        //self.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.6)
    }
    func displayDividerLine(display:Bool)
    {
        if display
        {
            let dividerView:UIView = UIView()
            //dividerView.setTranslatesAutoresizingMaskIntoConstraints(false)
            dividerView.tag = 0xADF
            dividerView.backgroundColor = UIColor.lightGrayColor()
            
            self.addSubview(dividerView)
            addConstraintsToDividerView(dividerView)
        }
        else
        {
            self.viewWithTag(0xADF)?.removeFromSuperview()
        }
    }
    
    private func addConstraintsToDividerView(view:UIView)
    {
        let heightConstraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1.0,
            constant: 2.0) //2 px height
        
        
//        let verticalCenter = NSLayoutConstraint(
//            item: view,
//            attribute: NSLayoutAttribute.CenterY,
//            relatedBy: NSLayoutRelation.Equal,
//            toItem: label,
//            attribute: NSLayoutAttribute.CenterY,
//            multiplier: 1.0,
//            constant: 0.0) //equal vertical centers with label
        let bottomConstraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1.0, constant: 1.0)
        
        let leadingConstraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.Left,
            relatedBy: NSLayoutRelation.Equal,
            toItem:  label,
            attribute: NSLayoutAttribute.Left,
            multiplier: 1.0, constant: 5.0)
        
        let trailingConatraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.Trailing,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self, attribute:
            NSLayoutAttribute.Trailing,
            multiplier: 1.0, constant: 5.0)
        
        
        self.addConstraints([leadingConstraint, trailingConatraint])
        self.addConstraint(heightConstraint)
        //self.addConstraint(verticalCenter)
        self.addConstraint(bottomConstraint)
        
    }
    
}