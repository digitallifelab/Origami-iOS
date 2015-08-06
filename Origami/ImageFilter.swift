//
//  ImageFilter.swift
//  Origami
//
//  Created by CloudCraft on 05.08.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

typealias imageReturningBlock = (image:UIImage?)->()

class ImageFilter
{
    var context:CIContext = CIContext(options: [kCIContextPriorityRequestLow:true])
    var filter:CIFilter = CIFilter(name: "CIPhotoEffectNoir")// "CISepiaTone"  "CIPhotoEffectMono"
    
    deinit
    {
        println(" ImageFilter Was Released")
    }
    
    init()
    {
        println(" ImageFilter was Initialized")
    }
    
    func filterImageBlackAndWhite(image:UIImage) -> UIImage?
    {
        var currentImageOrientation : UIImageOrientation?
        
        currentImageOrientation = image.imageOrientation
        
        var startImage = CIImage(CGImage: image.CGImage)
        filter.setValue(startImage, forKey: kCIInputImageKey)
        
        var outputImage = filter.outputImage
        
        var cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent())
        
        var toReturnUIImage:UIImage?
        if let orientation = currentImageOrientation
        {
            toReturnUIImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: orientation)
        }
        else
        {
            toReturnUIImage = UIImage(CGImage: cgImage)
        }
        
        return toReturnUIImage
    }
    
    func filterImageBlackAndWhiteInBackGround(image:UIImage, completeInMainQueue:Bool, completion completionBlock:imageReturningBlock?)
    {
        let bgQueue = dispatch_queue_create("Origami.ImageFiltering", DISPATCH_QUEUE_SERIAL)
        
        dispatch_async(bgQueue, { () -> Void in
            var currentImageOrientation : UIImageOrientation?
            
            currentImageOrientation = image.imageOrientation
            
            var lvContext:CIContext = CIContext(options: [kCIContextPriorityRequestLow:true])
            var filter:CIFilter = CIFilter(name: "CIPhotoEffectNoir")
            
            var startImage = CIImage(CGImage: image.CGImage)
            filter.setValue(startImage, forKey: kCIInputImageKey)
            
            var outputImage = filter.outputImage
            
            var cgImage = lvContext.createCGImage(outputImage, fromRect: outputImage.extent())
            
            var toReturnUIImage:UIImage?
            if let orientation = currentImageOrientation
            {
                toReturnUIImage = UIImage(CGImage: cgImage, scale: 1.0, orientation: orientation)
            }
            else
            {
                toReturnUIImage = UIImage(CGImage: cgImage)
            }
            
            if let toComplete = completionBlock
            {
                if completeInMainQueue
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        toComplete(image: toReturnUIImage)
                    })
                }
                else
                {
                    toComplete(image: toReturnUIImage)
                }
            }
            
            
           
        })
      
    }
}