//
//  CollectionViewHandler.swift
//  Origami
//
//  Created by CloudCraft on 10.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//


/*
NOTE: 
This class is created only for subclassing
*/
import Foundation
import UIKit
class CollectionHandler: NSObject, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource
{
    var collectionView:UICollectionView?
    //dummy implementation of requered methods
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let collectionCell = UICollectionViewCell(frame: CGRectMake(0.0, 0.0, 100.0, 100.0))
        return collectionCell
    }
}