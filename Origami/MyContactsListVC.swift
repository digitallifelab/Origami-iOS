//
//  ContactsListVC.swift
//  Origami
//
//  Created by CloudCraft on 15.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit
import CoreData
class MyContactsListVC: UIViewController , UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var myContactsTable:UITableView?
    
    var myContacts:[DBContact]?

    var contactsSearchButton:UIBarButtonItem?
    var contactImages = [String:UIImage]()
    var currentSelectedContactsIndex:Int = 0
    
    var segmentedControl:UISegmentedControl?
    var searchBar:UISearchBar?
    
    var allContactsFetchController:NSFetchedResultsController?
    var favContactsFetchController:NSFetchedResultsController?
    var contactsFetchRequest = NSFetchRequest(entityName: "DBContact")
    
    var localMainContext:NSManagedObjectContext?
    
    var currentFetchController:NSFetchedResultsController?
    
    var displayMode:DisplayMode = .Day
    
    //MARK:----
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        configureSearchBar()
        
        // Do any additional setup after loading the view.
        setAppearanceForNightModeToggled(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
        configureNavigationItems()
        configureNavigationControllerToolbarItems()
        
        self.localMainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        if let dbHandler = DataSource.sharedInstance.localDatadaseHandler, mainQueueContext = self.localMainContext
        {
            mainQueueContext.parentContext = dbHandler.getPrivateContext()
            //mainQueueContext.undoManager = NSUndoManager()
            
            let lastNameSort = NSSortDescriptor(key: "lastName", ascending: true)
            contactsFetchRequest.sortDescriptors = [lastNameSort]
            self.allContactsFetchController = NSFetchedResultsController(fetchRequest: contactsFetchRequest, managedObjectContext: mainQueueContext, sectionNameKeyPath: nil, cacheName: nil)
            
            let favContactsRequest = NSFetchRequest(entityName: "DBContact")
            favContactsRequest.sortDescriptors = [lastNameSort]
            favContactsRequest.predicate = NSPredicate(format: "favorite = true")
            
            self.favContactsFetchController = NSFetchedResultsController(fetchRequest: favContactsRequest, managedObjectContext: mainQueueContext, sectionNameKeyPath: nil, cacheName: nil)
            
            self.currentFetchController = self.allContactsFetchController
            self.currentFetchController?.delegate = self
        }
        
        myContactsTable?.estimatedRowHeight = 60
        myContactsTable?.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        do {
            try self.currentFetchController?.performFetch()
        }
        catch{
            
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.addGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, rootVC = appDelegate.rootViewController as? RootViewController
        {
            self.view.removeGestureRecognizer(rootVC.screenEdgePanRecognizer)
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kContactFavouriteButtonTappedNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        
        if let searchingBar = searchBar
        {
            searchBarCancelButtonClicked(searchingBar)
        }
        
        super.viewDidDisappear(animated)
    }
    
    /**
     
     Sets night or day mode to the whole app – the tint and background color of navigation bar and toolbar items, and also the background color of viewcontroller`s view
     
     - nightModeOn: *false* means .Day, *true* means .Night
     */
    override func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.toolbar.translucent = false
        
        if nightModeOn
        {
            self.navigationController?.navigationBar.barStyle = UIBarStyle.Default
            self.navigationController?.navigationBar.barTintColor = kBlackColor
            self.view.backgroundColor = kBlackColor
            self.navigationController?.toolbar.tintColor = kWhiteColor
            self.navigationController?.toolbar.barTintColor = kBlackColor
            self.displayMode = .Night
        }
        else
        {
            self.navigationController?.navigationBar.barStyle = UIBarStyle.Default
            self.navigationController?.navigationBar.barTintColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.4)
            self.view.backgroundColor = kWhiteColor
            self.navigationController?.toolbar.tintColor = kWhiteColor
            self.navigationController?.toolbar.barTintColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.5)
            self.displayMode = .Day
        }
    }
    
    
    func configureNavigationItems()
    {
        #if SHEVCHENKO
        #else
            let lvMethodSignatureString:Selector = "showContactSearchVC"
            contactsSearchButton = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: lvMethodSignatureString)
            contactsSearchButton?.enabled = true
        #endif
        
        self.navigationItem.rightBarButtonItem = contactsSearchButton
        
        let segmentedControl = UISegmentedControl(items: ["All".localizedWithComment(""), "Favorite".localizedWithComment("")])
        segmentedControl.selectedSegmentIndex = 0
        currentSelectedContactsIndex = segmentedControl.selectedSegmentIndex
        segmentedControl.addTarget(self, action: "contactsFilterDidChange:", forControlEvents: UIControlEvents.ValueChanged)
        self.segmentedControl = segmentedControl
        self.navigationItem.titleView = segmentedControl

        
        configureLeftBarButtonItem()
    }
    
    func configureLeftBarButtonItem()
    {
        let leftButton = UIButton(type:.System)
        leftButton.frame = CGRectMake(0.0, 0.0, 44.0, 40.0)
        leftButton.imageEdgeInsets = UIEdgeInsetsMake(4, -8, 4, 24)
        leftButton.setImage(UIImage(named: "icon-options")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        leftButton.addTarget(self, action: "menuButtonTapped:", forControlEvents: .TouchUpInside)
        
        let leftBarButton = UIBarButtonItem(customView: leftButton)
        
        self.navigationItem.leftBarButtonItem = leftBarButton
    }
    
    func configureNavigationControllerToolbarItems()
    {
        let homeButton = UIButton(type:.System)

        homeButton.setImage(UIImage(named: kHomeButtonImageName)?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
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
    
    func configureSearchBar()
    {
        let aSearchBar = UISearchBar(frame: CGRectMake(0.0, 0.0, self.view.bounds.size.width, 50.0))
        myContactsTable?.tableHeaderView = aSearchBar
        aSearchBar.sizeToFit()
        aSearchBar.delegate = self
        aSearchBar.tintColor = kDayNavigationBarBackgroundColor
        aSearchBar.searchBarStyle = .Minimal
        self.searchBar = aSearchBar
    }
    
    //MARK: ------ menu displaying
    func menuButtonTapped(sender:AnyObject)
    {
        if let searchingBar = searchBar
        {
            searchBarCancelButtonClicked(searchingBar)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(kMenu_Buton_Tapped_Notification_Name, object: nil)
    }
    //MARK: ---
    #if SHEVCHENKO
    #else
    func showContactSearchVC()
    {
        guard let searcherVC = self.storyboard?.instantiateViewControllerWithIdentifier("ContactSearchVC") as? ContactSearchVC else
        {
            return
        }
        searcherVC.delegate = self
        self.navigationController?.pushViewController(searcherVC, animated: true)
    }
    #endif
    
    
    //MARK: current VC

    func contactsFilterDidChange(sender:UISegmentedControl)
    {
        if let bar = self.searchBar where bar.showsCancelButton
        {
            searchBarCancelButtonClicked(bar)
            return
        }
        
        currentSelectedContactsIndex = sender.selectedSegmentIndex
        switch currentSelectedContactsIndex{
        case 0:
            self.currentFetchController = self.allContactsFetchController
        case 1:
            self.currentFetchController = self.favContactsFetchController
        default:
            break
        }
        
        self.currentFetchController?.delegate = self
        
        do
        {
            try self.currentFetchController?.performFetch()
            
            self.myContactsTable?.reloadData()
        }
        catch let fetchError
        {
            print("Fetched results controller did fail to fetch:")
            print(fetchError)
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let contactProfileVC = self.storyboard?.instantiateViewControllerWithIdentifier("ContactProfileVC") as? ContactProfileVC
        {
            if let contact = self.contactForIndexPath(indexPath)
            {
                contactProfileVC.contactManagedId = contact.objectID
            }
            self.navigationController?.pushViewController(contactProfileVC, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 67.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let contact = contactForIndexPath(indexPath)
        {
            let contactName = contact.nameAndLastNameSpacedString()!
            
            let mainFrameWidth = UIScreen.mainScreen().bounds.size.width
            let nameFrame = contactName.boundingRectWithSize(CGSizeMake(mainFrameWidth - (8 + 40 + 8 + 40), CGFloat(FLT_MAX) ), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 17.0)!], context: nil)
            
            var moodFrame = CGRectZero
            if let contactMood = contact.mood
            {
                moodFrame = contactMood.boundingRectWithSize(CGSizeMake(mainFrameWidth - (8 + 40 + 8 + 40), CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName:UIFont(name: "SegoeUI", size: 14.0)!], context: nil)
            }
            
            let verticalConstraints:CGFloat = 8 + 1 + 16
            let labelFrameHeights = nameFrame.size.height + moodFrame.size.height
            
           
            
            let toReturnHeight = ceil( labelFrameHeights + verticalConstraints )
            if toReturnHeight > 67.0
            {
                return toReturnHeight
            }
        }
        return 67.0
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
    {
        if let tappedContact = self.contactForIndexPath(indexPath), contactId = tappedContact.contactId?.integerValue
        {
            let newValue = !tappedContact.favorite!.boolValue
            
            let objectId = tappedContact.objectID
            DataSource.sharedInstance.updateContactIsFavourite(contactId) {[weak self] (success, error) -> () in
                if success
                {
                    if let weakSelf = self, contactToChange = weakSelf.localMainContext?.objectWithID(objectId) as? DBContact //weakSelf.contactForIndexPath(indexPath)
                    {
                        contactToChange.favorite = NSNumber(bool: newValue)
                        do{
                            try weakSelf.localMainContext?.save()
                        }
                        catch let saveError{
                            print("Did not save Contacts Main queue context:")
                            print(saveError)
                        }
                        
                        guard let _ = weakSelf.currentFetchController?.delegate else
                        {
                            weakSelf.currentFetchController?.delegate = weakSelf
                            do
                            {
                                try weakSelf.currentFetchController?.performFetch()
                            }
                            catch let fetchError
                            {
                                print("\n ->  Error while refetching during favourite attribute changed:")
                                print(fetchError)
                            }
                            return
                        }

                    }
                }
            }
        }
    }

    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let currentFetchController = self.currentFetchController, objects = currentFetchController.fetchedObjects
        {
            return objects.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let contactCell = tableView.dequeueReusableCellWithIdentifier("MyContactCell", forIndexPath: indexPath) as! MyContactListCell
        contactCell.selectionStyle = .None
        
        configureCell(contactCell, forIndexPath:indexPath)
        return contactCell
    }
    
    private func configureCell(cell: MyContactListCell, forIndexPath indexPath:NSIndexPath)
    {
        cell.displayMode = self.displayMode
        if let contact = contactForIndexPath(indexPath)
        {
            //name field
            cell.nameLabel.text = contact.nameAndLastNameSpacedString()
            
            // mood field
            cell.moodLabel?.text = contact.mood
            
            //favourite
            if contact.favorite!.boolValue
            {
                cell.favouriteButton.tintColor = kDaySignalColor
            }
            else
            {
                cell.favouriteButton.tintColor = UIColor.lightGrayColor()
            }
            cell.favouriteButton.tag = indexPath.row
            
            //avatar
           
            if let avatarImage = DataSource.sharedInstance.getAvatarForUserId(contact.contactId!.integerValue)
            {
                cell.avatar?.image = avatarImage
            }
            else
            {
                cell.avatar?.image = UIImage(named: "icon-contacts")?.imageWithRenderingMode(.AlwaysTemplate)
            }
        }
        
    }
    
    private func contactForIndexPath(indexPath:NSIndexPath) -> DBContact?
    {
        let row = indexPath.row
        
        guard let
            currentFetchController = self.currentFetchController,
            objects = currentFetchController.fetchedObjects as? [DBContact] where objects.count > row else
        {
            return nil
        }
        
        return objects[row]
    }
    
    private func contactNameStringFromContact(contact:Contact) -> String
    {
        var nameString = ""
        if let firstName = contact.firstName// as? String
        {
            nameString += firstName
        }
        if let lastName = contact.lastName// as? String
        {
            if nameString.isEmpty
            {
                nameString = lastName
            }
            else
            {
                nameString += (" " + lastName)
            }
        }
        
        return nameString
    }
    
    //MARK: - NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        myContactsTable?.beginUpdates()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        myContactsTable?.endUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        if controller !== self.currentFetchController
        {
            return
        }
        
        switch type
        {
            case .Update:
                
                var shouldUpdateNewPath = true
                if let indPath = indexPath
                {
                    shouldUpdateNewPath = false
                    myContactsTable?.reloadRowsAtIndexPaths([indPath], withRowAnimation: .None)
                }
                if let newPath = newIndexPath
                {
                    if shouldUpdateNewPath
                    {
                        myContactsTable?.reloadRowsAtIndexPaths([newPath], withRowAnimation: .None)
                    }
                }
            case .Delete:
                if let inPath = indexPath
                {
                    myContactsTable?.deleteRowsAtIndexPaths([inPath], withRowAnimation: .Left)
                }
            case .Insert:
                if let newPath = newIndexPath
                {
                    myContactsTable?.insertRowsAtIndexPaths([newPath], withRowAnimation: .Right)
                }
                if let inPath = indexPath
                {
                    myContactsTable?.insertRowsAtIndexPaths([inPath], withRowAnimation: .Right)
                }
            case .Move:
                myContactsTable?.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
         
        }
    }
    /**
     Method is tied to reussable table view cell in storyboard to determine whith indexPath tapped to switch contact Favourite/UnFavourite
     */
    @IBAction func favouriteDiscrosureButtonTapped(sender:UIButton, event:UIEvent)
    {
        guard let touch = event.allTouches()?.first else
        {
            return
        }
        
        let location = touch.locationInView( self.myContactsTable)
        
        guard let indexPathTouched = self.myContactsTable?.indexPathForRowAtPoint(location) else
        {
            return
        }
        
        //calling delegate method
        self.tableView(myContactsTable!, accessoryButtonTappedForRowWithIndexPath: indexPathTouched)
    }
    
    
    #if SHEVCHENKO
    #else
    //MARK: - ContactsSearcherDelegate
    func contactsSearcher(searcher:ContactSearchVC, didFindContact:Contact, willDismiss:Bool)
    {
        defer
        {
            if willDismiss
            {
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        
        let backOperation = NSBlockOperation() {
            guard let recievedUserId = didFindContact.userId else
            {
                return
            }
            
            if let _ = DataSource.sharedInstance.localDatadaseHandler?.readContactById(recievedUserId)
            {
                return
            }
            else
            {
                DataSource.sharedInstance.localDatadaseHandler?.saveContactsToDataBase([didFindContact], completion: { (saved, error) -> () in
                    if saved
                    {
                        dispatch_async(dispatch_get_main_queue()){[weak self] in
                            if let weakSelf = self
                            {
                                do{
                                    try weakSelf.currentFetchController?.performFetch()
                                    //weakSelf.myContactsTable?.reloadData()
                                }
                                catch{}
                            }
                        }
                    }
                    else
                    {
                        
                    }
                })
            }
        }
        
        NSOperationQueue().addOperation(backOperation)
    }
    
    func contactsSearcherDidCancelSearch(searcher:ContactSearchVC)
    {
        self.navigationController?.popViewControllerAnimated(true)
    }
    #endif

    //MARK:  - table view filtering
    //MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
       searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        if let segControl = self.segmentedControl
        {
            contactsFilterDidChange(segControl) // to set default fetchedResultsController
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        //myContactsTable?.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String)
    {
        searchForText(searchText)
        //myContactsTable?.reloadData()
    }
    
    //MARK: Searching
    private func searchForText(text:String)
    {
        if text.characters.count < 1
        {
            if let segControl = self.segmentedControl
            {
                contactsFilterDidChange(segControl) // to set default fetchedResultsController
            }
            return
        }
        
        if let context = localMainContext
        {
            let textPredicate = NSPredicate(format:"(lastName BEGINSWITH[cd] %@) OR (firstName BEGINSWITH[cd] %@)", text, text)
            
            var searchPredicates = [textPredicate]
            
            if let segmentSwitcher = segmentedControl
            {
                if segmentSwitcher.selectedSegmentIndex > 0
                {
                    let favPredicate = NSPredicate(format: "favorite = TRUE")
                    // ? trying to improve CoreData performance ?
                    searchPredicates.insert(favPredicate, atIndex: 0)
                }
            }
            
            let fetchRequest = NSFetchRequest(entityName: "DBContact")
            
            fetchRequest.predicate = /*predicate*/ NSCompoundPredicate(andPredicateWithSubpredicates: searchPredicates)
            
            fetchRequest.sortDescriptors = contactsFetchRequest.sortDescriptors ?? [NSSortDescriptor(key: "lastName", ascending: true)]
            
            let fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            
            self.currentFetchController?.delegate = nil
            
            fetchResultsController.delegate = self
            self.currentFetchController = fetchResultsController
            
            do
            {
                try self.currentFetchController?.performFetch()
                self.myContactsTable?.reloadData()
            }
            catch let fetchError
            {
                print("Some error while performing contacts filter fetch")
                
                print(fetchError)
            }
        }
    }
}
