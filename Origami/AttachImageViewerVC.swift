//
//  AttachImageViewerVC.swift
//  Origami
//
//  Created by CloudCraft on 26.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class AttachImageViewerVC: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var imageScrollView:UIScrollView!
    var delegate:AttachViewerDelegate?
    var imageToDisplay:UIImage?
    var imageHolder:UIImageView?
    var doubleTapRecognizer:UITapGestureRecognizer?
    var fileCreatorId:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if imageHolder != nil
        {
            imageHolder!.image = imageToDisplay
        }
     
        doubleTapRecognizer = UITapGestureRecognizer (target: self, action: "doubleTapAction:")
        doubleTapRecognizer?.numberOfTapsRequired = 2
        doubleTapRecognizer?.numberOfTouchesRequired = 1
        imageScrollView.addGestureRecognizer(doubleTapRecognizer!)
        imageScrollView.delegate = self
       
        setAppearanceForNightModeToggled(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        if imageHolder == nil
        {
            addImageHolder()
        }
        setupDeleteButton()
   
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        imageHolder?.removeFromSuperview()
        imageHolder = nil
    }
    
    override func viewDidLayoutSubviews() {
        addImageHolder()
    }

    
    private func setupDeleteButton()
    {
        if let delegate = self.delegate
        {
            if delegate.attachViewerShouldAllowDeletion(self)
            {
                let deleteBarButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "deleteAttachButtontapped:")
                self.navigationItem.rightBarButtonItem = deleteBarButton
            }
        }
    }
    
    func addImageHolder()
    {
        if imageToDisplay != nil && imageHolder == nil
        {
            if CGRectGetWidth(imageScrollView.bounds) > imageToDisplay!.size.width || CGRectGetHeight(imageScrollView.bounds) > imageToDisplay!.size.height
            {
                imageScrollView.contentSize = imageScrollView.bounds.size
            }
            else
            {
                
            }
            imageHolder = UIImageView(image: imageToDisplay)
            imageHolder!.contentMode = .ScaleAspectFit
            imageHolder!.sizeToFit()
            let fullFrame = imageHolder!.frame
            
            if fullFrame.size.width > imageScrollView.bounds.size.width || fullFrame.size.height > imageScrollView.bounds.size.height
            {
                // decrease image frame to fit scrollView dimensions
            
                let horizontalRatio = imageScrollView.bounds.size.width / fullFrame.size.width
                let verticalRatio = imageScrollView.bounds.size.height / fullFrame.size.height
                let scaleFactor = (horizontalRatio > verticalRatio) ? verticalRatio : horizontalRatio
                
                let newImageFrame = CGRectMake(fullFrame.origin.x, fullFrame.origin.y, fullFrame.size.width * scaleFactor, fullFrame.size.height * scaleFactor)
                
                imageHolder!.frame = newImageFrame
                
                imageScrollView.contentSize = CGSizeMake(fullFrame.size.width * 2, fullFrame.size.height * 2)
                imageScrollView.contentOffset = CGPointMake(-fullFrame.size.width / 2, -fullFrame.size.height / 2)
                imageScrollView.maximumZoomScale = 1 / scaleFactor
            }
            else
            {
                imageScrollView.maximumZoomScale = 2.0
            }
            
            
            imageHolder!.center = CGPointMake(CGRectGetMidX(imageScrollView.bounds), CGRectGetMidY(imageScrollView.bounds))
            imageHolder!.layer.borderWidth = 1.0
            imageScrollView.addSubview(imageHolder!)
            
            centerImageInScrollView()
        }
    }
    
    func centerImageInScrollView()
    {
        let center = CGPointMake(CGRectGetMidX(imageScrollView.bounds), CGRectGetMidY(imageScrollView.bounds))
        imageHolder!.center = center
    }
    
    func doubleTapAction(recognizer:UITapGestureRecognizer)
    {
        // Zoom out slightly, capping at the minimum zoom scale specified by the scroll view
        var newZoomScale:CGFloat = imageScrollView.zoomScale / 1.5
        newZoomScale = max(newZoomScale, imageScrollView.minimumZoomScale);
        imageScrollView.setZoomScale(newZoomScale, animated: true)
        centerImageInScrollView()
    }
    
    //MARK: UIScrollViewDelegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageHolder
    }
    func scrollViewDidZoom(scrollView: UIScrollView) {
        centerImageInScrollView()
    }
    
    
    //MARK: - Delete Attach File
    func deleteAttachButtontapped(sender:AnyObject)
    {
        delegate?.attachViewerDeleteAttachButtonTapped(self)
    }

}
