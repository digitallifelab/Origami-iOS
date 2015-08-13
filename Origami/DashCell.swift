//
//  DashCellFavourite.swift
//  Origami
//
//  Created by CloudCraft on 05.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit


class DashCell: UICollectionViewCell
{
    var backColor:UIColor
        {
        didSet{
            self.backgroundColor = backColor
        }
    }
    var titleColor:UIColor {
        didSet{
            titleLabel?.textColor = titleColor
        }
    }
    var descriptionColor:UIColor {
        didSet{
            descriptionLabel?.textColor = descriptionColor
        }
    }
    
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var descriptionLabel:UILabel!
    @IBOutlet var signalsCountLabel:UILabel!
    @IBOutlet var flagIcon:UIImageView!
    @IBOutlet var dividerView:UIView? = nil
    @IBOutlet var signalDetectorView:UIView? = nil
    
    required init(coder aDecoder: NSCoder) {
        
        backColor = kDayCellBackgroundColor//UIColor.clearColor()
        titleColor = UIColor.blackColor()
        descriptionColor = UIColor.grayColor()
        
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        backColor = UIColor.clearColor()
        titleColor = UIColor.blackColor()
        descriptionColor = UIColor.grayColor()
        super.init(frame: frame)
    }
    
    var displayMode:DisplayMode = .Day
    {
        didSet
        {
            switch displayMode
            {
                case DisplayMode.Day:
                    switch cellType
                    {
                        case .SignalsToggleButton:
                            fallthrough
                        case .Signal:
                            backColor = kDaySignalColor
                            descriptionColor = kWhiteColor
                        
                        case .Other:
                            titleColor = kWhiteColor
                            descriptionColor = UIColor.grayColor()
                        
                        case .Messages:
                            backColor = UIColor.whiteColor()
                        
                        
                    }
                
                case DisplayMode.Night:
                    switch cellType
                    {
                        case .SignalsToggleButton:
                            fallthrough
                        case .Signal:
                            backColor = kNightSignalColor
                            descriptionColor = kWhiteColor
                        case .Other :
                            backColor = UIColor.clearColor()
                            titleColor = kWhiteColor
                            descriptionColor = kWhiteColor.colorWithAlphaComponent(0.6)
                        case .Messages:
                            backColor = UIColor.clearColor()
                        
                    }
            }
            updateAppearance()
        }
    }
    var cellType:DashCellType = .Other
    {
        didSet{
            
            switch cellType
            {
                case .SignalsToggleButton:
                    flagIcon.image = UIImage(named: "icon-flag")
                    titleColor = UIColor.whiteColor()
                    backColor = (self.displayMode == .Day) ? kDaySignalColor : kNightSignalColor
                    signalDetectorView?.hidden = true
                
                case .Signal:
                    titleColor = UIColor.whiteColor()//(self.displayMode == .Day) ? UIColor.blackColor() : UIColor.whiteColor()
                    descriptionColor = UIColor.whiteColor()
                    backColor =  (self.displayMode == .Day) ? kDaySignalColor : kNightSignalColor
                    flagIcon?.image = nil
                    signalsCountLabel?.text = nil
                    signalDetectorView?.hidden = true
                
                case .Other :
                    titleColor = kWhiteColor //(self.displayMode == .Day) ? UIColor.blackColor() : UIColor.whiteColor()
                    descriptionColor = kWhiteColor.colorWithAlphaComponent(0.6) // (self.displayMode == .Day) ? UIColor.grayColor() : UIColor(white: 0.5, alpha: 1.0)
                    flagIcon?.image = nil
                    signalsCountLabel?.text = nil
                    backColor = (self.displayMode == .Day) ? kDayCellBackgroundColor : UIColor.clearColor()
                
                
            default: break
            }
            
            updateAppearance()
        }
    }
    
    override func  awakeFromNib()
    {
        backgroundColor = backColor
        titleLabel.textColor = titleColor
        descriptionLabel.textColor = descriptionColor
        self.layer.cornerRadius = 5.0
    }
    
    override func prepareForReuse()
    {
        self.flagIcon?.image = nil
        self.signalsCountLabel?.text = nil
        
        updateAppearance()
    }
    
    func updateAppearance()
    {
        self.backgroundColor = backColor
        titleLabel.textColor = titleColor
        descriptionLabel.textColor = descriptionColor
        dividerView?.backgroundColor = titleColor
        signalDetectorView?.backgroundColor = (self.displayMode == .Day) ? kDaySignalColor : kNightSignalColor
        
        if cellType == .SignalsToggleButton
        {
            titleLabel.hidden = true
            descriptionLabel.hidden = true
            dividerView?.hidden = true
        }
        else
        {
            titleLabel.hidden = false
            descriptionLabel.hidden = false
            dividerView?.hidden = false
        }
    }
}






