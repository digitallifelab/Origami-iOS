//
//  UserProfileSexCell.swift
//  Origami
//
//  Created by CloudCraft on 01.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileSexCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel:UILabel?
    @IBOutlet weak var sexLabel:UILabel?
    var switcher:UISegmentedControl?
    
    var delegate:UserProfileCollectionCellDelegate?
    let cellType:ProfileTextCellType = .Sex

    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day:
                sexLabel?.textColor = kDayCellBackgroundColor

            case .Night:
                sexLabel?.textColor = kWhiteColor
            }
        }
    }
    
    @IBAction func editButtonTapped(sender:UIButton?)
    {
        delegate?.changeInfoPressed(cellType)
    }

    func enableSexSwitchControl(currentSex:NSNumber?)
    {
        let segmentedControl = UISegmentedControl(items: ["male".localizedWithComment(""), "female".localizedWithComment("")])
        let centerBounds = CGPointMake(floor(CGRectGetMidX(self.bounds)), floor(CGRectGetMidY(self.bounds)))
        segmentedControl.center = centerBounds
        segmentedControl.tintColor = kDayNavigationBarBackgroundColor
        segmentedControl.backgroundColor = kWhiteColor
        if let currentSexNumber = currentSex
        {
            segmentedControl.selectedSegmentIndex = currentSexNumber.integerValue
        }
        
        segmentedControl.addTarget(self, action: "segmentedControlChanged:", forControlEvents: .ValueChanged)
        self.switcher = segmentedControl
        self.addSubview(segmentedControl)
    }
    
    func segmentedControlChanged(sender:UISegmentedControl)
    {
        self.delegate?.changeSexSwitchPresed(sender.selectedSegmentIndex)
        self.disableSexSwitch()
    }
    
    func disableSexSwitch()
    {
        switcher?.removeFromSuperview()
        switcher = nil
    }
    
}
