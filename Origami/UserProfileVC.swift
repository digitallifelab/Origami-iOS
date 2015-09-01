//
//  UserProfileVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, UITextFieldDelegate, UserProfileAvatarCollectionCellDelegate, AttachPickingDelegate, TableItemPickerDelegate, UIAlertViewDelegate {

    var user = DataSource.sharedInstance.user
    let avatarCellIdentifier = "UserProfileAvatarCell"
    let textCellIdentifier = "UserProfileTextCell"
    var defaultEdgeInsets:UIEdgeInsets?
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
    
    var tempPassword:String?
    
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        addObserversForKeyboard()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeObserversForKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: - UITextViewDelegate and stuff
    func addObserversForKeyboard()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardAppearance:", name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardAppearance:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func removeObserversForKeyboard()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func handleKeyboardAppearance(notification:NSNotification)
    {
        if let notifInfo = notification.userInfo
        {
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue()
            let keyboardHeight = keyboardFrame.size.height
            //let animationOptionCurveNumber = notifInfo[UIKeyboardAnimationCurveUserInfoKey]! as! NSNumber
            //let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions.fromRaw(   animationOptionCurveNumber)
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            var keyboardIsToShow = false
            if notification.name == UIKeyboardWillShowNotification
            {
                keyboardIsToShow = true
                defaultEdgeInsets = profileCollection.contentInset
                let edgeInsets = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
                profileCollection.contentInset = edgeInsets
                
            }
            else
            {
               //let edgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
                profileCollection.contentInset = defaultEdgeInsets!
            }
            
            
            UIView.animateWithDuration(animationTime,
                delay: 0.0,
                options: options,
                animations: {  [weak self]  in
                    if let weakSelf = self
                    {
                        weakSelf.view.layoutIfNeeded()
                    }
                    
                    
                },
                completion: { [weak self]  (finished) -> () in
                    
                })
        }
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        if let type = ProfileTextCellType(rawValue:textView.tag)
        {
            switch type{
            case .PhoneNumber:
                let nsString:NSString = textView.text
                var integerString = nsString.longLongValue
                
                //store before updating user phone
                var previousValue = DataSource.sharedInstance.user?.phone
                
                if integerString > 0 && integerString < INT64_MAX
                {
                    DataSource.sharedInstance.user?.phone = String("\(integerString)")
                    DataSource.sharedInstance.editUserInfo({ (success, error) -> () in
                        if success
                        {
                            println(" -> UserProfileVC succeeded to edit user Phone Number.")
                            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                if let weakSelf = self
                                {
                                    weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.PhoneNumber.rawValue, inSection: 0)])
                                }
                                })
                        }
                        else
                        {
                            if let anError = error
                            {
                                println(" -> UserProfileVC failed to edit user Phone Number.")
                                DataSource.sharedInstance.user?.phone = previousValue
                                dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                    if let weakSelf = self
                                    {
                                        weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Age.rawValue, inSection: 0)])
                                        weakSelf.showAlertWithTitle("Error.", message: "Could not update your phone number.", cancelButtonTitle: "Close")
                                    }
                                    })
                            }
                        }
                    })
                }
                else if textView.text .isEmpty
                {
                    DataSource.sharedInstance.user?.phone = ""
                    DataSource.sharedInstance.editUserInfo({ (success, error) -> () in
                        if success
                        {
                            println(" -> UserProfileVC succeeded to edit user Phone Number.")
                            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                if let weakSelf = self
                                {
                                    weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.PhoneNumber.rawValue, inSection: 0)])
                                }
                                })
                        }
                        else
                        {
                            if let anError = error
                            {
                                println(" -> UserProfileVC failed to edit user Phone Number.")
                                DataSource.sharedInstance.user?.phone = previousValue
                                dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                    if let weakSelf = self
                                    {
                                        weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Age.rawValue, inSection: 0)])
                                        weakSelf.showAlertWithTitle("Error.", message: "Could not update your phone number.", cancelButtonTitle: "Close")
                                    }
                                    })
                            }
                        }
                    })
                }
            case .Name:
                userDidChangeFirstName(textView.text)
                
            case .LastName:
                userDidChangeLastName(textView.text)
            default:
                break
            }
        }
        return true
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if textField.tag == ProfileTextCellType.Password.rawValue
        {
            tempPassword = textField.text
            showAlertAboutChangePassword()
        }
        textField.removeFromSuperview()
        return true
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
    //MARK: UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let datePickerHolder = self.view.viewWithTag(0xDA7E)
        {
            datePickerCancels(nil)
        }
        for aCell in profileCollection.visibleCells()
        {
            if let textCell = aCell as? UserProfileTextContainerCell
            {
                textCell.stopEditingText()
            }
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
        profileCollection.scrollToItemAtIndexPath(NSIndexPath(forItem: 8, inSection: 0), atScrollPosition: .Top, animated: true)
        
        showDatePickerView()
        
    }
    
    func startEditingCountry()
    {
        DataSource.sharedInstance.getCountries {[weak self] (countries, error) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if let weakSelf = self
                {
                    if let countriesArray = countries, countriesTableVC = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("ItemPickerVC") as? TableItemPickerVC
                    {
                        countriesTableVC.delegate = self
                        countriesTableVC.pickerType = .Country
                        countriesTableVC.startItems = countriesArray
                        weakSelf.navigationController?.pushViewController(countriesTableVC, animated: true)
                    }
                }
            })
        }
    }
    
    func startEditingLanguage()
    {
        DataSource.sharedInstance.getLanguages { [weak self](languages, error) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let weakSelf = self
                {
                    if let langArray = languages, langsTableVC = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("ItemPickerVC") as? TableItemPickerVC
                    {
                        langsTableVC.delegate = self
                        langsTableVC.pickerType = .Language
                        langsTableVC.startItems = langArray
                        weakSelf.navigationController?.pushViewController(langsTableVC, animated: true)
                    }
                }
            })
        }
    }
    
    func startEditingMood()
    {
        
    }
    
    func startEditingUserFirstName()
    {
        let indexPath = NSIndexPath(forItem: ProfileTextCellType.Name.rawValue, inSection: 0)
        if let textCell = profileCollection.cellForItemAtIndexPath(indexPath) as? UserProfileTextContainerCell
        {
            textCell.enableTextView(nil)
            textCell.textView?.delegate = self
            
            textCell.startEditingText()
            profileCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func startEditingUserLastname()
    {
        let indexPath = NSIndexPath(forItem: ProfileTextCellType.LastName.rawValue, inSection: 0)
        if let textCell = profileCollection.cellForItemAtIndexPath(indexPath) as? UserProfileTextContainerCell
        {
            textCell.enableTextView(nil)
            textCell.textView?.delegate = self
            
            textCell.startEditingText()
            profileCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func startEditingPhoneNumber()
    {
        let indexPath = NSIndexPath(forItem: ProfileTextCellType.PhoneNumber.rawValue, inSection: 0)
      
        if let textCell = profileCollection.cellForItemAtIndexPath(indexPath) as? UserProfileTextContainerCell
        {
            if let currentPhone = DataSource.sharedInstance.user?.phone as? String
            {
                if currentPhone.isEmpty || currentPhone ==  " "
                {
                    textCell.enableTextView("+")
                }
                else
                {
                    textCell.enableTextView(nil)
                }
            }
            else
            {
                textCell.enableTextView("+")
            }
            textCell.textView?.delegate = self
            
            textCell.startEditingText()
            profileCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func startEditingUserPassword()
    {
        let indexPath = NSIndexPath(forItem: ProfileTextCellType.Password.rawValue, inSection: 0)
        
        if let textCell = profileCollection.cellForItemAtIndexPath(indexPath) as? UserProfileTextContainerCell
        {
            textCell.enableTextView(nil)
          
            textCell.passwordTextField?.delegate = self
            
            textCell.startEditingText()
            profileCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    //MARK: birthday picking
    func showDatePickerView()
    {
        
        var datePickerHolderView = UIView(frame: CGRectMake(0.0, CGRectGetMaxY(self.profileCollection.frame) - 280.0, CGRectGetWidth(self.view.bounds), 280.0))
        datePickerHolderView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleTopMargin
        datePickerHolderView.tag = 0xDA7E // :-) DATE
        datePickerHolderView.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.7)
        
        let holderWidth = CGRectGetWidth(datePickerHolderView.bounds)
        
        var datePicker = UIDatePicker(frame: CGRectMake(0, 50.0, datePickerHolderView.bounds.size.width, 200))
        datePicker.backgroundColor = UIColor.whiteColor()
        if let currentDate = user?.birthDay?.dateFromServerDateString()
        {
            datePicker.date = currentDate
        }
        else
        {
            datePicker.date = NSDate()
        }
        datePicker.datePickerMode = UIDatePickerMode.Date
        datePicker.tag = 2
        
        datePickerHolderView.addSubview(datePicker)
        
        var button = UIButton.buttonWithType(UIButtonType.System) as? UIButton
        button?.tintColor = (self.displayMode == .Day) ? kDayCellBackgroundColor : kWhiteColor
        button?.backgroundColor = (self.displayMode == .Day) ? UIColor.whiteColor() : UIColor.lightGrayColor()
        button?.frame = CGRectMake(holderWidth - 60.0 , 0.0, 60, 44.0)
        button?.setTitle("done".localizedWithComment(""), forState: .Normal)
        button?.addTarget(self, action: "datePickerSubmitNewDate:", forControlEvents: .TouchUpInside)
        if let b = button
        {
            datePickerHolderView.addSubview(button!)
        }
  
        var cancelButton = UIButton.buttonWithType(.System) as? UIButton
        cancelButton?.tintColor = button?.tintColor
        cancelButton?.backgroundColor = (self.displayMode == .Day) ? UIColor.whiteColor() : UIColor.lightGrayColor()
        cancelButton?.frame = CGRectMake(0, 0, 60.0, 44.0)
        cancelButton?.setTitle("cancel".localizedWithComment(""), forState: .Normal)
        cancelButton?.addTarget(self, action: "datePickerCancels:", forControlEvents: .TouchUpInside)
        if let cB = cancelButton
        {
            datePickerHolderView.addSubview(cancelButton!)
        }
        
        self.view.insertSubview(datePickerHolderView, aboveSubview: profileCollection)
    }
    
    func datePickerCancels(sender:UIButton?)
    {
        sender?.enabled = false
        if let holderView = self.view.viewWithTag(0xDA7E) //datePickerHolderView
        {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                holderView.alpha = 0.1
            }, completion: { (finished) -> Void in
                holderView.removeFromSuperview()
            })
        }
    }
    
    func datePickerSubmitNewDate(sender:UIButton?)
    {
        sender?.enabled = false
        if let holderView = self.view.viewWithTag(0xDA7E)
        {
            if let datePicker = holderView.viewWithTag(2) as? UIDatePicker
            {
                let date = datePicker.date
                var previousDate = DataSource.sharedInstance.user?.birthDay
                DataSource.sharedInstance.user?.birthDay = date.dateForServer()
                DataSource.sharedInstance.editUserInfo { (success, error) -> () in
                    if success
                    {
                        println(" -> UserProfileVC succeeded to edit user birth date.")
                        dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                            if let weakSelf = self
                            {
                                weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Age.rawValue, inSection: 0)])
                            }
                        })
                    }
                    else if let anError = error
                    {
                        println(" -> UserProfileVC failed to edit user birth date.")
                        DataSource.sharedInstance.user?.birthDay = previousDate
                        dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                            if let weakSelf = self
                            {
                                weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Age.rawValue, inSection: 0)])
                                weakSelf.showAlertWithTitle("Error.", message: "Could not update your birthday.", cancelButtonTitle: "Close")
                            }
                        })
                    }
                }
                
            }
            //dismiss datePickerHolderView
            datePickerCancels(nil)
        }
    }
    
    
    //MARK: Password changing
    
    func showAlertAboutChangePassword()
    {
        let title =  "attention".localizedWithComment("")
        let message = "sureToChangePassword".localizedWithComment("")
        let cancelTitle = "cancel".localizedWithComment("")
        let proceedTitle = "change".localizedWithComment("")
        
        if FrameCounter.isLowerThanIOSVersion("8.0")
        {
            let alertView = UIAlertView(
                title: title,
                message: message,
                delegate: self,
                cancelButtonTitle: cancelTitle,
                otherButtonTitles: proceedTitle)
            alertView.tag = ProfileTextCellType.Password.rawValue
            alertView.show()
            
        }
        else
        {
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .Alert)
            
            let alertActionCancel = UIAlertAction(title: cancelTitle, style: .Cancel, handler: {[weak self] (alertAction) -> Void in
                if let weakSelf = self
                {
                    weakSelf.tempPassword = nil
                    weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Password.rawValue, inSection: 0)])
                }
            })
            
            let alertActionChange = UIAlertAction(title: proceedTitle, style: .Default, handler: {[weak self] (alertAction) -> Void in
                if let weakSelf = self
                {
                    weakSelf.userDidConfirmPasswordChange()
                }
            })
            
            alertController.addAction(alertActionCancel)
            alertController.addAction(alertActionChange)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func userDidConfirmPasswordChange()
    {
        if let password = tempPassword
        {
            let oldPassword = DataSource.sharedInstance.user?.password
            
            DataSource.sharedInstance.user?.password = password
            DataSource.sharedInstance.editUserInfo({[weak self] (success, error) -> () in
                if let weakSelf = self
                {
                    weakSelf.tempPassword = nil
                }
                
                if success
                {
                    println(" -> UserProfileVC succeeded to edit user Password: /n->Old Password: \(oldPassword) /n->New Password: \(password)")
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Password.rawValue, inSection: 0)])
                        }
                        })
                    
                    //save new password to later automatic login
                    let bgQueue = dispatch_queue_create("Origami.passwordSaving.", DISPATCH_QUEUE_SERIAL)
                    dispatch_async(bgQueue, { () -> Void in
                        NSUserDefaults.standardUserDefaults().setObject(password, forKey: passwordKey)
                        NSUserDefaults.standardUserDefaults().synchronize()
                    })
                }
                else
                {
                    println(" -> UserProfileVC failed to edit user Password.")
                    
                    if let anError = error
                    {
                        if let anError = error
                        {
                            println("Error: \n ->\(anError)")
                        }
                    }
                   
                    DataSource.sharedInstance.user?.password = oldPassword
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Password.rawValue, inSection: 0)])
                            weakSelf.showAlertWithTitle("Error.", message: "Could not update your Password.", cancelButtonTitle: "Close")
                        }
                        })
                }
                
            })
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if alertView.tag == ProfileTextCellType.Password.rawValue
        {
            switch buttonIndex
            {
            case 1:
                userDidConfirmPasswordChange()
            case alertView.cancelButtonIndex:
                self.tempPassword = nil
                self.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Password.rawValue, inSection: 0)])
            default:
                break
            }
        }
    }
    
    //MARK -- Country & Language
    //MARK: TableItemPickerDelegate
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject) {
        if let itemPickerVC = itemPicker as? TableItemPickerVC
        {
            switch itemPickerVC.pickerType
            {
            case .Country:
                if let country = item as? Country
                {
                    userDidChangeCountry(country)
                }
            case .Language:
                if let language = item as? Language
                {
                    userDidChangeLanguage(language)
                }
            }
        }
        self.navigationController?.popViewControllerAnimated(false)
    }
    
    func itemPickerDidCancel(itemPicker: AnyObject) {
        if let vc = itemPicker as? UIViewController
        {
            vc.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    //MARK: Country & Language
    
    func userDidChangeCountry(country:Country)
    {
        let oldId = DataSource.sharedInstance.user?.countryId
        let oldName = DataSource.sharedInstance.user?.country
        
        DataSource.sharedInstance.user?.country = country.countryName
        DataSource.sharedInstance.user?.countryId = country.countryId
        
        DataSource.sharedInstance.editUserInfo({ [weak self](success, error) -> () in
            if let weakSelf = self
            {
                if success
                {
                    println(" -> UserProfileVC succeeded to edit user Country: /n->Old Country: \(oldName) /n->New Country: \(DataSource.sharedInstance.user?.country)")
                    weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forItem: ProfileTextCellType.Country.rawValue, inSection: 0)])
                }
                else
                {
                    DataSource.sharedInstance.user?.country = oldName
                    DataSource.sharedInstance.user?.countryId = oldId
                    println(" -> UserProfileVC failed to edit user Country.")
                    weakSelf.showAlertWithTitle("Error.", message: "Could not update your Country.", cancelButtonTitle: "Close")
                    if let anError = error
                    {
                        println("Error: \n ->\(anError)")
                    }
                }
            }
        })
    }
    
    func userDidChangeLanguage(language:Language)
    {
        let oldId = DataSource.sharedInstance.user?.languageId
        let oldName = DataSource.sharedInstance.user?.language
        
        DataSource.sharedInstance.user?.language = language.languageName
        DataSource.sharedInstance.user?.languageId = language.languageId
        
        DataSource.sharedInstance.editUserInfo({ [weak self](success, error) -> () in
            if let weakSelf = self
            {
                if success
                {
                    println(" -> UserProfileVC succeeded to edit user Language: /n->Old Language: \(oldName) /n->New Language: \(DataSource.sharedInstance.user?.language)")
                    weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forItem: ProfileTextCellType.Language.rawValue, inSection: 0)])
                }
                else
                {
                    DataSource.sharedInstance.user?.language = oldName
                    DataSource.sharedInstance.user?.languageId = oldId
                    println(" -> UserProfileVC failed to edit user Language.")
                    weakSelf.showAlertWithTitle("Error.", message: "Could not update your Language.", cancelButtonTitle: "Close")
                    if let anError = error
                    {
                        println("Error: \n ->\(anError)")
                    }
                }
            }
            })
    }
    
    //MARK: Name, LastName, Mood change
    func userDidChangeFirstName(newFirstName:String?)
    {
        if let newname = newFirstName
        {
            let oldName = DataSource.sharedInstance.user?.firstName
            
            DataSource.sharedInstance.user?.firstName = newname
            DataSource.sharedInstance.editUserInfo({ (success, error) -> () in
                if success
                {
                    println(" -> UserProfileVC succeeded to edit user LastName: /n->Old FirstName: \(oldName) /n->New FirstName: \(DataSource.sharedInstance.user?.lastName)")
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Name.rawValue, inSection: 0)])
                        }
                        })
                }
                else
                {
                    println(" -> UserProfileVC failed to edit user FirstName.")
                    
                    if let anError = error
                    {
                        println("Error: \n ->\(anError)")
                    }
                    
                    DataSource.sharedInstance.user?.password = oldName
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.Name.rawValue, inSection: 0)])
                            weakSelf.showAlertWithTitle("Error.", message: "Could not update your name.", cancelButtonTitle: "Close")
                        }
                        })
                }
            })
        }
    }
    
    func userDidChangeLastName(newLastName:String?)
    {
        if let newname = newLastName
        {
            let oldLastName = DataSource.sharedInstance.user?.lastName
            
            DataSource.sharedInstance.user?.lastName = newname
            DataSource.sharedInstance.editUserInfo({ (success, error) -> () in
                if success
                {
                    println(" -> UserProfileVC succeeded to edit user LastName: /n->Old LastName: \(oldLastName) /n->New LastName: \(DataSource.sharedInstance.user?.lastName)")
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.LastName.rawValue, inSection: 0)])
                        }
                    })
                }
                else
                {
                    println(" -> UserProfileVC failed to edit user LastName.")
                    
                    if let anError = error
                    {
                        println("Error: \n ->\(anError)")
                    }
                    
                    DataSource.sharedInstance.user?.password = oldLastName
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.profileCollection.reloadItemsAtIndexPaths([NSIndexPath(forRow: ProfileTextCellType.LastName.rawValue, inSection: 0)])
                            weakSelf.showAlertWithTitle("Error.", message: "Could not update your last name.", cancelButtonTitle: "Close")
                        }
                    })
                }
            })
        }
    }
}
