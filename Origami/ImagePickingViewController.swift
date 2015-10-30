//
//  ImagePickingViewController.swift
//  Origami
//
//  Created by CloudCraft on 23.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//


import UIKit

/**
 ImagePickingViewController is used for:
 - adding attaches to element
 - to select user`s profile avatar
*/
class ImagePickingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var imagePickerController:UIImagePickerController = UIImagePickerController()
 
    @IBOutlet var preview:UIImageView!
    @IBOutlet var cameraButton:UIBarButtonItem!
    var attachPickingDelegate:AttachPickingDelegate?
    @IBOutlet var bottomToolbar:UIToolbar!
    
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
            let lvDateString = NSDate().timeDateStringForMediaName() + ".jpg"
         
            return lvDateString // as String
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
    override func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        super.setAppearanceForNightModeToggled(nightModeOn)
        self.bottomToolbar.translucent = false
        if nightModeOn
        {
            self.bottomToolbar.tintColor = kWhiteColor
            self.bottomToolbar.barTintColor = kBlackColor
        }
        else
        {
            self.bottomToolbar.tintColor = kDayNavigationBarBackgroundColor
            self.bottomToolbar.barTintColor = kWhiteColor
        }
    }
    
    //MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        var selectedImage:UIImage = UIImage()
        if picker.allowsEditing
        {
            if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
                selectedImage = editedImage
            }
            else if let originamImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                selectedImage = originamImage
            }
        }
        else
        {
            if let originamImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
                selectedImage = originamImage
            }
        }
        
        proceedWithSelectedImage(selectedImage)
        
        imagePickerController.willMoveToParentViewController(nil)
        imagePickerController.view.removeFromSuperview()
        imagePickerController.removeFromParentViewController()
        imagePickerController.didMoveToParentViewController(nil)
        
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
        
        imagePickerController.allowsEditing = false
        if let allowEditingResult = self.attachPickingDelegate?.mediaPickerShouldAllowEditing(self)
        {
            imagePickerController.allowsEditing = allowEditingResult
        }
        
        self.addChildViewController(imagePickerController)
        imagePickerController.willMoveToParentViewController(self)
        self.view.addSubview(imagePickerController.view)
        imagePickerController.didMoveToParentViewController(self)
        
    }
    
    func proceedWithSelectedImage(image:UIImage)
    {
        let bgQueue:dispatch_queue_t = dispatch_queue_create("Origami.ImageProcessing.Background", DISPATCH_QUEUE_SERIAL)
        let currentMediaName = self.mediaName
        dispatch_async(bgQueue, {[weak self] () -> Void in
            
            let lvSelectedMedia = MediaFile()
            
            var fixedImage = image.fixOrientation()
            
            if let weakSelf = self, let targetImageSize = weakSelf.attachPickingDelegate?.mediaPickerPreferredImgeSize(weakSelf)
            {
                //reduce image size for networking
                let targetWidth = targetImageSize.width
                let targetHeight = targetImageSize.height
                
                if fixedImage.size.width >= targetWidth || fixedImage.size.height >= targetHeight
                {
                    let ratio = min(targetWidth / fixedImage.size.width , targetWidth / fixedImage.size.height)
                    //let imageWidth:CGFloat =  round(fixedImage.size.width * ratio)
                    //let imageHeight:CGFloat = round(fixedImage.size.height * ratio)
                    if let scaled = fixedImage.scaleToSizeKeepAspect(CGSizeMake(fixedImage.size.width * ratio, fixedImage.size.height * ratio))
                    {
                        fixedImage = scaled
                    }
                    else
                    {
                        assert(false, " did not  scale down an image.")
                    }
                }
            }
            
            lvSelectedMedia.type = .Image
            if let name = currentMediaName
            {
                lvSelectedMedia.name = name
            }
            else
            {
                lvSelectedMedia.name = ""
            }
            
            if let aData = UIImageJPEGRepresentation(fixedImage, 1.0)
            {
                lvSelectedMedia.data = aData
            }
            
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
