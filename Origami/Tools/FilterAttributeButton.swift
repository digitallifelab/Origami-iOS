//
//  FilterAttributeButton.swift
//  Origami
//
//  Created by CloudCraft on 25.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class FilterAttributeButton: UIButton {
    
    var toggleType:ToggleType = .ToggledOff(filterType:.Signal) {
        didSet {
            switch toggleType {
            case .ToggledOn:
                self.imageEdgeInsets = UIEdgeInsetsZero
                self.backgroundColor = self.tintColor?.colorWithAlphaComponent(0.6)
                self.layer.cornerRadius = 5.0
                self.layer.masksToBounds = true
            case .ToggledOff:
                self.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
                self.backgroundColor = UIColor.clearColor()
                
            }
        }
    }

}
