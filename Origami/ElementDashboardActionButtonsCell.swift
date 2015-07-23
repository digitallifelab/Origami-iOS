//
//  ElementDashboardActionButtonsCell.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementDashboardActionButtonsCell: UITableViewCell //cell contains action buttons for current displayed ELEMENT - set element signal, set element favourite, archive element, and other
{

    var actionButtonDelegate:ButtonTapDelegate?
//    private var backgroundColors:[Int:UIColor] = [Int:UIColor]()
    var elementIsOwned = false
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func actionButtonTapped(sender:UIButton)
    {
       actionButtonDelegate?.didTapOnButton(sender)
    }

    override func layoutSubviews() {
        // display borders for text containing buttons
        if let buttonsHolderView = self.contentView.viewWithTag(101)
        {
            var firstFourButtons = [UIButton]()
            for lvButton in buttonsHolderView.subviews
            {
                if let button = lvButton as? UIButton
                {
                    lvButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
                    
                    if !elementIsOwned
                    {
                        let lvCurrentTag = lvButton.tag
                        if lvCurrentTag == 1 || lvCurrentTag >= 3
                        {
                            (lvButton as! UIButton).enabled = false
                        }
                    }
                    else
                    {
                        (lvButton as! UIButton).enabled = true
                    }
                    
                    if firstFourButtons.count < 4
                    {
                        if lvButton.tag > 0 && lvButton.tag < 5
                        {
                            firstFourButtons.append(lvButton as! UIButton)
                        }
                    }
                    else
                    {
                        break
                    }
                }
            }
            
            for button in firstFourButtons
            {
                button.layer.borderColor = UIColor.lightGrayColor().CGColor
                button.layer.borderWidth = 2.0
            }
        }
    }
    
    var signalButton:UIButton? {
        get{
            if let toReturnButton = self.viewWithTag(101)?.viewWithTag(ActionButtonType.ToggleSignal.rawValue) as? UIButton
            {
                return toReturnButton
            }
            return nil
        }
    }
//    
//    func setBackgroundColor(color:UIColor, forButtonTag tag:Int)
//    {
//        backgroundColors[tag] = color
//    }
    
//    func configureButtonsAppearance()
//    {
//        let subviewsCount = self.contentView.subviews.count
//        if subviewsCount > 0
//        {
//            var firstFourButtons = [UIButton]()
//            for lvButton in self.contentView.subviews
//            {
//                if let button = lvButton as? UIButton
//                {
//                    if firstFourButtons.count < 4
//                    {
//                        firstFourButtons.append(lvButton as! UIButton)
//                    }
//                    else
//                    {
//                        break
//                    }
//                }
//            }
//            
//            for button in firstFourButtons
//            {
//                button.layer.borderColor = UIColor.grayColor().CGColor
//                button.layer.borderWidth = 1.0
//            }
//        }
//    }
}
