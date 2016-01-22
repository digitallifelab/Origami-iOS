//
//  TapGreetingView.swift
//  Origami
//
//  Created by CloudCraft on 16.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

class TapGreetingView: UIView {

    private let label:UILabel
    private var dayAttributes : [String:AnyObject] = [NSForegroundColorAttributeName:kDayCellBackgroundColor]
    private var nightAttributes : [String:AnyObject] = [NSForegroundColorAttributeName:kWhiteColor]
    
    var text:String = "" {
        didSet{
             self.label.attributedText = NSAttributedString(string: text, attributes:dayAttributes )
        }
    }
    
    var displayMode:DisplayMode = .Day {
        didSet{
            switch displayMode
            {
                case .Day:
                    self.backgroundColor = UIColor.clearColor()
                    self.label.attributedText = NSAttributedString(string: text, attributes:dayAttributes )
                case .Night:
                    self.backgroundColor = UIColor.clearColor()
                    self.label.attributedText = NSAttributedString(string: text, attributes: nightAttributes)
            }
        }
    }
    
    override init(frame: CGRect) {
        
        self.label = UILabel()
       
        self.label.numberOfLines = 0
        if let segoeFont = UIFont(name: "SegoeUI", size: 15.0)
        {
            self.dayAttributes[NSFontAttributeName] = segoeFont
            self.nightAttributes[NSFontAttributeName] = segoeFont
        }
        
        super.init(frame: frame)
        self.label.frame = self.bounds
        print(" label frame: \(label.frame)")
        self.label.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        self.addSubview(self.label)
    }

    required init?(coder aDecoder: NSCoder) {
        self.label = UILabel()
        self.label.numberOfLines = 0
        
        super.init(coder: aDecoder)
    }

}
