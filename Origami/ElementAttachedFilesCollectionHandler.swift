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
    
    lazy var attachIconSound = UIImage(named: "icon-attach-sound")
    lazy var attachIconDocument = UIImage(named: "icon-attach-document")
    lazy var attachIconVideo = UIImage(named: "icon-attach-video")
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
        var attachCell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachedFileCell", forIndexPath: indexPath) as! ElementDashboardAttachedFileCell
        
        configureCell(attachCell, forIndexPath: indexPath)

        return attachCell
    }

    func configureCell( cell:ElementDashboardAttachedFileCell, forIndexPath indexPath:NSIndexPath) {
        if indexPath.item < attachedItems.count
        {
            let attachFile = attachedItems[indexPath.item]
            
            if attachFile.attachID == nil
            {
                if let delegate = self.collectionView?.delegate
                {
                    
                }
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
                    else if let filePreviewData = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(attachFile)
                    {
                        var lvMediaFile = MediaFile()
                        lvMediaFile.data = filePreviewData[attachFile]! // Attention! assigning small image data to MediaFile, not full size image data. !
                        lvMediaFile.name = attachFile.fileName!
                        lvMediaFile.type = .Image
                        
                        attachData[attachFile.attachID!] = lvMediaFile
                        cell.attachIcon.image = UIImage(data: lvMediaFile.data)
                    }
                case .Document:
                    cell.attachIcon.image = attachIconDocument
                case .Sound:
                    cell.attachIcon.image = attachIconSound
                case .Video:
                    cell.attachIcon.image = attachIconVideo
                }
            }
            else
            {
                self.loadAttachFileDataForAttachFile(attachFile, atIndexPath: indexPath, completion: {[weak self] (hasData) -> () in
                    if let aSelf = self
                    {
                        if hasData == true
                        {
                            aSelf.collectionView?.reloadItemsAtIndexPaths([indexPath])
                        }
                    }
                })
            }
        }
    }
    
    func createMediaFileForAttachIfNotExist(attachFile:AttachFile)
    {
        if let aMediaFile = attachData[attachFile.attachID!]
        {
            return
        }
        
        if let filePreviewData = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(attachFile)
        {
            var lvMediaFile = MediaFile()
            lvMediaFile.data = filePreviewData[attachFile]! // Attention! assigning small image data to MediaFile, not full size image data. !
            lvMediaFile.name = attachFile.fileName!
            lvMediaFile.type = .Image
            
            attachData[attachFile.attachID!] = lvMediaFile
        }
    }
    
    private func loadAttachFileDataForAttachFile(attach:AttachFile, atIndexPath indexPath:NSIndexPath,
        completion completionBlock:((hasData:Bool)->())?)
    {
        DataSource.sharedInstance.loadAttachFileDataForAttaches([attach], completion: { [weak self] () -> () in
            let backgroundQueue = dispatch_queue_create("attached file data queue", DISPATCH_QUEUE_SERIAL)
            
            dispatch_async(backgroundQueue, {[weak self] () -> Void in
                if let filePreviewData = DataSource.sharedInstance.getSnapshotImageDataForAttachFile(attach)
                {
                    if let weakSelf = self
                    {
                        weakSelf.createMediaFileForAttachIfNotExist(attach)
                    }
                        
                    dispatch_async(dispatch_get_main_queue(), { ()->() in
                            
                        completionBlock?(hasData:true)
                    })
                    
                    
                }
                else
                {
                    if let weakSelf = self, compBlock = completionBlock
                    {
                        dispatch_async(dispatch_get_main_queue(), { ()->() in
                            
                            compBlock(hasData:false)
                        })
                    }
                }
            })
        })
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
        arrayOfAttaches.sort { (attach1, attach2) -> Bool in
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
        println("\n ->>Reloading attaches collection cell <<- \n \n")
        self.attachedItems = arrayOfAttaches
        self.collectionView?.reloadSections(NSIndexSet(index: 0))
    }
    
    //MARK: Delegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.attachTapDelegate?.attachedFileTapped(attachedItems[indexPath.item])
    }
    
    
    

}
