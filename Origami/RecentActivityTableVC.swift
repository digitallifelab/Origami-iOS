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
    var elements:[DBElement]?
    
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
    
    let optionsConverter = ElementOptionsConverter()
    
    let currentSystemUser = DataSource.sharedInstance.user!
    
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
                                if let idInt = anElement.creatorId?.integerValue
                                {
                                    if idInt > 0
                                    {
                                        creatorIDsSet.insert(idInt)
                                    }
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
    
    //MARK --
    
    func startLoadingElementsByActivity(completion:(()->())?)
    {
        dispatch_async(getBackgroundQueue_DEFAULT()) {[weak self] () -> Void in
            if let recentElements = DataSource.sharedInstance.localDatadaseHandler?.readRecentNonArchivedElements()
            {
                if let weakSelf = self
                {
                    weakSelf.elements = recentElements
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        weakSelf.tableView?.reloadData()
//                    })
                }
            }
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
        
        self.setToolbarItems(currentToolbarItems, animated: false)
    }
    
    func pushElementDashBoardForElement(element:DBElement)
    {
        self.view.userInteractionEnabled = false

        if let dashboard = self.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
        {
            dashboard.currentElement = element
            self.navigationController?.pushViewController(dashboard, animated: true)
        }
        self.view.userInteractionEnabled = true
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
                
                activityCell.elementTitleLabel?.text = element.title // as? String
                activityCell.elementDetailsTextView?.text = element.details //as? String
                activityCell.displayMode = self.displayMode
                
                if element.isArchived()
                {
                    activityCell.backgroundColor = UIColor.lightGrayColor()
                }
                
                //setup decision Icon Image
                if self.optionsConverter.isOptionEnabled(.Decision, forCurrentOptions: element.type!.integerValue)
                {
                    activityCell.decisionIcon?.image = UIImage(named: "tile-decision")?.imageWithRenderingMode(.AlwaysTemplate)
                }
                else
                {
                    activityCell.decisionIcon?.image = nil
                }
                
                //setup idea icon image
                if self.optionsConverter.isOptionEnabled(.Idea, forCurrentOptions: element.type!.integerValue)
                {
                    activityCell.ideaIcon?.image = UIImage(named: "tile-idea")?.imageWithRenderingMode(.AlwaysTemplate)
                }
                else
                {
                    activityCell.ideaIcon?.image = nil
                }
                
                //setup avatar, name and task Icon image depending on Task property of element
                if self.optionsConverter.isOptionEnabled(.Task, forCurrentOptions: element.type!.integerValue)
                {
                    if let finishState = ElementFinishState(rawValue: element.finishState!.integerValue)
                    {
                        switch finishState
                        {
                        case .Default:
                            activityCell.taskIcon?.image = nil
                        case .InProcess, .InProcessNoDate:
                            activityCell.taskIcon?.image = UIImage(named: "tile-task-pending")?.imageWithRenderingMode(.AlwaysTemplate)
                        case .FinishedGood, .FinishedGoodNoDate:
                            activityCell.taskIcon?.image = UIImage(named: "tile-task-good")?.imageWithRenderingMode(.AlwaysTemplate)
                        case .FinishedBad, .FinishedBadNoDate:
                            activityCell.taskIcon?.image = UIImage(named: "tile-task-bad")?.imageWithRenderingMode(.AlwaysTemplate)
                        
                        }
                    }
                    
                    //setup avatar
                    if let avatarImage = DataSource.sharedInstance.getAvatarForUserId(element.responsibleId!.integerValue)
                    {
                        activityCell.elementCreatorAvatar?.image = avatarImage
                    }
                    
                    
                    //setup NameLabel text under avatar
                    if let responsible = element.responsibleId?.integerValue, currentContact = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(responsible).db
                    {
                        activityCell.nameLabel?.text = currentContact.initialsString()
                    }
                    else if let responsibleIdInt = element.responsibleId?.integerValue, user = DataSource.sharedInstance.user,  userIdInt = user.userId
                    {
                        if userIdInt == responsibleIdInt
                        {
                            activityCell.nameLabel?.text = user.initialsString()
                        }
                    }
                }
                else //no task
                {
                    activityCell.taskIcon?.image = nil
                    if let avatar = avatarForElementHolder[element.creatorId!.integerValue]
                    {
                        activityCell.elementCreatorAvatar?.image = avatar
                    }
                    else
                    {
                        activityCell.elementCreatorAvatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
                        //and try to query avatar from ram again
                        if let creatorIdInt = element.creatorId?.integerValue
                        {
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
                        
                    }
                    
                    if let creatorId = element.creatorId?.integerValue, currentContact = DataSource.sharedInstance.localDatadaseHandler?.findPersonById(creatorId).db //contacts = DataSource.sharedInstance.getContactsByIds(Set([creatorId])), currentContact = contacts.first
                    {
                        activityCell.nameLabel?.text = currentContact.initialsString()
                    }
                    else if let user = DataSource.sharedInstance.user,  userIdInt = user.userId
                    {
                        if userIdInt == element.creatorId
                        {
                            activityCell.nameLabel?.text = user.initialsString()
                        }
                    }
                }
                
                return activityCell
            }
        }
        
        return UITableViewCell(style: .Default, reuseIdentifier: "Cell")
    }
    
    func elementForIndexPath(indexPath:NSIndexPath) -> DBElement?
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
