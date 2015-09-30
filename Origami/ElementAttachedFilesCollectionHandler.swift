//
//  ElementAttachedFilesCollectionHandler.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementAttachedFilesCollectionHandler: CollectionHandler
{
    lazy var attachedItems:[AttachFile] = [AttachFile]()
    lazy var attachData:[NSNumber:MediaFile] = [NSNumber:MediaFile]()
    
    //moved to in-place switch statement
//    lazy var attachIconSound = UIImage(named: "icon-attach-sound")//UIImage(named: "icon-attach-sound")
//    lazy var attachIconDocument = UIImage(named: "icon-attach-document")
//    lazy var attachIconVideo = UIImage(named: "icon-attach-video")
    var attachTapDelegate:AttachmentSelectionDelegate?
    
    override init()
    {
        super.init()
    }
    
    convenience init?(items:[AttachFile]) // failable initializer - we don`t need to show attach files collection view in element`s dashboard, if there are no attached files
    {
        self.init()
        if items.isEmpty
        {
            return nil
        }
        self.attachedItems = items
    }
    
    //DataSource
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let attachCount = self.attachedItems.count
        if attachCount == 1 //check for
        {
            let attachFile = attachedItems[0]
            if attachFile.attachID == nil
            {
                return 0
            }
        }
        
        return attachCount
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let attachCell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachedFileCell", forIndexPath: indexPath) as! ElementDashboardAttachedFileCell
        
        configureCell(attachCell, forIndexPath: indexPath)

        return attachCell
    }

    func configureCell( cell:ElementDashboardAttachedFileCell, forIndexPath indexPath:NSIndexPath) {
        if indexPath.item < attachedItems.count
        {
            let attachFile = attachedItems[indexPath.item]
            
            if attachFile.attachID == nil
            {
                cell.attachIcon.image = UIImage(named: "icon-addAttachment")
                return
            }
            
            cell.titleLabel.text = attachFile.fileName
            cell.attachIcon.image = noImageIcon
            
            createMediaFileForAttachIfNotExist(attachFile)
            
            if let mediaFile = attachData[attachFile.attachID!]
            {
                switch mediaFile.type!
                {
                case .Image:
                    if let attachImage = UIImage(data: mediaFile.data)
                    {
                        cell.attachIcon.image = attachImage
                    }
                case .Document:
                    cell.attachIcon.image = /*attachIconDocument*/ UIImage(named: "icon-attach-sound")
                case .Sound:
                    cell.attachIcon.image = /*attachIconSound*/ UIImage(named: "icon-attach-document")
                case .Video:
                    cell.attachIcon.image = /*attachIconVideo*/ UIImage(named: "icon-attach-video")
                }
            }
        }
    }
    
    func createMediaFileForAttachIfNotExist(attachFile:AttachFile) -> Bool
    {
        if let _ = attachData[attachFile.attachID!]
        {
            return true
        }
        
        if let filePreviewData = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(attachFile)
        {
            let lvMediaFile = MediaFile()
            lvMediaFile.data = filePreviewData[attachFile]! // Attention! assigning small image data to MediaFile, not full size image data. !
            lvMediaFile.name = attachFile.fileName!
            lvMediaFile.type = .Image
            
            attachData[attachFile.attachID!] = lvMediaFile
            
            return true
        }
        
        return false
    }
    
    
    func attachFileForFileName(name:String) -> (AttachFile, NSIndexPath)? //tuple
    {
        if self.attachedItems.isEmpty
        {
            return nil
        }
        
        let countAttaches = self.attachedItems.count
        for var i = 0; i < countAttaches; i++
        {
            let attach = self.attachedItems[i]
            if attach.fileName == name
            {
                let indexPath = NSIndexPath(forItem: i, inSection: 0)
                return (attach,indexPath)
            }
        }
       
        
        return nil
    }
    
    //MARK: ---
    
    
    func startLoadingAttachedFileSnapshot(fileName:String)
    {
        if let result:(AttachFile, NSIndexPath) = self.attachFileForFileName(fileName)
        {
            if self.createMediaFileForAttachIfNotExist(result.0)
            {
                dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                    if let weakSelf = self
                    {
                        weakSelf.collectionView?.reloadItemsAtIndexPaths([result.1])
                    }
                })
            }
            return
        }
        
        print("\n -> Error: current attach handler does not have attach named \(fileName)\n")
    }
    
    func reloadCollectionWithData(newData:[AttachFile:MediaFile])
    {
        var setOfAttaches = Set(self.attachedItems)
        for (lvAttachFile,lvMediaFile) in newData //assign data locally
        {
            attachData[lvAttachFile.attachID!] = lvMediaFile
            setOfAttaches.insert(lvAttachFile)
        }
        var arrayOfAttaches = Array(setOfAttaches)
        arrayOfAttaches.sortInPlace { (attach1, attach2) -> Bool in
            if let dateString1 = attach1.createDate , dateString2 = attach2.createDate
            {
                if let date1 = (dateString1 as NSString).dateFromServerDateString(), date2 = (dateString2 as NSString).dateFromServerDateString()
                {
                    let comparisonResult = date1.compare(date2)
                    
                    return (comparisonResult == .OrderedAscending)
                }
            }
            
            return false
        }
        print("\n ->>Reloading attaches collection cell <<- \n \n")
        self.attachedItems = arrayOfAttaches
        self.collectionView?.reloadSections(NSIndexSet(index: 0))
    }
    
    //MARK: Delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.attachTapDelegate?.attachedFileTapped(attachedItems[indexPath.item])
    }
    
    
    

}
