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
    let avatarCellIdentifier = "UserProfileAvatarCell"
    let textCellIdentifier = "UserProfileTextCell"
    
    var currentAvatar:UIImage?
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode{
            case .Day:
                self.view.backgroundColor = kDayNavigationBarBackgroundColor
            case .Night:
                self.view.backgroundColor = kBlackColor
            }
        }
    }
    
    @IBOutlet var profileCollection:UICollectionView!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        self.displayMode = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? .Night : .Day
        
        profileCollection.dataSource = self
        profileCollection.delegate = self
        
        self.navigationController?.navigationBar.tintColor = kWhiteColor
        
        if let layout = UserProfileFlowLayout(numberOfItems: 10)
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
        return 10 // cells with different type of info about logged in user
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        var textCell:UserProfileTextContainerCell?
        var shouldBeDelegate = true
        
        switch indexPath.item
        {
        case 0:
            var avatarCell = collectionView.dequeueReusableCellWithReuseIdentifier(avatarCellIdentifier, forIndexPath: indexPath) as! UserProfileAvatarCollectionCell
            avatarCell.delegate = self
            avatarCell.displayMode = self.displayMode
            if let image = self.currentAvatar
            {
                avatarCell.avatarImageView?.image = image
            }
            return avatarCell
            
        case ProfileTextCellType.Mood.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.titleLabel?.text = "mood".localizedWithComment("")
            textCell?.textLabel?.text = user?.mood as? String
            
        case ProfileTextCellType.Email.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.cellType = .Email
            textCell?.titleLabel?.text = "email".localizedWithComment("")
            textCell?.textLabel?.text = user?.userName as? String
            shouldBeDelegate = false
            
        case ProfileTextCellType.Name.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.titleLabel?.text = "firstName".localizedWithComment("")
            textCell?.cellType = .Name
            textCell?.textLabel?.text = user?.firstName as? String
            
        case ProfileTextCellType.LastName.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.titleLabel?.text = "lastName".localizedWithComment("")
            textCell?.cellType = .LastName
            textCell?.textLabel?.text = user?.lastName as? String
            
        case ProfileTextCellType.Country.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.titleLabel?.text = "country".localizedWithComment("")
            textCell?.cellType = .Country
            textCell?.textLabel?.text = user?.country as? String
            
        case ProfileTextCellType.Language.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.titleLabel?.text = "language".localizedWithComment("")
            textCell?.cellType = .Language
            textCell?.textLabel?.text = user?.language as? String
            
        case ProfileTextCellType.Age.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.cellType = .Age
            textCell?.titleLabel?.text = "age".localizedWithComment("")
            textCell?.textLabel?.text = nil
            if let userBirthDay = user?.birthDay as? String
            {
                var date = userBirthDay.dateFromServerDateString()
                if let existDate = date
                {
                    let birthDateString = existDate.dateStringMediumStyle()
                    textCell?.textLabel?.text = birthDateString
                }
            }
            
        case ProfileTextCellType.PhoneNumber.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.titleLabel?.text = "phone".localizedWithComment("")
            textCell?.cellType = .PhoneNumber
            textCell?.textLabel?.text = user?.phone as? String
            
        case ProfileTextCellType.Password.rawValue:
            textCell = collectionView.dequeueReusableCellWithReuseIdentifier(textCellIdentifier, forIndexPath: indexPath) as? UserProfileTextContainerCell
            textCell?.textLabel?.text = "changePassword".localizedWithComment("")
            textCell?.titleLabel?.text = nil
            textCell?.cellType = .Password
            
        default:
            break
        }
        
        if let cell = textCell
        {
            cell.delegate = (shouldBeDelegate) ? self : nil
            cell.displayMode = self.displayMode
            return cell
        }
        
        return UserProfileTextContainerCell()
    }
    
//    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        if indexPath.item == 0
//        {
//            if let avatarCell = cell as? UserProfileAvatarCollectionCell
//            {
//                avatarCell.avatar.setImage(self.currentAvatar, forState: .Normal)
//            }
//        }
//    }
    
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
        println("pressed edit \(cellType.rawValue)")
        
        switch cellType
        {
        case .Age:
            startEditingUserBirthDate()
        case .Country:
            startEditingCountry()
        case .Language:
            startEditingLanguage()
        case .Mood:
            startEditingMood()
        case .Name:
            startEditingUserFirstName()
        case .LastName:
            startEditingUserLastname()
        case .PhoneNumber:
            startEditingPhoneNumber()
        case .Password:
            startEditingUserPassword()
        case .Email:
            break
            
        }
    }
    
    //MARK: handle editing user Photo
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
    //MARK: Edit User Text Info
    
    func startEditingUserBirthDate()
    {
        
    }
    
    func startEditingCountry()
    {
        
    }
    
    func startEditingLanguage()
    {
        
    }
    
    func startEditingMood()
    {
        
    }
    
    func startEditingUserFirstName()
    {
        
    }
    
    func startEditingUserLastname()
    {
        
    }
    
    func startEditingPhoneNumber()
    {
        
    }
    
    func startEditingUserPassword()
    {
        
    }
    
    
    
}
