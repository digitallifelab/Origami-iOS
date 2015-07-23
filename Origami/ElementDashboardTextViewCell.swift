//
//  ElementDashboardTextViewCell.swift
//  Origami
//
//  Created by CloudCraft on 09.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementDashboardTextViewCell: UITableViewCell , UITextViewDelegate {

    @IBOutlet var textView:UITextView!
    @IBOutlet var moreButton:UIButton!
    @IBOutlet var favouriteIcon:UIButton!
    @IBOutlet var favIconWidthConstraint:NSLayoutConstraint!
    @IBOutlet var lessTextLabel:UILabel!
    var tapOnLabel:UITapGestureRecognizer?
    var displayMode:DisplayMode = .Day {
        didSet{
            if displayMode == .Night
            {
                textView.textColor = UIColor.whiteColor()
                lessTextLabel.textColor = UIColor.whiteColor()
            }
            else  // (.Day)
            {
                textView.textColor = UIColor.blackColor()
                lessTextLabel.textColor = UIColor.blackColor()
            }
        }
    
    }
    var moreDescriptionDelegate:ButtonTapDelegate?
    var editingDelegate:ElementTextEditingDelegate?

    var showsMoreButton = false //show or hide More button at bottom left
        {
        didSet{
            moreButton.hidden = !showsMoreButton
        }
    }
    
    var isTitleCell = false //hide or show favourite icon at top left
        {
        didSet{
            favouriteIcon.hidden = !isTitleCell
            favIconWidthConstraint.constant = (isTitleCell) ? 35.0 : 0.0
        }
    }
    
    var shouldEditTextView = false {
        didSet{
            self.textView.delegate = self
            self.textView.delegate = (shouldEditTextView) ? self : nil
            self.textView.editable = shouldEditTextView
            self.textView.userInteractionEnabled = shouldEditTextView
            if shouldEditTextView && !isTitleCell
            {
                self.lessTextLabel.layer.zPosition = 20.0
                self.textView.layer.zPosition = 1.0
                self.checkLessLabelTapRecognizer(true)
            }
            else
            {
                self.textView.layer.zPosition = 20.0
                self.lessTextLabel.layer.zPosition = 1.0
                self.checkLessLabelTapRecognizer(false)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        // uncomment to debug

//        self.lessTextLabel.layer.borderWidth = 2.0
       // self.textView.layer.borderWidth = 2.0
        self.backgroundColor = UIColor.clearColor()
        moreButton.tintColor = kDaySignalColor
    }

    override func prepareForReuse() {
        
        self.checkLessLabelTapRecognizer(shouldEditTextView && !isTitleCell)
        super.prepareForReuse()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if self.textView == nil
        {
            self.textView = UITextView(frame: self.bounds)
            self.textView.scrollEnabled = false
            self.textView.font = UIFont(name: "Segoe UI", size: 14.0)
            self.textView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
            self.contentView.addSubview(self.textView)
        }
    }
    
    func checkLessLabelTapRecognizer(shouldEdit:Bool)
    {
        if let touchRecognizers = self.lessTextLabel.gestureRecognizers as? [UIGestureRecognizer]
        {
            for gRecog in touchRecognizers
            {
                self.lessTextLabel.removeGestureRecognizer(gRecog)
            }
        }
        self.tapOnLabel = nil
        
        if shouldEdit
        {
            self.tapOnLabel = UITapGestureRecognizer(target: self, action: "textLabelTap:")
            self.tapOnLabel!.numberOfTapsRequired = 1
            self.tapOnLabel!.numberOfTouchesRequired = 1
            self.lessTextLabel?.addGestureRecognizer(self.tapOnLabel!)
            if !self.lessTextLabel.userInteractionEnabled
            {
                self.lessTextLabel.userInteractionEnabled = true
            }
        }
    }
    
    @IBAction func moreButtonTapped(sender:UIButton)
    {
        //println("Description Text Cell. MORE button tapped.")
        moreDescriptionDelegate?.didTapOnButton(sender)
    }
    @IBAction func favouriteButtonTapped(sender:UIButton)
    {
        if self.editingDelegate != nil
        {
            self.editingDelegate!.titleCellwantsToChangeElementIsFavourite?(self)
        }
    }
    

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //MARK: UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool
    {
        if self.editingDelegate != nil
        {
            if self.isTitleCell
            {
                self.editingDelegate!.titleCellEditTitleTapped(self)
            }
            else
            {
                self.editingDelegate!.descriptionCellEditDescriptionTapped(self)
            }
            
        }
        return false
    }
    
    func textLabelTap(sender:UITapGestureRecognizer)
    {
        self.textViewShouldBeginEditing(self.textView)
    }

}
