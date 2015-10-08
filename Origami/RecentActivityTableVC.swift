//
//  RecentActivityTableVC.swift
//  Origami
//
//  Created by CloudCraft on 10.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class RecentActivityTableVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView:UITableView?
    let kElementCellIdentifier = "ElementTableCell"
    var isReloadingTable = false {
        didSet{
            print(" ->  isReloadingTable = \(isReloadingTable)")
        }
    }
    var elements:[Element]?
    
    var avatarForElementHolder:[Int:UIImage] = [Int:UIImage]()
    
    var displayMode:DisplayMode = .Day {
        didSet {
            switch displayMode
            {
            case .Day:
                self.view.backgroundColor = kWhiteColor
            case .Night:
                self.view.backgroundColor = kBlackColor
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.backgroundColor = UIColor.clearColor()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //black or
        self.displayMode = NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey) ? .Night : .Day
        configureNavigationControllerToolbarItems()
        
        startLoadingElementsByActivity {[weak self] () -> () in
            if let weakSelf = self
            {
                weakSelf.reloadTableView()
                if let _ = weakSelf.elements
                {
                    let bgQueue = dispatch_queue_create("com.Origami.AvatarsQuery.queue", DISPATCH_QUEUE_SERIAL)
                    dispatch_async(bgQueue, {[weak self] () -> Void in
                        if let weakerSelf = self, elementsForBgQueue = weakerSelf.elements
                        {
                            var creatorIDsSet = Set<Int>()
                            //1 insert creatorIDs
                            for anElement in elementsForBgQueue
                            {
                                let idInt = anElement.creatorId.integerValue
                                if idInt > 0
                                {
                                    creatorIDsSet.insert(idInt)
                                }
                            }
                            
                            //2 try to get avatars
                            if !creatorIDsSet.isEmpty
                            {
                                for anId in creatorIDsSet
                                {
                                    if let avatar = DataSource.sharedInstance.getAvatarForUserId(anId)
                                    {
                                        weakSelf.avatarForElementHolder[anId] = avatar
                                    }
                                }
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if let visibleRowsPaths = weakerSelf.tableView?.indexPathsForVisibleRows//? // as? [NSIndexPath]
                                {
                                    weakerSelf.tableView?.reloadRowsAtIndexPaths(visibleRowsPaths, withRowAnimation: .None)
                                }
                            })
                        }
                     
                    }) //bg queue end
                }

            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _ = self.elements
        {
            if !isReloadingTable
            {
                self.reloadTableView()
            }
        }
    }
    
//    override func viewWillDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
////        self.tableView?.delegate = nil
////        self.tableView?.dataSource = nil
////        self.elements = nil
//    }
    
    //MARK --
    
    func startLoadingElementsByActivity(completion:(()->())?)
    {
        DataSource.sharedInstance.getAllElementsSortedByActivity { [weak self] (elements) -> () in
            let bgQueue = dispatch_queue_create("filter.queue", DISPATCH_QUEUE_SERIAL)
            dispatch_async(bgQueue, { () -> Void in
                if let elementsToFilter = elements
                {
                    let withoutArchived = ObjectsConverter.filterArchiveElements(false, elements: elementsToFilter)
                    if let weakSelf = self
                    {
                        if !weakSelf.isReloadingTable
                        {
                            weakSelf.elements = withoutArchived
                            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                                if let _ = self
                                {
                                    completion?()
                                }
                            })
                        }
                        else
                        {
                            let timeout:dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * 0.5))
                            dispatch_after(timeout, dispatch_get_main_queue(), { [weak self]() -> Void in
                                if let weakSelf = self
                                {
                                    weakSelf.elements = withoutArchived
                                    completion?()
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    func reloadTableView()
    {
        isReloadingTable = true
      
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.reloadData()

        isReloadingTable = false
    }
    
    func configureNavigationControllerToolbarItems()
    {
        switch displayMode
        {
        case .Day:
            setAppearanceForNightModeToggled(false)
        case .Night:
            setAppearanceForNightModeToggled(true)
            
        }
        
        
        let homeButton = UIButton(type: .System)
        homeButton.setImage(UIImage(named: kHomeButtonImageName)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        homeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        homeButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        homeButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        homeButton.addTarget(self, action: "homeButtonPressed:", forControlEvents: .TouchUpInside) //in extension to UIViewController
        
        let homeImageButton = UIBarButtonItem(customView: homeButton)
        
        let flexibleSpaceLeft = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let flexibleSpaceRight = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        let currentToolbarItems:[UIBarButtonItem] = [flexibleSpaceLeft, homeImageButton ,flexibleSpaceRight]
        
        //
        self.setToolbarItems(currentToolbarItems, animated: false)
    }
    
//    func homeButtonPressed(sender:UIBarButtonItem)
//    {
//        if let currentVCs = self.navigationController?.viewControllers
//        {
//            if currentVCs.count > 1
//            {
//                if let rootIsHome = currentVCs.first as? HomeVC
//                {
//                    self.navigationController?.popToRootViewControllerAnimated(true)
//                }
//                else
//                {
//                    if let home = self.storyboard?.instantiateViewControllerWithIdentifier("HomeVC") as? HomeVC
//                    {
//                        self.navigationController?.setViewControllers([home], animated: true)
//                    }
//                }
//            }
//            else
//            {
//                if let home = self.storyboard?.instantiateViewControllerWithIdentifier("HomeVC") as? HomeVC
//                {
//                    self.navigationController?.setViewControllers([home], animated: true)
//                }
//            }
//        }
//    }
    
    func pushElementDashBoardForElement(element:Element)
    {
        self.view.userInteractionEnabled = false
//            DataSource.sharedInstance.loadAttachesInfoForElement(element, completion: {[weak self] (_) -> () in
//                if let weakSelf = self
//                {
                    if let dashboard = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                    {
                        dashboard.currentElement = element
                        self.navigationController?.pushViewController(dashboard, animated: true)
                    }
                    self.view.userInteractionEnabled = true
//                }
//            })
    }
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let elements = self.elements
        {
            return elements.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let activityCell = tableView.dequeueReusableCellWithIdentifier(kElementCellIdentifier, forIndexPath: indexPath) as? RecentActivityTableCell
        {
            if let element = elementForIndexPath(indexPath)
            {
                if let changeDateString = element.lastChangeDateReadableString()
                {
                    activityCell.dateLabel?.text = changeDateString
                }
                else if let createDateString = element.creationDateReadableString(shouldEvaluateCurrentDay: true)
                {
                    activityCell.dateLabel?.text = createDateString
                }
                else
                {
                    activityCell.dateLabel?.text = nil
                }
                
                activityCell.elementTitleLabel?.text = element.title as? String
                activityCell.elementDetailsTextView?.text = element.details as? String
                activityCell.displayMode = self.displayMode
                if element.isArchived()
                {
                    activityCell.backgroundColor = UIColor.lightGrayColor()
                }
                if let avatar = avatarForElementHolder[element.creatorId.integerValue]
                {
                    activityCell.elementCreatorAvatar?.image = avatar
                }
                else
                {
                    activityCell.elementCreatorAvatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
                    //and try to query avatar from ram again
                    let creatorIdInt = element.creatorId.integerValue
                    if creatorIdInt > 0
                    {
                        let bgQueue = dispatch_queue_create("com.origami.Cell.For.IndexPath.Queue", DISPATCH_QUEUE_SERIAL)
                        dispatch_async(bgQueue, {[weak self] () -> Void in
                            if let imageAvatar = DataSource.sharedInstance.getAvatarForUserId(creatorIdInt)
                            {
                                if let aSelf = self
                                {
                                    aSelf.avatarForElementHolder[creatorIdInt] = imageAvatar
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        aSelf.tableView?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                                    })
                                }
                            }
                        })
                    }
                }
                
                if let contacts = DataSource.sharedInstance.getContactsByIds(Set([element.creatorId.integerValue])), currentContact = contacts.first
                {
                    activityCell.nameLabel?.text = currentContact.initialsString()
                }
                else if let user = DataSource.sharedInstance.user,  userIdInt = user.userId?.integerValue
                {
                    if userIdInt == element.creatorId.integerValue
                    {
                        activityCell.nameLabel?.text = user.initialsString()
                    }
                }
                
                return activityCell
            }
        }
        
        return UITableViewCell(style: .Default, reuseIdentifier: "Cell")
    }
    
    func elementForIndexPath(indexPath:NSIndexPath) -> Element?
    {
        if let element = elements?[indexPath.row]
        {
            return element
        }
        return nil
    }
    
    //MARK: UITableViewDelegate
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 110.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let element = elementForIndexPath(indexPath)
        {
            pushElementDashBoardForElement(element)
        }
    }
}
