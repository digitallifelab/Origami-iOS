//
//  ElementDashboardAttachedFileCell.swift
//  Origami
//
//  Created by CloudCraft on 14.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementDashboardAttachedFileCell: UICollectionViewCell
{
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var attachIcon:UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.grayColor().CGColor
        self.layer.borderWidth = 1.0
        //cell.attachIcon.layer.borderColor = UIColor.grayColor().CGColor
        //cell.attachIcon.layer.borderWidth = 1.0;
    }
    
    override func prepareForReuse() {
        titleLabel.text = nil
        attachIcon.image = nil
        super.prepareForReuse()
    }
    
    override func layoutSubviews() {
        self.contentView.frame = self.bounds
        super.layoutSubviews()
    }
    
}