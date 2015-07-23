//
//  MoreButtonHolderView.swift
//  Origami
//
//  Created by CloudCraft on 10.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class MoreButtonHolderView: UIView
{
    var view:UIView!
    var buttonTapDelegate:ButtonTapDelegate?
    @IBOutlet var button:UIButton!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
//        MoreButtonHolderView.loadFromNibNamed("MoreButtonHolderView", bundle: nil)
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
        let nib = UINib(nibName: "MoreButtonHolderView", bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    @IBAction func extendButtonTapped(sender:UIButton)
    {
        self.buttonTapDelegate?.didTapOnButton(button)
    }
}
