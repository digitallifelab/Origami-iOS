//
//  Extensions.swift
//  Origami
//
//  Created by CloudCraft on 08.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit
extension String
{
    func localizedWithComment(comment:String) -> String
    {
        let toReturnDebug = NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: comment)
        return toReturnDebug
    }
}

import UIKit

extension NSDate
{
    class func dummyDate() -> NSString
    {
        return "/Date(0)/"
    }
    
    func dateForServer() -> NSString
    {
        let utcTimeZone = NSTimeZone(abbreviation: "UTC")
        
        let gmtOffset = utcTimeZone?.secondsFromGMTForDate(self)
        if gmtOffset == nil
        {
            return ""
        }
        
        let interval = self.timeIntervalSince1970
        
        var offsetString:NSString
        
        if gmtOffset >= 0 && gmtOffset <= 9
        {
            offsetString = NSString(format: "+0%ld", Double(gmtOffset!))
        }
        else if gmtOffset > 9
        {
            offsetString = NSString(format: "+%ld", Double(gmtOffset!))
        }
        else if gmtOffset < 0 && gmtOffset >= -9
        {
            offsetString = NSString(format: "-0%ld", Double(gmtOffset!))
        }
        else
        {
            offsetString = NSString(format: "-%ld", Double(gmtOffset!))
        }
        
        let lvString = "/Date(\(Int(floor(Double(interval))))000\(offsetString)00)/" as NSString
        //let toReturn = NSString(format: "/Date(%ld000%@00)/", floor( Double(interval)), offsetString)
        
        return lvString
    }
    
    func timeDateString() -> NSString
    {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    func timeDateStringShortStyle() -> NSString
    {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .MediumStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    
    func dateStringMediumStyle() -> String?
    {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
}

extension NSString
{
    func dateFromServerDateString() -> NSDate?
    {        
        let badCharacters = NSCharacterSet(charactersInString: "1234567890-+").invertedSet
        let dateUTCstring = self.stringByTrimmingCharactersInSet(badCharacters) as NSString
        
        let lettersCount = dateUTCstring.length
        if lettersCount < 5
        {
            return nil
        }
        
        var dateValueString = dateUTCstring.substringToIndex(lettersCount - 5) as NSString
        let newCount = dateValueString.length
        if newCount < 3
        {
            return nil
        }
        
        dateValueString = dateValueString.substringToIndex(newCount - 3) as NSString
        
        let timeInterval = dateValueString.doubleValue as NSTimeInterval
        let date = NSDate(timeIntervalSince1970: timeInterval)
        
        return date
        
    }
    
    func timeDateStringFromServerDateString() -> NSString?
    {
        let badChars = NSCharacterSet(charactersInString: "1234567890-+").invertedSet
        var cleanString = self.stringByTrimmingCharactersInSet(badChars) as NSString
        if cleanString.length < 5
        {
            return nil
        }
        
        cleanString = cleanString.substringToIndex(cleanString.length - 5)
        if cleanString.length < 3
        {
            return nil
        }
        
        cleanString = cleanString.substringToIndex(cleanString.length - 3)
        let timeInterval = cleanString.doubleValue as NSTimeInterval
        let lvDate = NSDate(timeIntervalSince1970: timeInterval)
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        let toReturn = dateFormatter.stringFromDate(lvDate)
        
        return toReturn
    }
}

extension String
{
    func dateFromServerDateString() -> NSDate?
    {
        let badCharacters = NSCharacterSet(charactersInString: "1234567890-+").invertedSet
        let dateUTCstring = self.stringByTrimmingCharactersInSet(badCharacters)
        
        let lettersCount = count(dateUTCstring)
        if lettersCount < 5
        {
            return nil
        }
        let stringIndex = advance(dateUTCstring.endIndex, -5)
        var dateValueString = dateUTCstring.substringToIndex(stringIndex)
        let newCount = count(dateValueString)
        if newCount < 3
        {
            return nil
        }
        
        let nextStringIndex = advance(dateValueString.endIndex, -3)
        dateValueString = dateValueString.substringToIndex(nextStringIndex)
        
        let timeInterval = (dateValueString as NSString).doubleValue as NSTimeInterval
        let date = NSDate(timeIntervalSince1970: timeInterval)
        
        return date
    }
    
    func timeDateStringFromServerDateString() -> String?
    {
        let badChars = NSCharacterSet(charactersInString: "1234567890-+").invertedSet
        var cleanString = self.stringByTrimmingCharactersInSet(badChars) as NSString
        if cleanString.length < 5
        {
            return nil
        }
        
        cleanString = cleanString.substringToIndex(cleanString.length - 5)
        if cleanString.length < 3
        {
            return nil
        }
        
        cleanString = cleanString.substringToIndex(cleanString.length - 3)
        let timeInterval = cleanString.doubleValue as NSTimeInterval
        let lvDate = NSDate(timeIntervalSince1970: timeInterval)
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        let toReturn = dateFormatter.stringFromDate(lvDate)
        
        return toReturn as String
    }
}

extension NSData
{
    class func dataFromIntegersArray(array:[Int]) -> NSData?
    {
        var mutableData = NSMutableData(capacity: array.count)
        for integer in array
        {
            var lvInteger = integer
            let lvOneByte = NSData(bytes: &lvInteger, length: 1)
            mutableData?.appendData(lvOneByte)
        }
        return mutableData
    }
}

extension UIView {
    class func loadFromNibNamed(nibNamed: String, bundle : NSBundle? = nil) -> UIView? {
        return UINib(
            nibName: nibNamed,
            bundle: bundle
            ).instantiateWithOwner(nil, options: nil)[0] as? UIView
    }
    
    func maskToCircle()
    {        
        let maskFrame = self.bounds
        let circlePath = UIBezierPath(ovalInRect: maskFrame)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = maskFrame
        shapeLayer.path = circlePath.CGPath
        self.layer.mask = shapeLayer
    }
}

extension UIImage{
    /* 
    - (UIImage*)scaleToSizeKeepAspect:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    
    CGFloat ws = size.width/self.size.width;
    CGFloat hs = size.height/self.size.height;
    
    if (ws > hs) {
    ws = hs/ws;
    hs = 1.0;
    } else {
    hs = ws/hs;
    ws = 1.0;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(size.width/2-(size.width*ws)/2,
    size.height/2-(size.height*hs)/2, size.width*ws,
    size.height*hs), self.CGImage);
    
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
    }
    */
    func scaleToSizeKeepAspect(newSize:CGSize) -> UIImage
    {
        UIGraphicsBeginImageContext(newSize)
        var widthRatio:CGFloat = newSize.width / self.size.width
        var heightRatio:CGFloat = newSize.height / self.size.height
        
        if widthRatio > heightRatio
        {
            widthRatio = heightRatio / widthRatio
            heightRatio = 1.0
        }
        else
        {
            heightRatio = widthRatio / heightRatio
            widthRatio = 1.0
        }
        
        let context:CGContextRef = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, 0.0, newSize.height)
        CGContextScaleCTM(context, 1.0, -1.0)
        let rect = CGRectMake(newSize.width / 2 - (newSize.width * widthRatio) / 2, newSize.height / 2 - (newSize.height - heightRatio) / 2, newSize.width * widthRatio, newSize.height * heightRatio)
        CGContextDrawImage(context, rect, self.CGImage)
        
        let scaledImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func fixOrientation() -> UIImage
    {
        let selfOrientation = self.imageOrientation
        
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        
        var transform = CGAffineTransformIdentity
        
        switch selfOrientation
        {
        case .Up:
            return self
        case .Down:
            fallthrough
        case .DownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case .Left:
            fallthrough
        case .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        case .Right:
            fallthrough
        case .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
        default: break
        }
        
        
        switch selfOrientation
        {
        case .UpMirrored:
            fallthrough
        case .DownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        case .LeftMirrored:
            fallthrough
        case .RightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        default: break
        }
        
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above
        
        var context = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), CGImageGetBitsPerComponent(self.CGImage), 0, CGImageGetColorSpace(self.CGImage), CGImageGetBitmapInfo(self.CGImage))
        
        CGContextConcatCTM(context, transform)
        
        switch selfOrientation
        {
        case .Left:
            fallthrough
        case .LeftMirrored:
            fallthrough
        case .Right:
            fallthrough
        case .RightMirrored:
            CGContextDrawImage(context, CGRectMake(0, 0, self.size.height, self.size.width), self.CGImage) //once again.. switch
        default:
            CGContextDrawImage(context, CGRectMake(0, 0, self.size.width, self.size.height), self.CGImage)
        }
        
        // And now we just create a new UIImage from the drawing context
        
        let imageRef:CGImageRef = CGBitmapContextCreateImage(context)
        
        if let toReturnFixed:UIImage = UIImage(CGImage: imageRef)
        {
            return toReturnFixed
        }
        
        // if By some reason could not create image
        return self;
    }
}

extension UIViewController
{
    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
        let comparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
        
        switch comparisonResult
        {
        case .OrderedSame, .OrderedDescending: // iOS 8 and More
            let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
            let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
            alertController.addAction(closeAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
    
        case .OrderedAscending: //iOS 7 and less
            UIAlertView(title: alertTitle, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle).show()
            
           
        }
    }
}
