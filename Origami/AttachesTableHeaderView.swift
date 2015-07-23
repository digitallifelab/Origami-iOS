//
//  AttachesTableHeaderView.swift
//  Origami
//
//  Created by CloudCraft on 23.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class AttachesTableHeaderView: UIView {

    var view:UIView!
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var addButton:UIButton!
    var buttonTapDelegate:ButtonTapDelegate?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        
        // use bounds not frame or it'll be offset
        view.frame = bounds
        
        // Make the view stretch with containing view
        view.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView
    {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "AttachesTableHeaderView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    @IBAction func addAttachmentTapped(sender:UIButton)
    {
        buttonTapDelegate?.didTapOnButton(sender)
    }
    
}
