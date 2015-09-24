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
    
    //@IBOutlet var labelTitle:UILabel!
    @IBOutlet var labelDate:UILabel!
    @IBOutlet var favouriteButton:UIButton!
    @IBOutlet var titleTextView:UITextView!
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
        
        titleTextView.font = UIFont(name: "SegoeUI", size: 30.0)
        titleTextView.textColor = kWhiteColor
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
        colorizeButtons()
        
        if active
        {
            addActionToButtons()
        }
        else
        {
            if let taskButton = self.viewWithTag(5) as? UIButton
            {
                taskButton.addTarget(self, action: "actionButtonTapped:", forControlEvents: .TouchUpInside)
            }
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
        setup_TASK_Button()
        setupDecisionButton()
    }
    
    private func setupSignalButton()
    {
        if let currentElement = self.handledElement, signalButton = self.viewWithTag(ActionButtonCellType.Signal.rawValue) as? UIButton
        {
            signalButton.setImage((UIImage(named: "icon-flag")?.imageWithRenderingMode(.AlwaysTemplate)), forState: .Normal)
            signalButton.tintColor = (currentElement.isSignal.boolValue) ? kDaySignalColor : kWhiteColor
        }
    }
    
    private func setupIdeaButton()
    {
        if let currentElement = self.handledElement, ideaButton = self.viewWithTag(ActionButtonCellType.Idea.rawValue)
        {
            if (optionsConverter.isOptionEnabled(ElementOptions.Idea, forCurrentOptions: currentElement.typeId.integerValue))
            {
                if currentElement.isArchived() {
                    ideaButton.tintColor = UIColor.lightGrayColor()
                }
                else {
                    if currentElement.isOwnedByCurrentUser()
                    {
                        ideaButton.tintColor = kDaySignalColor
                    }
                    else
                    {
                        ideaButton.tintColor = kWhiteColor
                    }
                }
            }
            else
            {
                if currentElement.isOwnedByCurrentUser()
                {
                    ideaButton.tintColor = kWhiteColor
                    if currentElement.isArchived()
                    {
                        ideaButton.tintColor = UIColor.lightGrayColor()
                    }
                }
                else
                {
                    ideaButton.hidden = true
                }
            }
        }
    
    }
    
    private func setup_TASK_Button() //task
    {
        if let currentElement = self.handledElement, taskButton = self.viewWithTag(ActionButtonCellType.CheckMark.rawValue) as? UIButton
        {
            if currentElement.isOwnedByCurrentUser()
            {
                if (optionsConverter.isOptionEnabled(ElementOptions.Task, forCurrentOptions: currentElement.typeId.integerValue))
                {
                    if !currentElement.isArchived()
                    {
                        taskButton.tintColor = kWhiteColor
                        if let finishState = ElementFinishState(rawValue: currentElement.finishState.integerValue)
                        {
                            switch finishState
                            {
                            case .Default:
                                taskButton.setImage(UIImage(named: "task-available-to-set")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            case .InProcess:
                                taskButton.setImage(UIImage(named: "task-in-process")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            case .FinishedGood:
                                taskButton.setImage(UIImage(named: "task-finished-good")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            case .FinishedBad:
                                taskButton.setImage(UIImage(named: "task-finished-bad")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            }
                        }
                    }
                    else
                    {
                        taskButton.tintColor = UIColor.lightGrayColor()
                        if let finishState = ElementFinishState(rawValue: currentElement.finishState.integerValue)
                        {
                            switch finishState
                            {
                            case .Default:
                                taskButton.setImage(UIImage(named: "task-available-to-set")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            case .InProcess:
                                taskButton.setImage(UIImage(named: "task-in-process")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            case .FinishedGood:
                                taskButton.setImage(UIImage(named: "task-finished-good")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            case .FinishedBad:
                                taskButton.setImage(UIImage(named: "task-finished-bad")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                            }
                        }
                    }
                }
                else
                {
                    if !currentElement.isArchived()
                    {
                        taskButton.tintColor = kWhiteColor
                    }
                    else
                    {
                        taskButton.tintColor = UIColor.lightGrayColor()
                    }
                    taskButton.setImage(UIImage(named: "task-available-to-set")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                }
            }
            else if currentElement.isTaskForCurrentUser()
            {
                if (optionsConverter.isOptionEnabled(ElementOptions.Task, forCurrentOptions: currentElement.typeId.integerValue))
                {
                    if let finishState = ElementFinishState(rawValue: currentElement.finishState.integerValue)
                    {
                        switch finishState
                        {
                        case .Default:
                            taskButton.hidden = true
                        case .InProcess:
                            taskButton.tintColor = kDaySignalColor
                            taskButton.setImage(UIImage(named: "task-in-process")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                        case .FinishedGood:
                            taskButton.tintColor = kWhiteColor
                            taskButton.setImage(UIImage(named: "task-finished-good")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                        case .FinishedBad:
                            taskButton.tintColor = kWhiteColor
                            taskButton.setImage(UIImage(named: "task-finished-bad")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
                        }
                    }
                }
                else
                {
                    taskButton.hidden = true
                }
            }
            else
            {
                taskButton.hidden = true
            }
            
        }
    }
    
    private func setupDecisionButton()
    {
        if let currentElement = self.handledElement, decisionButton = self.viewWithTag(ActionButtonCellType.Solution.rawValue)
        {
            if (optionsConverter.isOptionEnabled(ElementOptions.Decision, forCurrentOptions: currentElement.typeId.integerValue))
            {
                if currentElement.isOwnedByCurrentUser()
                {
                    decisionButton.tintColor = kDaySignalColor
                }
                else
                {
                    decisionButton.tintColor = kWhiteColor
                }
            }
            else
            {
                if currentElement.isOwnedByCurrentUser()
                {
                    decisionButton.tintColor = kWhiteColor
                    if currentElement.isArchived()
                    {
                        decisionButton.tintColor = UIColor.lightGrayColor()
                    }
                }
                else
                {
                    decisionButton.hidden = true
                }
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
