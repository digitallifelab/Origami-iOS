//
//  ChatMessageRecievedCell.swift
//  Origami
//
//  Created by CloudCraft on 17.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ChatMessageRecievedCell: UITableViewCell {

    @IBOutlet var avatar:UIImageView!
    @IBOutlet var dateLabel:UILabel!
    @IBOutlet var nameLabel:UILabel!
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var textContainerView:UIView!
    var borderLayer:CAShapeLayer?
    var maskLayer:CAShapeLayer?
    
    var message:String?{
        didSet{
            borderLayer?.removeFromSuperlayer()
            maskLayer?.removeFromSuperlayer()
            
            messageLabel.text = message
            messageLabel.sizeToFit()
            
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.avatar.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.avatar.maskToCircle()
        // Initialization code
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = 200.0
        super.layoutSubviews()
        //setMaskTo(self.textContainerView, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight | UIRectCorner.TopRight, withColor: UIColor.lightGrayColor())
    }
    
    func roundCorners()
    {
        self.layoutIfNeeded()
        
        setMaskTo(self.textContainerView, byRoundingCorners: UIRectCorner.BottomLeft | UIRectCorner.BottomRight | UIRectCorner.TopRight, withColor: UIColor.lightGrayColor())
    }
    
    func setMaskTo(view:UIView, byRoundingCorners corners:UIRectCorner, withColor color:UIColor)
    {
        let rect = view.bounds
        //println("layout bounds: \(rect)")
        //rounded mask
        var rounded =  UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSizeMake(10.0, 10.0))
        var shape = CAShapeLayer()
        shape.path = rounded.CGPath;
        self.maskLayer = shape;
        view.layer.mask = shape;
      
//        //rounded border
//        var roundedSubPath = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSizeMake(10.0, 10.0))
//        
//        var borderLayer = CAShapeLayer()
//        borderLayer.path = roundedSubPath.CGPath
//        borderLayer.lineWidth = 1.0;
//        borderLayer.strokeColor = color.CGColor;
//        borderLayer.fillColor = nil;
//        self.borderLayer = borderLayer;
//        view.layer.insertSublayer(borderLayer, above:shape);
        
        super.layoutSubviews()
    }
}
