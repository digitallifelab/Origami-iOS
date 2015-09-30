//
//  OptionsView.swift
//  Origami
//
//  Created by CloudCraft on 08.09.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class OptionsView: UIView, UITableViewDelegate, UITableViewDataSource {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    private var tableView:UITableView
    private var optionsSource:[[String:String]]?
    var delegate:TableItemPickerDelegate?
    var message:Message?
    
    let displayMode:DisplayMode = (NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey)) ? .Night : .Day
    
    required init?(coder aDecoder: NSCoder) {
        self.tableView = UITableView(frame: CGRectZero, style: .Plain)
        super.init(coder: aDecoder)
    }
    
    init()
    {
        self.tableView = UITableView(frame: CGRectZero, style: .Plain)
        super.init(frame: CGRectZero)
    }
    
    convenience init?(optionsInfo:[[String:String]]?)
    {
        self.init()
       // tableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)
       
        
        if optionsInfo == nil
        {
            return nil
        }
        if optionsInfo!.count < 1
        {
            return nil
        }
        
        self.optionsSource = optionsInfo
        self.autoresizingMask = [UIViewAutoresizing.FlexibleLeftMargin , UIViewAutoresizing.FlexibleRightMargin , UIViewAutoresizing.FlexibleTopMargin]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.displayMode == .Day
        {
            self.backgroundColor = kWhiteColor
            self.layer.shadowColor = UIColor.blackColor().colorWithAlphaComponent(0.6).CGColor
        }
        else
        {
            self.backgroundColor = kBlackColor
            self.layer.shadowColor = UIColor.whiteColor().colorWithAlphaComponent(0.6).CGColor
        }
   
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 3.0
        self.layer.shadowOffset = CGSizeMake(0.0, -2.0)
        
        configureTable()
    }
   
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0
        {
            if let info = optionsSource
            {
                return info.count
            }
            return 0
        }
        else
        {
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        
        cell.selectionStyle = .Gray

        configureCell(cell, forIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell:UITableViewCell, forIndexPath:NSIndexPath)
    {
        if forIndexPath.section == 0
        {
            if let infoArray = self.optionsSource
            {
                let row = forIndexPath.row
                if infoArray.count > row
                {
                    let infoDict = infoArray[row]
                    for (key, value) in infoDict
                    {
                        cell.textLabel?.text = key
                
                        if let image = UIImage(named: value)
                        {
                            cell.imageView?.image = image.imageWithRenderingMode(.AlwaysTemplate)
                        }
                        break
                    }
                }
                
                if let font = UIFont(name: "SegoeUI", size: 17)
                {
                    cell.textLabel?.font = font
                }
                
                if self.displayMode == .Day
                {
                    cell.imageView?.tintColor = kDayCellBackgroundColor
                    cell.textLabel?.textColor = kDayCellBackgroundColor
                }
                else
                {
                    cell.textLabel?.textColor = kWhiteColor
                    cell.imageView?.tintColor = kWhiteColor
                }
                
                cell.imageView?.contentMode = .ScaleAspectFit
             
            }
            cell.backgroundColor = UIColor.clearColor()
        }
        else
        {
            cell.textLabel?.text = "cancel".localizedWithComment("")
            cell.textLabel?.textColor = kDaySignalColor
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.backgroundColor = UIColor.clearColor()
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 0
        {
            self.delegate?.itemPicker(self, didPickItem: indexPath)
        }
        else
        {
            self.delegate?.itemPickerDidCancel(self)
        }
    }
    
    
    //MARK: layout
    private func configureTable()
    {
        self.tableView.removeFromSuperview()
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = true//setTranslatesAutoresizingMaskIntoConstraints(true)
        
        self.tableView.backgroundColor = UIColor.clearColor()
        
        self.tableView.frame = self.bounds
       
        self.addSubview(self.tableView)
        
        self.tableView.autoresizingMask = [.FlexibleHeight , .FlexibleWidth]
        
        self.tableView.scrollEnabled = false
        
        self.tableView.dataSource = self
        self.tableView.reloadData()
        let numberOfRows = CGFloat(self.tableView.numberOfRowsInSection(0) + self.tableView.numberOfRowsInSection(1))
        
        let rowHeight = floor(self.bounds.size.height / numberOfRows)
        self.tableView.rowHeight = rowHeight
        
        self.tableView.delegate = self
        self.tableView.reloadData()
        self.tableView.contentOffset = CGPointMake(0, -2) // to hide bottom cell delimiter
        
        self.alpha = 0.0
        
        showYourselfAnimated(true)
    }
    
    //MARK: --
    func showYourselfAnimated(animated:Bool)
    {
        if animated
        {
            UIView.animateWithDuration(0.2, animations: {[weak self] () -> Void in
                if let weakSelf = self
                {
                    weakSelf.alpha = 1.0
                }
            })
        }
        else
        {
            self.alpha = 1.0
        }
    }
}
