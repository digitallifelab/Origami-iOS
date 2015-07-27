//
//  SingleElementDateDetailsCell.swift
//  Origami
//
//  Created by CloudCraft on 27.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class SingleElementDateDetailsCell: UICollectionViewCell, UITableViewDataSource {
    
    var displayMode:DisplayMode = .Day {
        didSet{
            switch self.displayMode{
            case .Day:
                self.backgroundColor = kDayCellBackgroundColor
               
            case .Night:
                self.backgroundColor = UIColor.clearColor()
                
            }
        }
    }
    var handledElement:Element?
    
    @IBOutlet var datesTable:UITableView!
    
    
    //MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var countRows = 0
        if let dateCreated = handledElement?.createDate?.timeDateStringFromServerDateString() as? String
        {
            countRows += 1
        }
        if let dateModified = handledElement?.changeDate?.timeDateStringFromServerDateString() as? String
        {
            countRows += 1
        }
        if let dateFinished = handledElement?.finishDate?.timeDateString() as? String
        {
            countRows += 1
        }
        return countRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var datesCell = tableView.dequeueReusableCellWithIdentifier("DatesTableHolderCell", forIndexPath: indexPath) as! ElementDashboardDatesCell
        datesCell.displayMode = self.displayMode
        
        configureDateCellForRow(indexPath.row, cell: datesCell)
        
        return datesCell
    }
    
    
    private func configureDateCellForRow(row:Int, cell:ElementDashboardDatesCell)
    {
        switch row
        {
        case 0:
            cell.titleLabel.text = "Created".localizedWithComment("")
            cell.dateLael.text = handledElement?.createDate?.dateFromServerDateString()?.timeDateString() as String? ?? nil
        case 1:
            cell.titleLabel.text = "Changed".localizedWithComment("")
            cell.dateLael.text = handledElement?.changeDate?.dateFromServerDateString()?.timeDateString() as String? ?? nil
        case 2:
            cell.titleLabel.text = "Finished".localizedWithComment("")
            cell.dateLael.text = handledElement?.finishDate?.timeDateString() as String? ?? nil
        default:
            break
        }
    }
}
