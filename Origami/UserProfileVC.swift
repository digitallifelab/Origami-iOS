//
//  UserProfileVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class UserProfileVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    
    @IBOutlet var profileCollection:UICollectionView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        profileCollection.dataSource = self
        profileCollection.delegate = self
        
        if let layout = UserProfileFlowLayout(numberOfItems: 7)
        {
            profileCollection.setCollectionViewLayout(layout, animated: false) //we are in view did load, so false
        }
     
        // Do any additional setup after loading the view.
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
            return avatarCell
            
        case ProfileTextCellType.Email.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Email
            return textCell
            
        case ProfileTextCellType.Name.rawValue:
            var textCell = collectionView.dequeueReusableCellWithReuseIdentifier("UserProfileTextCell", forIndexPath: indexPath) as! UserProfileTextContainerCell
            textCell.cellType = .Name
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
