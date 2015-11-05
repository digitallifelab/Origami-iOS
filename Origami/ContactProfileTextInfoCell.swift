//
//  ContactProfileTextInfoCell.swift
//  Origami
//
//  Created by CloudCraft on 26.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactProfileTextInfoCell: UITableViewCell {

    @IBOutlet weak var titleTextLabel:UILabel?
    @IBOutlet weak var mainInfoTextLabel:UILabel?
    
    var displayMode:DisplayMode = .Day{
        didSet{
            switch displayMode
            {
            case .Day :
                mainInfoTextLabel?.textColor = kBlackColor
            case .Night :
                mainInfoTextLabel?.textColor = kWhiteColor
            }
            
        }
    }

}
