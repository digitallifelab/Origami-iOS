//
//  SingleElementAttachesCollectionHolderCell.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementAttachesCollectionHolderCell: UICollectionViewCell, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    @IBOutlet weak var attachesCollectionView:UICollectionView?
    var delegate:AttachmentCellDelegate?
    let attachCellSize = CGSizeMake(90.0, 70.0)
    
    //MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //handle tap on single attach file
        delegate?.attachTappedAtIndexPath(indexPath)
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return attachCellSize
    }
    
    //MARK - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let countOfAttaches = delegate?.attachesCount()
        {
            return countOfAttaches
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let attachItemCell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachedFileCell", forIndexPath: indexPath) as? AttachedFileCell
        {
            attachItemCell.titleLabel.text = delegate?.titleForAttachmentAtIndexPath(indexPath)
            attachItemCell.attachIcon.image = delegate?.imageForAttachmentAtIndexPath(indexPath)
            return attachItemCell
        }
        
        return UICollectionViewCell()
    }
}
