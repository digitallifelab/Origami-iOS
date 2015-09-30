//
//  ImageFilter.swift
//  Origami
//
//  Created by CloudCraft on 05.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit
import ImageIO

typealias imageReturningBlock = (image:UIImage?)->()

class ImageFilter
{
//    var context:CIContext = CIContext(options: [kCIContextPriorityRequestLow:true])
//    var filter:CIFilter = CIFilter(name: "CIPhotoEffectNoir")// "CISepiaTone"  "CIPhotoEffectMono"
//    
//    deinit
//    {
//        print(" ImageFilter Was Released")
//    }
//    
//    init()
//    {
//        print(" ImageFilter was Initialized")
//    }
//    
//    func filterImageBlackAndWhite(image:UIImage) -> UIImage?
//    {
//        var currentImageOrientation : UIImageOrientation?
//        
//        currentImageOrientation = image.imageOrientation
//        
//        var startImage = CIImage(CGImage: image.CGImage)
//        filter.setValue(startImage, forKey: kCIInputImageKey)
//        
//        var outputImage = filter.outputImage
//        
//        var cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
//        
//        var toReturnUIImage:UIImage?
//        if let orientation = currentImageOrientation
//        {
//            toReturnUIImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: orientation)
//        }
//        else
//        {
//            toReturnUIImage = UIImage(CGImage: cgImage)
//        }
//        
//        return toReturnUIImage
//    }
//    
//    func filterImageBlackAndWhiteInBackGround(image:UIImage, completeInMainQueue:Bool, completion completionBlock:imageReturningBlock?)
//    {
//        let bgQueue = dispatch_queue_create("Origami.ImageFiltering", DISPATCH_QUEUE_SERIAL)
//        
//        dispatch_async(bgQueue, { () -> Void in
//            var currentImageOrientation : UIImageOrientation?
//            
//            currentImageOrientation = image.imageOrientation
//            
//            var lvContext:CIContext = CIContext(options: [kCIContextPriorityRequestLow:true])
//            var filter:CIFilter = CIFilter(name: "CIPhotoEffectNoir")
//            
//            var startImage = CIImage(CGImage: image.CGImage)
//            filter.setValue(startImage, forKey: kCIInputImageKey)
//            
//            var outputImage = filter.outputImage
//            
//            var cgImage = lvContext.createCGImage(outputImage, fromRect: outputImage.extent())
//            
//            var toReturnUIImage:UIImage?
//            if let orientation = currentImageOrientation
//            {
//                toReturnUIImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: orientation)
//            }
//            else
//            {
//                toReturnUIImage = UIImage(CGImage: cgImage)
//            }
//            
//            if let toComplete = completionBlock
//            {
//                if completeInMainQueue
//                {
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        toComplete(image: toReturnUIImage)
//                    })
//                }
//                else
//                {
//                    toComplete(image: toReturnUIImage)
//                }
//            }
//        })
//    }
    
    class func getImagePreviewDataFromData(imageData:NSData) -> NSData?
    {
//        var size : Int = 200
//        let cfBool:CFBooleanRef = true
//        let cfNum = CFNumberCreate(nil, CFNumberType.IntType, &size)
//        
//        let dictionayKeyCB = UnsafePointer<CFDictionaryKeyCallBacks>()
//        let valueKeyCB = UnsafePointer<CFDictionaryValueCallBacks>()
//        
//        let keys: [CFStringRef] = [kCGImageSourceCreateThumbnailFromImageIfAbsent, kCGImageSourceThumbnailMaxPixelSize]
//        let keysPointer =  UnsafeMutablePointer<UnsafePointer<Void>>.alloc(1)
//        keysPointer.initialize(keys)
//        
//        let values: [CFTypeRef] = [kCFBooleanTrue, cfNum]
//        let valuesPointer =  UnsafeMutablePointer<UnsafePointer<Void>>.alloc(1)
//        valuesPointer.initialize(values)
//        
//        let options = CFDictionaryCreate(kCFAllocatorDefault, keysPointer, valuesPointer, 2, dictionayKeyCB, valueKeyCB)
//
//        
//        if let imageSource = CGImageSourceCreateWithData(imageData , nil)
//        {
//            
//            let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options)
//            //CFRelease(imageSource)
//            if let uiImage = UIImage(CGImage: cgImage)
//            {
//                return UIImageJPEGRepresentation(uiImage, 1.0)
//            }
//        }
        if let image = UIImage(data: imageData)
        {
            if let scaledImage = image.scaleToSizeKeepAspect(CGSizeMake(200, 200))
            {
                return UIImageJPEGRepresentation(scaledImage, 1.0)
            }
        }
        
        return nil
    }
    /*
    -( UIImage *)       thumbnailFromImage: ( UIImage *)image
    {
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider( image.CGImage );
    CGImageSourceRef src = CGImageSourceCreateWithDataProvider( dataProvider, NULL );
    
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
    (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
    (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageAlways,
    (id)[NSNumber numberWithFloat:160.f], (id)kCGImageSourceThumbnailMaxPixelSize,
    nil];
    
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex( src, 0, (__bridge CFDictionaryRef)(options) );
    
    UIImage* smallImage = [UIImage imageWithCGImage:thumbnail scale:1 orientation:UIImageOrientationUp];
    return smallImage;
    }
*/
    /*
    
    
    CGImageRef MyCreateThumbnailImageFromData (NSData * data, int imageSize)
    
    {
    
    CGImageRef        myThumbnailImage = NULL;
    
    CGImageSourceRef  myImageSource;
    
    CFDictionaryRef   myOptions = NULL;
    
    CFStringRef       myKeys[3];
    
    CFTypeRef         myValues[3];
    
    CFNumberRef       thumbnailSize;
    
    
    
    // Create an image source from NSData; no options.
    
    myImageSource = CGImageSourceCreateWithData((CFDataRef)data,
    
    NULL);
    
    // Make sure the image source exists before continuing.
    
    if (myImageSource == NULL){
    
    fprintf(stderr, "Image source is NULL.");
    
    return  NULL;
    
    }
    
    
    
    // Package the integer as a  CFNumber object. Using CFTypes allows you
    
    // to more easily create the options dictionary later.
    
    thumbnailSize = CFNumberCreate(NULL, kCFNumberIntType, &imageSize);
    
    
    
    // Set up the thumbnail options.
    
    myKeys[0] = kCGImageSourceCreateThumbnailWithTransform;
    
    myValues[0] = (CFTypeRef)kCFBooleanTrue;
    
    myKeys[1] = kCGImageSourceCreateThumbnailFromImageIfAbsent;
    
    myValues[1] = (CFTypeRef)kCFBooleanTrue;
    
    myKeys[2] = kCGImageSourceThumbnailMaxPixelSize;
    
    myValues[2] = (CFTypeRef)thumbnailSize;
    
    
    
    myOptions = CFDictionaryCreate(NULL, (const void **) myKeys,
    
    (const void **) myValues, 2,
    
    &kCFTypeDictionaryKeyCallBacks,
    
    & kCFTypeDictionaryValueCallBacks);
    
    
    
    // Create the thumbnail image using the specified options.
    
    myThumbnailImage = CGImageSourceCreateThumbnailAtIndex(myImageSource,
    
    0,
    
    myOptions);
    
    // Release the options dictionary and the image source
    
    // when you no longer need them.
    
    CFRelease(thumbnailSize);
    
    CFRelease(myOptions);
    
    CFRelease(myImageSource);
    
    
    
    // Make sure the thumbnail image exists before continuing.
    
    if (myThumbnailImage == NULL){
    
    fprintf(stderr, "Thumbnail image not created from image source.");
    
    return NULL;
    
    }
    
    
    
    return myThumbnailImage;
    
    }
    

    
*/
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}