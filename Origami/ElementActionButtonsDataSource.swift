//
//  ElementActionButtonsDataSource.swift
//  Origami
//
//  Created by CloudCraft on 23.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

struct ActionButtonModel {
    var type:ActionButtonCellType = .Edit
    var enabled:Bool = true
    var backgroundColor:UIColor = UIColor.lightGrayColor()
    var tintColor:UIColor = UIColor.whiteColor()
}


class ElementActionButtonsDataSource: NSObject, UICollectionViewDataSource {
    
    var buttons:[ActionButtonModel]?
    convenience init?(buttonModels:[ActionButtonModel]?)
    {
        self.init()
        if buttonModels == nil
        {
            return nil
        }
        if buttonModels!.isEmpty
        {
            return nil
        }
        
        self.buttons = buttonModels
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let existButtons = self.buttons
        {
            return buttons!.count
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var buttonCell = collectionView.dequeueReusableCellWithReuseIdentifier("ActionButtonCell", forIndexPath: indexPath) as! ElementActionButtonCell
        if let buttonModel = buttons?[indexPath.item]
        {
            buttonCell.imageView.image = imageForButton(buttonModel)
            buttonCell.imageView.backgroundColor = buttonModel.backgroundColor //backgroundColorForButton(button)
            buttonCell.imageView.tintColor = buttonModel.tintColor
        }
        println("tint color: \(buttonCell.imageView.tintColor)")
        return buttonCell
    }
    
    func imageForButton(model:ActionButtonModel) -> UIImage?
    {
        switch model.type
        {
        case .Edit:
            return UIImage(named: "icon-edit")
        case .Add:
            return UIImage(named: "icon-add")
        case .Delete:
            return UIImage(named: "icon-delete")
        case .Archive:
            return UIImage(named: "icon-arch")
        case .Signal:
            return UIImage(named: "icon-flag")
        case .CheckMark:
            return UIImage(named: "icon-okey")
        case .Idea:
            return UIImage(named: "icon-idea")
        case .Solution:
            return UIImage(named: "icon-solution")
        }
    }
   
}
