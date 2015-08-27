//
//  UserProfileVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UserProfileAvatarCollectionCellDelegate, AttachPickingDelegate {

    var user = DataSource.sharedInstance.user
    
    @IBOutlet var profileCollection:UICollectionView!
    
    var currentAvatar:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileCollection.dataSource = self
        profileCollection.delegate = self
        
        self.navigationController?.navigationBar.tintColor = kWhiteColor
        
        if let layout = UserProfileFlowLayout(numberOfItems: 7)
        {
            profileCollection.setCollectionViewLayout(layout, animated: false) //we are in view did load, so false
        }
     
        let backGroundQueue = dispatch_queue_create("user_Avatar_queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(backGroundQueue, { [weak self] () -> Void in
            if let userName = DataSource.sharedInstance.user?.userName as? String
            {
                DataSource.sharedInstance.loadAvatarForLoginName(userName, completion: {(image) -> () in
                    if let avatar = image, weakSelf = self
                    {
                        weakSelf.currentAvatar = avatar
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                           weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                        })
                        
                    }
                })
            }
            
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9 // cells with different type of info about logged in user
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        switch indexPath.item
        {
        case 0:
            var avatarCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileAvatarCell", forIndexPath: indexPath) as! UserProfileAvatarCollectionCell
            avatarCell.backgroundColor = UIColor.brownColor()
            avatarCell.delegate = self
            if let image = self.currentAvatar
            {
                avatarCell.avatar.setImage(image, forState: .Normal)
            }
            return avatarCell
            
        case ProfileTextCellType.Email.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Email
            return textCell
            
        case ProfileTextCellType.Name.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Name
            textCell.delegate = self
            return textCell
            
        case ProfileTextCellType.LastName.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .LastName
            return textCell
            
        case ProfileTextCellType.Country.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Country
            return textCell
            
        case ProfileTextCellType.Language.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Language
            return textCell
            
        case ProfileTextCellType.Age.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Age
            return textCell
            
        case ProfileTextCellType.PhoneNumber.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .PhoneNumber
            return textCell
            
        case ProfileTextCellType.Password.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Password
            return textCell
            
        default:
            return UserProfileTextContainerCell()
        }
    }
    
    
    @IBAction func homeButtonTapped(sender:UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: UserProfileAvatarCollectionCellDelegate
    func showAvatarPressed() {
        showFullscreenUserPhoto()
    }
    
    func changeAvatarPressed() {
        if let imagePicker = self.storyboard?.instantiateViewControllerWithIdentifier("ImagePickerVC") as? ImagePickingViewController
        {
            imagePicker.attachPickingDelegate = self
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    
    func changeInfoPressed(cellType: ProfileTextCellType) {
        
    }
    
    //MARK: handle editing user
    func showFullscreenUserPhoto()
    {
        if let avatar = self.currentAvatar, avatarShowingVC = self.storyboard?.instantiateViewControllerWithIdentifier("AttachImageViewer") as? AttachImageViewerVC
        {
            avatarShowingVC.imageToDisplay = self.currentAvatar
            self.navigationController?.pushViewController(avatarShowingVC, animated: true)
        }
    }
    
    //MARK: AttachPickingDelegate
    func mediaPickerDidCancel(picker: AnyObject) {
        if picker is UIViewController
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mediaPicker(picker: AnyObject, didPickMediaToAttach mediaFile: MediaFile) {
        
        var lvData = mediaFile.data.copy() as! NSData

        if picker is UIViewController
        {
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
        DataSource.sharedInstance.uploadAvatarForCurrentUser(lvData, completion: { [weak self](success, error) -> () in
            if success
            {
                if let weakSelf = self
                {
                    weakSelf.currentAvatar = UIImage(data: lvData)
                
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
                    })
                }
            }
            else
            {
                if let weakSelf = self
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakSelf.showAlertWithTitle("Error", message:"Could not update avatar.", cancelButtonTitle:"Close")
                    })
                }
                
            }
        })
    }
}
