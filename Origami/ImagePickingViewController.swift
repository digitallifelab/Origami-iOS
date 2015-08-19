//
//  ImagePickingViewController.swift
//  Origami
//
//  Created by CloudCraft on 23.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ImagePickingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var imagePickerController:UIImagePickerController = UIImagePickerController()
    @IBOutlet var navigationBackgroundView:UIView!
    @IBOutlet var preview:UIImageView!
    @IBOutlet var cameraButton:UIBarButtonItem!
    var attachPickingDelegate:AttachPickingDelegate?
    private var selectedMedia:MediaFile? {
        didSet{
            if let lvData = selectedMedia?.data
            {
                self.preview.image = UIImage(data:lvData)
            }
        }
    }
    private var mediaName:String? {
        get{
            var lvDate = NSDate().timeDateStringShortStyle().stringByReplacingOccurrencesOfString(" ", withString: "_") + ".jpg" as NSString
            lvDate = lvDate.stringByReplacingOccurrencesOfString(":", withString: "-")
            lvDate = lvDate.stringByReplacingOccurrencesOfString(",", withString: "")
            lvDate = lvDate.stringByReplacingOccurrencesOfString("/", withString: "-")
            return lvDate as String
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !UIImagePickerController.isSourceTypeAvailable(.Camera) {
            cameraButton.enabled = false
        }
        imagePickerController.delegate = self
        // Do any additional setup after loading the view.
        
        setAppearanceForNightModeToggled(NSUserDefaults.standardUserDefaults().boolForKey(NightModeKey))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //MARK: Appearance
    func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        if nightModeOn
        {
            //self.displayMode = .Night
            self.view.backgroundColor = UIColor.blackColor()
            self.navigationBackgroundView.backgroundColor = UIColor.blackColor()
        }
        else
        {
            //self.displayMode = .Day
            self.view.backgroundColor = kDayViewBackgroundColor //kDayViewBackgroundColor
            self.navigationBackgroundView.backgroundColor = /*UIColor.whiteColor()*/kDayNavigationBarBackgroundColor
        }
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        var selectedImage:UIImage = UIImage()
        if let originamImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = originamImage
        }
        else if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = editedImage
        }
        
        proceedWithSelectedImage(selectedImage)
        
        self.dismissViewControllerAnimated(true, completion:nil)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: ----
    private func showImagePickerControllerFor(sender:UIBarButtonItem) {
        
        if sender.tag == 2 {
            if UIImagePickerController.isSourceTypeAvailable(.Camera)
            {
                imagePickerController.sourceType = .Camera
                imagePickerController.showsCameraControls = true
            }
            else
            {
                imagePickerController.sourceType = .PhotoLibrary
            }
        }
        else
        {
            imagePickerController.sourceType = .PhotoLibrary
            
        }
        self.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func proceedWithSelectedImage(image:UIImage)
    {
        let bgQueue:dispatch_queue_t = dispatch_queue_create("Origami.ImageProcessing.Background", DISPATCH_QUEUE_SERIAL)
        dispatch_async(bgQueue, {[weak self] () -> Void in
            
            var lvSelectedMedia = MediaFile()
            
            var fixedImage = image.fixOrientation()
            
            //reduce image size for networking
            if fixedImage.size.width >= 1000.0 || fixedImage.size.height >= 1000.0
            {
                let ratio = min(1000.0 / fixedImage.size.width , 1000.0 / fixedImage.size.height)
                let imageWidth:CGFloat =  round(fixedImage.size.width * ratio)
                let imageHeight:CGFloat = round(fixedImage.size.height * ratio)
                fixedImage = fixedImage.scaleToSizeKeepAspect(CGSizeMake(fixedImage.size.width * ratio, fixedImage.size.height * ratio))
            }
            lvSelectedMedia.type = .Image
            lvSelectedMedia.name = self?.mediaName ?? ""
            lvSelectedMedia.data = UIImageJPEGRepresentation(fixedImage,
                0.9)
            
            dispatch_async(dispatch_get_main_queue(), {[weak self] () -> Void in
                if let aSelf = self
                {
                    aSelf.selectedMedia = lvSelectedMedia
                }
            })
        })
    }
    
    //MARK: IBActions
    @IBAction func cancelTapped(sender:UIBarButtonItem) {
        self.attachPickingDelegate?.mediaPickerDidCancel(self)
    }
    
    @IBAction func doneTapped(sender:UIBarButtonItem) {
        if selectedMedia != nil
        {
            self.attachPickingDelegate?.mediaPicker(self, didPickMediaToAttach: selectedMedia!)
        }
        else
        {
            cancelTapped(sender)
        }
    }
    
    @IBAction func cameraTapped(sender:UIBarButtonItem) {
        showImagePickerControllerFor(sender)
    }
    
    @IBAction func galleryTapped(sender:UIBarButtonItem) {
        showImagePickerControllerFor(sender)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
