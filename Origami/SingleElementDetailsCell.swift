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
            let old = oldValue
            if displayMode == old
            {
                return
            }
            switch self.displayMode
            {
            case .Day:
                self.textLabel.textColor = UIColor.blackColor()
                self.moreLessButton.tintColor = kDaySignalColor
            case .Night:
                self.textLabel.textColor = UIColor.grayColor()
                self.moreLessButton.tintColor = kNightSignalColor
            }
        }
    }
    
    @IBOutlet var textLabel:UILabel!
    @IBOutlet var moreLessButton:UIButton!
    //var labelTapRecognizer:UITapGestureRecognizer?
    
    
    @IBAction func moreLeccButtonTap(sender:UIButton)
    {
        // send event to upper views - need to recalculate self`s dimensions in collectionViewLayout subclass
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        if let labelTapper = labelTapRecognizer
//        {
//            
//        }
//        else
//        {
//            labelTapRecognizer = UITapGestureRecognizer(target: self, action: "labelTapped:")
//            labelTapRecognizer!.numberOfTapsRequired = 1
//            labelTapRecognizer!.numberOfTouchesRequired = 1
//            textLabel.userInteractionEnabled = true
//            textLabel.addGestureRecognizer(labelTapRecognizer!)
//        }
    }
    
//    private func labelTapped(sender:UITapGestureRecognizer)
//    {
//        //
//    }
//    
}
