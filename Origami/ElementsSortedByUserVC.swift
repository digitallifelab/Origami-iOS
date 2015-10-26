//
//  ElementsSortedByUserVC.swift
//  Origami
//
//  Created by CloudCraft on 11.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementsSortedByUserVC: RecentActivityTableVC, TableItemPickerDelegate {

   
    /*
    //for showing current selected user 
    
    is subject to change if subclassing
    */
    
    var currentTopRightButton:UIButton?
    
    var currentSelectedUserAvatar:UIImage? = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
 
    var elementsCreatedByUser:[DBElement]?
    var elementsUserParticipatesIn:[DBElement]?
    var selectedUserId:Int = 0
    var selectedFilterOption:ElementOptions = ElementOptions.ReservedValue1
    
    override var displayMode:DisplayMode {
        
        didSet {
            switch displayMode
            {
            case .Day:
                self.view.backgroundColor = kWhiteColor
                self.topToolbar?.barTintColor = kWhiteColor
                self.topToolbar?.tintColor = kDayNavigationBarBackgroundColor
            case .Night:
                self.view.backgroundColor = kBlackColor
                self.topToolbar?.barTintColor = kBlackColor
                self.topToolbar?.tintColor = kWhiteColor
            }
        }
        
    }
    
    @IBOutlet weak var segmentedControl:UISegmentedControl?
    @IBOutlet weak var topToolbar:UIToolbar?
    @IBOutlet weak var filterSegmentedControl:UISegmentedControl?
    
    var archivedVisible = false
    
    //MARK: - -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        configureNavigationControllerNavigationBarButtonItems()
        configureCurrentRightTopButton()
        configureCurrentRightButtonImage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.removeGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        super.viewWillDisappear(animated)
        
    }
    
    override func startLoadingElementsByActivity(completion:(()->())?)
    {
        self.setLoadingIndicatorVisible(true)
        
        let isArchivedToggledOn = self.segmentedControl!.selectedSegmentIndex == 1
        let selectedUser = selectedUserId
        let currentlyEnabledOption = selectedFilterOption
        
        dispatch_async(getBackgroundQueue_SERIAL()){
            
            DataSource.sharedInstance.localDatadaseHandler?.readElementsByUserId(selectedUser, archived: isArchivedToggledOn, elementType: currentlyEnabledOption) {[weak self] (result) -> () in
                
                if let weakSelf = self
                {
                    weakSelf.elementsCreatedByUser = result.owned
                    weakSelf.elementsUserParticipatesIn = result.participating
                    
                    dispatch_async(dispatch_get_main_queue()) { _ in
                        completion?()
                        weakSelf.setLoadingIndicatorVisible(false)
                    }
                }
            }
        }
    }
    
    override func configureNavigationControllerToolbarItems() {
        super.configureNavigationControllerToolbarItems()
        configureNavigationControllerNavigationBarButtonItems()
    }
    
    
    
    func configureNavigationControllerNavigationBarButtonItems()
    {
        if let navController = self.navigationController
        {
            let viewControllers = navController.viewControllers
            if viewControllers.count > 1
            {
                return
            }
        }
        let leftButton = UIButton(type:.System)//UIButton.buttonWithType(.System) as! UIButton
        leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
        leftButton.setImage(UIImage(named: "icon-options")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        leftButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
    
        let leftBarButton = UIBarButtonItem(customView: leftButton)
    
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    //MARK: ------ menu displaying
    func menuButtonTapped(sender:AnyObject)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    //MARK: --
    
    override func elementForIndexPath(indexPath: NSIndexPath) -> DBElement?
    {
        if let elements = elementsForSection(indexPath.section)
        {
            if elements.count > indexPath.row
            {
                return elements[indexPath.row]
            }
        }
        return nil
    }
    
    override func reloadTableView()
    {
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.reloadData()
        
        self.tableView?.userInteractionEnabled = true
        
    }
    
    //MARK: UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        var numberOfSections = 0
        if let ownedElements = self.elementsCreatedByUser
        {
            if !ownedElements.isEmpty
            {
                numberOfSections += 1
            }
        }
        if let participatingElements = self.elementsUserParticipatesIn
        {
            if !participatingElements.isEmpty
            {
                numberOfSections += 1
            }
        }
        
        return numberOfSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let elements = elementsForSection(section)
        {
            return elements.count
        }
        
        return 0
    }
    
    func elementsForSection(section:Int) -> [DBElement]?
    {
        if selectedFilterOption == .Task
        {
            switch section
            {
            case 0:
                if self.elementsUserParticipatesIn != nil && elementsUserParticipatesIn?.count > 0
                {
                    return self.elementsUserParticipatesIn
                }
                else
                {
                    return self.elementsCreatedByUser
                }
            case 1:
                return self.elementsCreatedByUser
            default:
                return nil
            }
        }
        else
        {
            switch section
            {
            case 0:
                if self.elementsCreatedByUser != nil && elementsCreatedByUser?.count > 0
                {
                    return self.elementsCreatedByUser
                }
                else
                {
                    return self.elementsUserParticipatesIn
                }
            case 1:
                return self.elementsUserParticipatesIn
            default:
                return nil
            }
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if selectedFilterOption == .Task //when displaying elements by TASK filter, we show PArticipating elements first
        {
            if let elements = elementsForSection(section)
            {
                if elements == self.elementsCreatedByUser!
                {
                    return "responsible".localizedWithComment("")
                }
                else
                {
                    return "creator".localizedWithComment("")
                }
            }
        }
        else
        {
            if let elements = elementsForSection(section)
            {
                if elements == self.elementsCreatedByUser!
                {
                    return "creator".localizedWithComment("")
                }
                else
                {
                    return "participant".localizedWithComment("")
                }
            }
        }
        return nil
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section < 2
        {
            if let _ = self.tableView(tableView, titleForHeaderInSection: section)
            {
                return 50.0
            }
        }
        return 0.0
    }

    //MARK: - right nav button
    func configureCurrentRightTopButton()
    {
        let rightButton = UIButton(type:.System)//UIButton.buttonWithType(.System) as! UIButton
        rightButton.backgroundColor = UIColor.clearColor()
        
        rightButton.frame = CGRectMake(0.0, 0.0, 45.0, 45.0)
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(4,4,4,4)
        rightButton.imageView?.contentMode = .ScaleAspectFill
        rightButton.maskToCircle()
        rightButton.setImage(self.currentSelectedUserAvatar, forState: .Normal)
        rightButton.addTarget(self, action: "selectElementsOwnerTapped:", forControlEvents: .TouchUpInside)
     
       
        self.currentTopRightButton = rightButton
        
        let rightBarButton = UIBarButtonItem(customView: self.currentTopRightButton!)
        
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func configureCurrentRightButtonImage()
    {
        guard let userIdExists = DataSource.sharedInstance.user?.userId else {
            return
        }
        
        if selectedUserId == 0
        {
            selectedUserId = userIdExists
        }
        
        let userId = selectedUserId
        
        dispatch_async(getBackgroundQueue_CONCURRENT(), {[weak self] () -> Void in
            
            
            var userAvatar = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            if let avatarPreviewImage = DataSource.sharedInstance.getAvatarForUserId(userId)
            {
                userAvatar = avatarPreviewImage.imageWithRenderingMode(.AlwaysOriginal)
            }
            
            guard let weakSelf = self else
            {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                weakSelf.currentSelectedUserAvatar = userAvatar
                weakSelf.configureCurrentRightTopButton()
            })
        })
            
        
    }
    
    func selectElementsOwnerTapped(sender:AnyObject)
    {
       DataSource.sharedInstance.localDatadaseHandler?.readAllMyContacts() {[weak self] (myContacts) -> () in
        if let weakSelf = self
        {
            dispatch_async(dispatch_get_main_queue()) { _ in
                if let contactsPicker = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("ContactsPickerVC") as? ContactsPickerVC
                {
                    contactsPicker.delegate = weakSelf
                    contactsPicker.contactsToSelectFrom = myContacts
                    weakSelf.navigationController?.pushViewController(contactsPicker, animated: true)
                }
            }
        }
        
        }
    }
    
    //MARK: - TableItemPickerDelegate
    func itemPickerDidCancel(itemPicker: AnyObject)
    {
       
        if let aUserID = DataSource.sharedInstance.user?.userId
        {
            if self.selectedUserId != aUserID
            {
                self.selectedUserId = aUserID// NSNumber(integer: aNumber.integerValue)
                self.configureCurrentRightButtonImage()
            }
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject)
    {
        if let aContact = item as? DBContact, contactId = aContact.contactId?.integerValue
        {
            if self.selectedUserId != contactId
            {
                self.selectedUserId = contactId
                self.configureCurrentRightButtonImage()
            }
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK: - Top Controllls actions
    //MARK: Archived / Normal
    @IBAction func segmentedControlDidChange(sender:UISegmentedControl)
    {
        if sender == self.filterSegmentedControl
        {
            switch sender.selectedSegmentIndex
            {
            case 0: //all elements
                selectedFilterOption = .ReservedValue1
            case 1: // signals
                selectedFilterOption = .ReservedValue2
            case 2: //ideas
                selectedFilterOption = .Idea
            case 3: // tasks
                selectedFilterOption = .Task
            case 4:
                selectedFilterOption = .Decision
            default:
                selectedFilterOption = .ReservedValue1
            }
        }
        self.startLoadingElementsByActivity {[weak self] ()->() in
            if let weakSelf = self
            {
                weakSelf.reloadTableView()
            }
        } // will reload tableView and dismiss activity indicator
    }
    
    //MARK: Filter by type
    func filterButtonTapped(sender:FilterAttributeButton)
    {
        sender.toggleType = sender.toggleType.toggleToOpposite()
    }
    
    func refreshFilteredData()
    {
        self.tableView?.userInteractionEnabled = false
    }
    
    
    func setLoadingIndicatorVisible(visible:Bool)
    {
        if visible
        {
            if let indicator = self.view.viewWithTag(0x70AD) as? UIActivityIndicatorView
            {
                if indicator.isAnimating()
                {
                    return //already showing
                }
                else
                {
                    indicator.startAnimating()
                }
                return
            }
            
            let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
            indicatorView.tag = 0x70AD
            let frame = CGRectMake(0, 0, 200.0, 200.0)
            indicatorView.frame = frame
            indicatorView.layer.cornerRadius = 7.0
            indicatorView.backgroundColor = kBlackColor.colorWithAlphaComponent(0.7)
            indicatorView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
            indicatorView.autoresizingMask =  [.FlexibleLeftMargin , .FlexibleRightMargin , .FlexibleTopMargin , .FlexibleBottomMargin]
            self.view.addSubview(indicatorView)
            indicatorView.startAnimating()
        }
        else
        {
            if let indicator = self.view.viewWithTag(0x70AD) as? UIActivityIndicatorView
            {
                indicator.stopAnimating()
            }
        }
    }
}
