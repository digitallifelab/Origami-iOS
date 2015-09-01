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
                //buttonTrueColor = UIColor.whiteColor()
            case .Night:
                self.backgroundColor = UIColor.blackColor()
                //buttonTrueColor = UIColor.whiteColor()
            }
        }
    }
    
    var favourite:Bool = false {
        didSet{
            
            if favourite
            {
                favouriteButton.tintColor = buttonTrueColor
                favouriteButton.backgroundColor = (displayMode == .Day) ? kDaySignalColor : kNightSignalColor
            }
            else
            {
                favouriteButton.tintColor = (displayMode == .Day) ? kDayCellBackgroundColor : UIColor.blackColor()//buttonFalseColor
                favouriteButton.backgroundColor = buttonFalseColor
            }
        }
    }
    var optionsConverter = ElementOptionsConverter()
    
    weak var handledElement:Element?
    var buttonTrueColor = UIColor.whiteColor()
    var buttonFalseColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
    
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
         //self.updateConstraints()
        //apply shadow to fav button
        let buttonBounds = favouriteButton.bounds
        
        let roundedLeftBottomPath = UIBezierPath(roundedRect: buttonBounds, byRoundingCorners: UIRectCorner.BottomRight | UIRectCorner.TopRight, cornerRadii: CGSizeMake(5, 5))
        var shape = CAShapeLayer()
        shape.frame = buttonBounds
        shape.path = roundedLeftBottomPath.CGPath
        favouriteButton.layer.mask = shape
        
        self.layer.masksToBounds = false
        //apply bottom rounded corners to us (CollectionViewCell)
        let selfBounds = self.bounds
        
        //apply shadow to us
    
        let shadowColor = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? UIColor.grayColor().CGColor : UIColor.blackColor().CGColor
        let shadowOpacity:Float = 0.5
        let shadowOffset = CGSizeMake(0.0, 3.0)
        let offsetShadowFrame = CGRectOffset(selfBounds, 0, shadowOffset.height)
        self.layer.shadowColor = shadowColor
        self.layer.shadowOpacity = shadowOpacity
        self.layer.shadowRadius = 3.0
        let offsetPath = UIBezierPath(roundedRect: offsetShadowFrame, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight, cornerRadii: CGSizeMake(5.0, 5.0))
        self.layer.shadowPath = offsetPath.CGPath
        
       
        //super.layoutSubviews()
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
    
    
    func setupActionButtons(active:Bool)
    {
        //buttonFalseColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)

        colorizeButtons()
        
        if active
        {
            addActionToButtons()
        }
    }
    
    //MARK: element is owned
    func addActionToButtons()
    {
        for var i = 0; i < 8; i++
        {
            if let buttonSubView = self.viewWithTag(i) as? UIButton
            {
                buttonSubView.addTarget(self, action: "actionButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)
            }
        }
    }
    
    func colorizeButtons()
    {
        for var i = 0; i < 8; i++
        {
            if let buttonSubView = self.viewWithTag(i) as? UIButton
            {
                if buttonSubView.hidden
                {
                    buttonSubView.hidden = false
                }
                buttonSubView.layer.cornerRadius = 20.0
                buttonSubView.tintColor = kWhiteColor
            }
        }
        
        setupSignalButton()
        setupIdeaButton()
        setupCheckMarkButton()
        setupDecisionButton()
    }
    
    private func setupSignalButton()
    {
        if let currentElement = self.handledElement, signalButton = self.viewWithTag(ActionButtonCellType.Signal.rawValue) as? UIButton
        {
            signalButton.setImage((UIImage(named: "icon-flag")?.imageWithRenderingMode(.AlwaysTemplate)), forState: .Normal)
            signalButton.backgroundColor = (currentElement.isSignal.boolValue) ? kDaySignalColor : UIColor.clearColor()
        }
    }
    private func setupIdeaButton()
    {
        if let currentElement = self.handledElement, ideaButton = self.viewWithTag(ActionButtonCellType.Idea.rawValue)
        {
            let enabled = (optionsConverter.isOptionEnabled(ElementOptions.Idea, forCurrentOptions: currentElement.typeId.integerValue))
            if enabled
            {
                ideaButton.backgroundColor = kDaySignalColor
            }
            else
            {
                ideaButton.backgroundColor = UIColor.clearColor()
            }
            
        }
    
    }
    private func setupCheckMarkButton()
    {
        if let currentElement = self.handledElement, checkmarkButton = self.viewWithTag(ActionButtonCellType.CheckMark.rawValue)
        {
            if (optionsConverter.isOptionEnabled(ElementOptions.Done, forCurrentOptions: currentElement.typeId.integerValue))
            {
                checkmarkButton.backgroundColor = kDaySignalColor
            }
            else
            {
                checkmarkButton.backgroundColor = UIColor.clearColor()
            }
        }
    }
    private func setupDecisionButton()
    {
        if let currentElement = self.handledElement, decisionButton = self.viewWithTag(ActionButtonCellType.Solution.rawValue)
        {
            if (optionsConverter.isOptionEnabled(ElementOptions.Decision, forCurrentOptions: currentElement.typeId.integerValue))
            {
                decisionButton.backgroundColor = kDaySignalColor
            }
            else
            {
                decisionButton.backgroundColor = UIColor.clearColor()
            }
        }
    }
    func actionButtonTapped(sender:AnyObject?)
    {
        if let button = sender as? UIButton
        {
            var theTag = button.tag
            if theTag > 7
            {
                theTag = 0
            }
            NSNotificationCenter.defaultCenter().postNotificationName(kElementActionButtonPressedNotification, object: self, userInfo: ["actionButtonIndex" : theTag])
        }
    }
    
    //MARK: element is not owned
//    private func hideActionButtons()
//    {
//        for var i = 0; i < 8; i++
//        {
//            if let buttonSubView = self.viewWithTag(i) as? UIButton
//            {
//                buttonSubView.hidden = true
//            }
//        }
//    }
}
