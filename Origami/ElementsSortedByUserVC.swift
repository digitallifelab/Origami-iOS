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
    var elementsCreatedByUser:[Element]?
    var elementsUserParticipatesIn:[Element]?
    var selectedUserId:Int = 0
    
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
    
    var archivedVisible = false{
        didSet{
            if archivedVisible
            {
                
            }
            else
            {
                
            }
        }
    }
    
    var ideasFilterEnabled = false
    var signalsFilterEnabled = false
    var tasksFilterEnabled = false
    var decisionsFilterEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let userId = DataSource.sharedInstance.user?.userId
        {
           
            if let anImage = DataSource.sharedInstance.getAvatarForUserId(userId)
            {
                if selectedUserId == userId
                {
                    currentSelectedUserAvatar = anImage
                }
            }

//            configureCurrentRightButtonImage()
        }
        
        configureCurrentRightTopButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureTopToolbarItems()
    }
    
    override func viewDidAppear(animated: Bool) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.signalsFilterEnabled = false
        self.ideasFilterEnabled = false
        self.tasksFilterEnabled = false
        self.decisionsFilterEnabled = false
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.removeGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        super.viewWillDisappear(animated)
        
    }
    
    override func startLoadingElementsByActivity(completion:(()->())?) {
        
        self.setLoadingIndicatorVisible(true)
        isReloadingTable = true
        print(" -> Getting all elements By Activity from DataSource... ")
        DataSource.sharedInstance.getAllElementsSortedByActivity { [weak self] (elements) -> () in
            if let weakSelf = self
            {
                if let elementsPresent = elements
                {
                    let archVisibleLocal = weakSelf.archivedVisible
                    let bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                    dispatch_async(bgQueue, {[weak self] () -> Void in
                        var allCurrentElements = [Element]()
                        if archVisibleLocal
                        {
                            if let archived = ObjectsConverter.filterArchiveElements(true, elements: elementsPresent)
                            {
                                allCurrentElements += archived
                            }
                        }
                        else
                        {
                            if let allWithoutArchived = ObjectsConverter.filterArchiveElements(false, elements: elementsPresent)
                            {
                                allCurrentElements += allWithoutArchived
                            }
                        }
                        
                        if let weakerSelf = self
                        {
                            //TODO:_ Switch to DBElements
                            //weakerSelf.elements = allCurrentElements
                            if weakerSelf.selectedUserId > 0  //sort elements by currently selected user
                            {
                                print(" -> Sorting all elements - sortCurrentElementsForNewUserId()")
                                weakSelf.sortCurrentElementsForNewUserId()
                            }
                        }
                        
                        weakSelf.checkFiltersEnabled()
                        
                        dispatch_async(dispatch_get_main_queue(), {() -> Void in
                                    completion?()
                        })//end of main_queue
                        
                    }) //end of bgQue
                }
            }
        }
    }
    
    func sortCurrentElementsForNewUserId()
    {
        self.elementsCreatedByUser?.removeAll(keepCapacity: false)
        self.elementsUserParticipatesIn?.removeAll(keepCapacity: false)
        self.elementsCreatedByUser = nil
        self.elementsUserParticipatesIn = nil      
        let currentSelectedUserId = self.selectedUserId
        print("\nSorting for selected user ID: \(currentSelectedUserId)")
        guard let allElements = self.elements else
        {
            isReloadingTable = false
            return
        }
    
        guard let userIDFromDataSource = DataSource.sharedInstance.user?.userId else {
            return
        }
        
        var toSortOwnedElements = Set<Element>()
        var toSortParticipatingElements = Set<Element>()
        
        for anElement in allElements
        {
            //TODO: ----
//            //print("Creator: \(anElement.creatorId)")
//            if anElement.creatorId == currentSelectedUserId
//            {
//                toSortOwnedElements.insert(anElement)
//            }
//            else
//            {
//                //print("PassWhomIDs: \(anElement.passWhomIDs)")
//                if userIDFromDataSource == currentSelectedUserId
//                {
//                    toSortParticipatingElements.insert(anElement)
//                }
//                else if anElement.passWhomIDs.count > 0
//                {
//                    let passIDsSet = Set(anElement.passWhomIDs)
//                    
//                    if passIDsSet.contains(currentSelectedUserId)
//                    {
//                        toSortParticipatingElements.insert(anElement)
//                    }
//                }
//            }
        }
        
        var sortedMyElements = Array(toSortOwnedElements)
        ObjectsConverter.sortElementsByDate(&sortedMyElements)
        
        var sortedParticipatingElements = Array(toSortParticipatingElements)
        ObjectsConverter.sortElementsByDate(&sortedParticipatingElements)
        
        if sortedMyElements.count > 0
        {
            self.elementsCreatedByUser = sortedMyElements
        }
        if sortedParticipatingElements.count > 0
        {
            self.elementsUserParticipatesIn = sortedParticipatingElements
        }
        
        
        isReloadingTable = false
    }
    
    override func configureNavigationControllerToolbarItems() {
        super.configureNavigationControllerToolbarItems()
        configureNavigationControllerNavigationBarButtonItems()
    }
    
    func configureTopToolbarItems()
    {
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        //let imageInsets = UIEdgeInsetsMake(4, 4, 4, 4)
        
        let signalButton =  FilterAttributeButton(type:.System) //as! FilterAttributeButton
        if self.signalsFilterEnabled
        {
            signalButton.toggleType = .ToggledOn(filterType: .Signal)
        }
        else
        {
            signalButton.toggleType = .ToggledOff(filterType: .Signal)
        }
        signalButton.frame = CGRectMake(0, 0, 44, 44)
        signalButton.setImage(UIImage(named: "icon-signal")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        signalButton.addTarget(self, action: "filterButtonTapped:", forControlEvents: .TouchUpInside)
        let signalBarItem = UIBarButtonItem(customView: signalButton)
        
        //
        let ideaButton = FilterAttributeButton(type:.System) //as! FilterAttributeButton
        if self.ideasFilterEnabled
        {
            ideaButton.toggleType = .ToggledOn(filterType: .Idea)
        }
        else
        {
            ideaButton.toggleType = .ToggledOff(filterType: .Idea)
        }
        ideaButton.frame = CGRectMake(0, 0, 44, 44)
        ideaButton.setImage(UIImage(named: "icon-idea")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        ideaButton.addTarget(self, action: "filterButtonTapped:", forControlEvents: .TouchUpInside)
        let ideaBarItem = UIBarButtonItem(customView: ideaButton)
        
        let taskButton = FilterAttributeButton(type:.System) //as! FilterAttributeButton
        if self.tasksFilterEnabled
        {
            taskButton.toggleType = .ToggledOn(filterType: .Task)
        }
        else
        {
            taskButton.toggleType = .ToggledOff(filterType: .Task)
        }
        taskButton.frame = CGRectMake(0, 0, 44, 44)
        taskButton.setImage(UIImage(named: "task-available-to-set")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        taskButton.addTarget(self, action: "filterButtonTapped:", forControlEvents: .TouchUpInside)
        let taskBarItem = UIBarButtonItem(customView: taskButton)
        
        let decisionButton = FilterAttributeButton(type:.System) //FilterAttributeButton.buttonWithType(.System) as! FilterAttributeButton
        if self.decisionsFilterEnabled
        {
            decisionButton.toggleType = .ToggledOn(filterType: .Decision)
        }
        else
        {
            decisionButton.toggleType = .ToggledOff(filterType: .Decision)
        }
        decisionButton.toggleType = .ToggledOff(filterType:.Decision)
        decisionButton.frame = CGRectMake(0, 0, 44, 44)
        decisionButton.setImage(UIImage(named: "icon-solution")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        decisionButton.addTarget(self, action: "filterButtonTapped:", forControlEvents: .TouchUpInside)
        let decisionBarItem = UIBarButtonItem(customView: decisionButton)
        
        
        self.topToolbar?.items = [signalBarItem, flexibleSpace, ideaBarItem, flexibleSpace, taskBarItem, flexibleSpace, decisionBarItem]
        
    }
    
    
    func configureNavigationControllerNavigationBarButtonItems()
    {
//        func configureLeftBarButtonItem()
//        {
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
//        }
    }
    
    //MARK: ------ menu displaying
    func menuButtonTapped(sender:AnyObject)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    //MARK: --
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var number:Int = 0
        if let elementsByUser = elementsCreatedByUser
        {
            if !elementsByUser.isEmpty
            {
                number += 1
            }
        }
        
        if let participatingElements = elementsUserParticipatesIn
        {
            if !participatingElements.isEmpty
            {
                number += 1
            }
        }
        
        return number
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tasksFilterEnabled  //when displaying elements by TASK filter, we show PArticipating elements first
        {
            switch section
            {
            case 0:
                if let elementsParticipating = elementsUserParticipatesIn
                {
                    return elementsParticipating.count
                }
                else if let elementsByUser = elementsCreatedByUser
                {
                    return elementsByUser.count
                }
                else
                {
                    return 0
                }
            case 1:
                if let elementsByUser = elementsCreatedByUser
                {
                    return elementsByUser.count
                }
                else
                {
                    return 0
                }
            default:
                return 0
            }
        }
        
        switch section
        {
        case 0:
            if let elementsByUser = elementsCreatedByUser
            {
                return elementsByUser.count
            }
            else if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating.count
            }
            else
            {
                return 0
            }
        case 1:
            if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating.count
            }
            else
            {
                return 0
            }
            
        default:
            return 0
        }
    }
    
    /*override*/ func elementForIndexPath(indexPath: NSIndexPath) -> Element? {
        if tasksFilterEnabled //when displaying elements by TASK filter, we show PArticipating elements first
        {
            switch indexPath.section
            {
            case 0:
                if let elementsParticipating = elementsUserParticipatesIn
                {
                    return elementsParticipating[indexPath.row]
                }
                else if let elementsOwned = elementsCreatedByUser
                {
                    return elementsOwned[indexPath.row]
                }
                else
                {
                    return nil
                }
            case 1:
                if let elementsOwned = elementsCreatedByUser
                {
                    return elementsOwned[indexPath.row]
                }
                else
                {
                    return nil
                }
            default:
                return nil
            }
        }
        
        switch indexPath.section
        {
        case 0:
            if let elementsByUser = elementsCreatedByUser
            {
                return elementsByUser[indexPath.row]
            }
            else if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating[indexPath.row]
            }
            else
            {
                return nil
            }
        case 1:
            if let elementsParticipating = elementsUserParticipatesIn
            {
                return elementsParticipating[indexPath.row]
            }
            else
            {
                return nil
            }
        default:
            return nil
        }
    }
    
    override func reloadTableView()
    {
        if isReloadingTable == true
        {
            return
        }
        
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.reloadData()
        
        isReloadingTable = false
        
        self.setLoadingIndicatorVisible(false)
        
        self.tableView?.userInteractionEnabled = true
        
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tasksFilterEnabled //when displaying elements by TASK filter, we show PArticipating elements first
        {
            switch section
            {
                case 0:
                    if let _ = elementsUserParticipatesIn
                    {
                        return "Participant of".localizedWithComment("")
                    }
                    else if let _ = elementsCreatedByUser
                    {
                        return "Creator of".localizedWithComment("")
                    }
                case 1:
                    if let _ = elementsCreatedByUser
                    {
                        return "Creator of".localizedWithComment("")
                    }
                default:
                    return nil
            }
            return nil
        }
        
        switch section
        {
            case 0:
                if let _ = elementsCreatedByUser
                {
                    return "Creator of".localizedWithComment("")
                }
                else if let _ = elementsUserParticipatesIn
                {
                    return "Participant of".localizedWithComment("")
                }
            case 1:
                if let _ = elementsUserParticipatesIn
                {
                    return "Participant of".localizedWithComment("")
                }
            default:
                return nil
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
        rightButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        rightButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
        rightButton.imageView?.contentMode = .ScaleAspectFit
        rightButton.setImage(self.currentSelectedUserAvatar, forState: .Normal)
        rightButton.addTarget(self, action: "selectElementsOwnerTapped:", forControlEvents: .TouchUpInside)
     
        rightButton.maskToCircle()
        self.currentTopRightButton = rightButton
        
        let rightBarButton = UIBarButtonItem(customView: self.currentTopRightButton!)
        
        self.navigationItem.rightBarButtonItem = rightBarButton
       
        configureCurrentRightButtonImage()
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
        else
        {
            var currentUserName:String?
            if selectedUserId == userIdExists
            {
                currentUserName = DataSource.sharedInstance.user?.userName //as? String
            }
            else
            {
                let aSet = Set([selectedUserId])
                if let contacts = DataSource.sharedInstance.getContactsByIds(aSet)
                {
                    let contact = contacts.first!
                    
                    currentUserName = contact.userName
                }
            }
            
            if let _ = currentUserName
            {
                let userId = selectedUserId
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), {[weak self] () -> Void in
                    
                    if let avatarPreviewImage = DataSource.sharedInstance.getAvatarForUserId(userId)
                    {
                        self?.currentSelectedUserAvatar = avatarPreviewImage
                    }
                    else
                    {
                        self?.currentSelectedUserAvatar = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                        if let weakSelf = self
                        {
                            weakSelf.currentTopRightButton?.setImage(weakSelf.currentSelectedUserAvatar, forState: .Normal)
                        }
                    })
                })
            }
        }
    }
    
    func selectElementsOwnerTapped(sender:AnyObject)
    {
        if let contactsPicker = self.storyboard?.instantiateViewControllerWithIdentifier("ContactsPickerVC") as? ContactsPickerVC
        {
            contactsPicker.delegate = self
            
            contactsPicker.contactsToSelectFrom = DataSource.sharedInstance.getMyContacts()
            
            self.navigationController?.pushViewController(contactsPicker, animated: true)
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
                
                //sortCurrentElementsForNewUserId()
                
                //self.reloadTableView()
            }
            else
            {
                isReloadingTable = false
            }
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func itemPicker(itemPicker: AnyObject, didPickItem item: AnyObject)
    {
        //self.isReloadingTable = true
      
        self.configureTopToolbarItems()
        
        if let aContact = item as? Contact
        {
             let contactId = aContact.contactId
            
            if self.selectedUserId != contactId
            {
                self.selectedUserId = contactId
                self.configureCurrentRightButtonImage()
                
                //sortCurrentElementsForNewUserId()
                //self.reloadTableView()
            }
            else
            {
                self.isReloadingTable = false
            }
            
        }
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK: - Top Controllls actions
    //MARK: Archived / Normal
    @IBAction func segmentedControlDidChange(sender:UISegmentedControl)
    {
        let currentIndex = sender.selectedSegmentIndex
        //filter archive or non archive elements to show
        if currentIndex == 1
        {
            archivedVisible = true
        }
        else if currentIndex == 0
        {
            archivedVisible = false
        }
        else
        {
            archivedVisible = false
        }
        
        self.elements?.removeAll(keepCapacity: false)
        self.elements = nil
        self.startLoadingElementsByActivity {[weak self] ()->() in if let weakSelf = self{ weakSelf.reloadTableView() }} // will reload tableView and dismiss activity indicator
        
    }
    
    //MARK: Filter by type
    func filterButtonTapped(sender:FilterAttributeButton)
    {
        sender.toggleType = sender.toggleType.toggleToOpposite()
        applyFilter(sender.toggleType)
    }
    
    func applyFilter(toggle:ToggleType)
    {
        if let _ = self.elements
        {
            switch toggle
            {
                case .ToggledOn(let type) where type == .Signal:
                    print(" enabled .Signal Filter")
                    signalsFilterEnabled = true
                    filterOutSignalsToggled()
                    self.reloadTableView()
                
                case .ToggledOn(let type) where type == .Idea:
                    print(" enabled .Idea Filter")
                    ideasFilterEnabled = true
                    filterOutElementsWithOptionsEnabled(.Idea) // Attention! passing not the same ENUM  here!
                    self.reloadTableView()
                
                case .ToggledOn(let type) where type == .Task:
                    print(" enabled .Task Filter")
                    tasksFilterEnabled = true
                    filterOutElementsWithOptionsEnabled(.Task)
                    self.reloadTableView()
                
                case .ToggledOn(let type) where type == .Decision:
                    print(" enabled .Decision Filter")
                    decisionsFilterEnabled = true
                    filterOutElementsWithOptionsEnabled(.Decision)
                    self.reloadTableView()
                
                ///---///
                case .ToggledOff(let type) where type == .Signal:
                    print(" disabled .Signal Filter")
                    signalsFilterEnabled = false
                    refreshFilteredData()
                case .ToggledOff(let type) where type == .Idea:
                    print(" disabled .Idea Filter")
                    ideasFilterEnabled = false
                    refreshFilteredData()
                case .ToggledOff(let type) where type == .Task:
                    print(" disabled .Task Filter")
                    tasksFilterEnabled = false
                    refreshFilteredData()
                case .ToggledOff(let type) where type == .Decision:
                    print(" disabled .Decision Filter")
                    decisionsFilterEnabled = false
                    refreshFilteredData()
                default:
                    break
            }
        }
    }
 
    func filterOutSignalsToggled()
    {
        if let owned = self.elementsCreatedByUser
        {
            let newOwned = owned.filter {element in return element.isSignal.boolValue}
            if !newOwned.isEmpty
            {
                self.elementsCreatedByUser = newOwned
            }
            else
            {
                self.elementsCreatedByUser = nil
            }
        }
        // sort participating if any
        if let participating = self.elementsUserParticipatesIn
        {
            let newParticipating = participating.filter { element in
                return element.isSignal.boolValue
            }
            
            if !newParticipating.isEmpty
            {
                self.elementsUserParticipatesIn = newParticipating
            }
            else
            {
                self.elementsUserParticipatesIn = nil
            }
        }
    }
    
    func filterOutElementsWithOptionsEnabled(options:ElementOptions)
    {
        if let owned = self.elementsCreatedByUser
        {
            let optionsConverter = ElementOptionsConverter()
            let newOwned = owned.filter { element in
                return optionsConverter.isOptionEnabled(options, forCurrentOptions: element.typeId)
            }
            
            if !newOwned.isEmpty
            {
                self.elementsCreatedByUser = newOwned
            }
            else
            {
                self.elementsCreatedByUser = nil
            }
        }
        // sort participating if any
        if let participating = self.elementsUserParticipatesIn
        {
            let optionsConverter = ElementOptionsConverter()
            let newParticipating = participating.filter { element in
                return optionsConverter.isOptionEnabled(options, forCurrentOptions: element.typeId)
            }
            if !newParticipating.isEmpty
            {
                self.elementsUserParticipatesIn = newParticipating
            }
            else
            {
                self.elementsUserParticipatesIn = nil
            }
        }
    }
    
    func refreshFilteredData()
    {
        self.tableView?.userInteractionEnabled = false
        //self.elements = nil

        self.startLoadingElementsByActivity {[weak self] () -> () in
            if let weakSelf = self, _ = weakSelf.elements
            {
                let bgQueue = dispatch_queue_create("com.origami.sorting.queue", DISPATCH_QUEUE_SERIAL)
                dispatch_async(bgQueue) { _ in
                    
                    weakSelf.checkFiltersEnabled()
                       
                    dispatch_async(dispatch_get_main_queue()) {[weak self] () -> Void in
                        if let anotherWeakSelf = self
                        {
                            anotherWeakSelf.reloadTableView()
                        }
                    }
                }
            }
        }
    }
    
    func checkFiltersEnabled()
    {
        if self.signalsFilterEnabled
        {
            filterOutSignalsToggled()
        }
        
        if self.ideasFilterEnabled
        {
            filterOutElementsWithOptionsEnabled(.Idea)
        }
        
        if self.tasksFilterEnabled
        {
            filterOutElementsWithOptionsEnabled(.Task)
        }
        
        if self.decisionsFilterEnabled
        {
            filterOutElementsWithOptionsEnabled(.Decision)
        }
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
