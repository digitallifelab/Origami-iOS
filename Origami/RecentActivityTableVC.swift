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
    var isReloadingTable = false
    var elements:[Element]?
    var displayMode:DisplayMode = .Day{
        didSet{
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
        
        startLoadingElementsByActivity()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let elements = self.elements
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
    
    func startLoadingElementsByActivity()
    {
        DataSource.sharedInstance.getAllElementsSortedByActivity { [weak self] (elements) -> () in
            if let weakSelf = self
            {
                weakSelf.elements = elements
                if !weakSelf.isReloadingTable
                {
                    weakSelf.reloadTableView()
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
        
        
        let homeButton = UIButton.buttonWithType(.System) as! UIButton
        homeButton.setImage(UIImage(named: "icon-home-SH")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        homeButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        homeButton.frame = CGRectMake(0, 0, 44.0, 44.0)
        homeButton.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        homeButton.addTarget(self, action: "homeButtonPressed:", forControlEvents: .TouchUpInside)
        
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
            DataSource.sharedInstance.loadAttachesForElement(element, completion: {[weak self] (_) -> () in
                if let weakSelf = self
                {
                    if let dashboard = weakSelf.storyboard?.instantiateViewControllerWithIdentifier("SingleElementDashboardVC") as? SingleElementDashboardVC
                    {
                        dashboard.currentElement = element
                        weakSelf.navigationController?.pushViewController(dashboard, animated: true)
                    }
                    weakSelf.view.userInteractionEnabled = true
                }
            })
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
                activityCell.elementTitleLabel?.text = element.title as? String
                activityCell.elementDetailsTextView?.text = element.details as? String
                activityCell.displayMode = self.displayMode
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
        return 100.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let element = elementForIndexPath(indexPath)
        {
            pushElementDashBoardForElement(element)
        }
    }
}
