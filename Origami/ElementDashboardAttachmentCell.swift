//
//  ElementDashboardAttachmentCell.swift
//  Origami
//
//  Created by CloudCraft on 24.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementDashboardAttachmentCell: UITableViewCell {

    @IBOutlet var collectionView:UICollectionView!
    var collectionHandler:CollectionHandler?
        {
        didSet{
            //collectionView.layer.borderWidth = 1.0
            collectionView.delegate = collectionHandler
            collectionView.dataSource = collectionHandler
            
        }
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
