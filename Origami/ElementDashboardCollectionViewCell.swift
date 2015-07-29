//
//  ElementDashboardCollectionViewCell.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementDashboardCollectionViewCell: UITableViewCell //this cell contains ELEMENT SUBORDINATES collection view or ELEMENT ATTACH FILES collection view
{

    @IBOutlet var collectionView:UICollectionView!
    
    var collectionHandler:CollectionHandler?
        {
        didSet{
            //collectionView.layer.borderWidth = 1.0
            collectionView.delegate = collectionHandler
            collectionView.dataSource = collectionHandler            
            collectionView.reloadData()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor.clearColor()
        
        collectionView.delegate = collectionHandler
        collectionView.dataSource = collectionHandler
        collectionView.scrollEnabled = false
    }
}
