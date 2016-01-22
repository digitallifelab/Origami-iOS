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

    @IBOutlet weak var switcher:UISegmentedControl?
    
    weak var delegate:UserProfileCollectionCellDelegate?
    let cellType:ProfileTextCellType = .Sex

    
    var currentGender:Int = 0
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day:
                switcher?.tintColor = kDayCellBackgroundColor

            case .Night:
                switcher?.tintColor = kWhiteColor
            }
        }
    }
    var editingEnabled = false {
        didSet {
            if editingEnabled
            {
                enableSexSwitchControl(NSNumber(integer:currentGender))
            }
            else
            {
                disableSexSwitch()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        switcher?.setTitle("male".localizedWithComment(""), forSegmentAtIndex: 0)
        switcher?.setTitle("female".localizedWithComment(""), forSegmentAtIndex: 1)
    }
    
    @IBAction func editButtonTapped(sender:UIButton?)
    {
        delegate?.changeInfoPressed(cellType)
    }

    func enableSexSwitchControl(currentSex:NSNumber?)
    {
        if let currentSexNumber = currentSex
        {
            switcher?.selectedSegmentIndex = currentSexNumber.integerValue
        }
        
        switcher?.addTarget(self, action: "segmentedControlChanged:", forControlEvents: .ValueChanged)
        switcher?.enabled = true
    }
    
    func segmentedControlChanged(sender:UISegmentedControl)
    {
        self.delegate?.changeSexSwitchPresed(sender.selectedSegmentIndex)
        self.disableSexSwitch()
    }
    
    func disableSexSwitch()
    {
        switcher?.removeTarget(self, action: "segmentedControlChanged:", forControlEvents: .ValueChanged)
        switcher?.enabled = false
    }
    
}
