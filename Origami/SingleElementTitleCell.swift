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
                favouriteButton.backgroundColor = kDaySignalColor
            case .Night:
                self.backgroundColor = UIColor.clearColor()
                favouriteButton.backgroundColor = kNightSignalColor
            }
        }
    }
    
    var favourite:Bool = false {
        didSet{
            
            if favourite
            {
                favouriteButton.tintColor = UIColor.yellowColor()
            }
            else
            {
                favouriteButton.tintColor = kWhiteColor
            }
        }
    }
    
    
    
    @IBOutlet var labelTitle:UILabel!
    @IBOutlet var labelDate:UILabel!
    @IBOutlet var favouriteButton:UIButton!
    
    @IBAction func favoutireButtonTap(sender:UIButton)
    {
        var tapNotification = NSNotification(name: kElementFavouriteButtonTapped, object: self)

        NSNotificationCenter.defaultCenter().postNotification(tapNotification)
    }
    
}
