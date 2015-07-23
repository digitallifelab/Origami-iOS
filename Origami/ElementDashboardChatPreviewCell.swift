//
//  ElementDashboardChatPreviewCell.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementDashboardChatPreviewCell: UITableViewCell // this cell contains and handles chat table, chat preview for currently displayed element
{

    @IBOutlet var chatPreviewTable:UITableView!
    
    var chatDataSource:ElementChatPreviewTableHandler?
        {
        didSet{
            chatPreviewTable.dataSource = chatDataSource
            //chatPreviewTable.delegate = chatDataSource
            chatPreviewTable.layer.borderColor = UIColor.lightGrayColor().CGColor
            if chatDataSource != nil{
                chatPreviewTable.layer.borderWidth = (chatDataSource!.messageObjects.isEmpty) ? 0.0 : 1.0
            }
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //chatPreviewTable.delegate = chatDataSource
        //chatPreviewTable.dataSource = chatDataSource
        //chatPreviewTable.rowHeight = 60.0
        self.backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        chatPreviewTable.rowHeight = 50.0
        chatPreviewTable.scrollRectToVisible(CGRectMake(0, self.bounds.size.height - 20, self.bounds.size.width, 20), animated: false)
    }
}
