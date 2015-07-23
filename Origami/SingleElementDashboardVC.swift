//
//  SingleElementDashboardVC.swift
//  Origami
//
//  Created by CloudCraft on 22.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDashboardVC: UIViewController {

    var currentElement:Element?
    @IBOutlet var collectionView:UICollectionView!
    var collectionDataSource:SingleElementCollectionViewDataSource?
    override func viewDidLoad() {
        super.viewDidLoad()

        
        collectionDataSource = SingleElementCollectionViewDataSource(element: currentElement) // both can be nil
        collectionDataSource!.handledElement = currentElement
        if collectionDataSource != nil
        {
            collectionView.dataSource = collectionDataSource!
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "elementFavouriteToggled:", name: kElementFavouriteButtonTapped, object: nil)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    //MARK: Handling buttons and other elements tap in collection view
    func elementFavouriteToggled(notification:NSNotification)
    {
        if let element = currentElement,  favourite = element.isFavourite
        {
            var isFavourite = !favourite.boolValue
            var elementCopy = Element(info: element.toDictionary())
            var titleCell:SingleElementTitleCell?
            if let titleCellCheck = notification.object as? SingleElementTitleCell
            {
                titleCell = titleCellCheck
            }
            DataSource.sharedInstance.updateElement(elementCopy, isFavourite: isFavourite) { [weak self] (edited) -> () in
                
                if let weakSelf = self
                {
                    if edited
                    {
                        weakSelf.currentElement!.isFavourite = NSNumber(bool: isFavourite)
                        titleCell?.favourite = isFavourite
                    }
                }
            }
            
        }
    }


}
