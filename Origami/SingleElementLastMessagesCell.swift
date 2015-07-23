//
//  SingleElementLastMessagesCell.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementLastMessagesCell: UICollectionViewCell {
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode{
            case .Day:
                chatIcon.backgroundColor = kDaySignalColor
            
            case .Night:
                chatIcon.backgroundColor = kNightSignalColor
            }
        }
    }
    
    @IBOutlet var chatIcon:UILabel!
    @IBOutlet var messagesTable:UITableView!
    
    override func prepareForReuse() {
        
    }
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        let bounds = chatIcon.bounds
        let roundedLeftBottomPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: UIRectCorner.BottomLeft, cornerRadii: CGSizeMake(5, 5))
        
        var shape = CAShapeLayer()
        shape.frame = bounds
        shape.path = roundedLeftBottomPath.CGPath
        
        chatIcon.layer.mask = shape
        
        let angle = CGFloat(90.0 * CGFloat(M_PI) / 180.0)
        chatIcon.transform = CGAffineTransformMakeRotation(angle)
        
    }
    
}
