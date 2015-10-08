//
//  Extensions.swift
//  Origami
//
//  Created by CloudCraft on 08.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

import UIKit

extension NSDate
{
    class func dummyDate() -> NSString
    {
        return "/Date(0)/"
    }
    
    func dateForServer() -> NSString?
    {
        let utcTimeZone = NSTimeZone(abbreviation: "UTC")
        
        let gmtOffset = utcTimeZone?.secondsFromGMTForDate(self)
        if gmtOffset == nil
        {
            return nil
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
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    func timeDateStringShortStyle() -> NSString
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    
    func timeDateStringForMediaName() -> String
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd_HH-MM-SS"
        let stringToReturn = dateFormatter.stringFromDate(self)
        
        return stringToReturn
    }
    
    func timeStringShortStyle() -> String
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    
    func dateStringShortStyle() -> String
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    
    func dateStringMediumStyle() -> String?
    {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        
        let toReturn = dateFormatter.stringFromDate(self)
        
        return toReturn
    }
    
    func lessThanDayAgo() -> Bool
    {
        let cal = NSCalendar.currentCalendar();
        let flags:NSCalendarUnit = [ NSCalendarUnit.Year , NSCalendarUnit.Month , NSCalendarUnit.Day]
        let date = NSDate()
        
//        let todayComps = cal.components(flags, fromDate:  date)
        //print("today componetns day: \(todayComps.day)")
        let components = cal.components(flags, fromDate: date.dateByAddingTimeInterval(-1.days))
        //print("today componetns day: \(components.day)")
//        
//        let selfComponents = cal.components(flags, fromDate: self)
        //print(" self  .day = \(selfComponents.day)")
        if let yesterday = cal.dateFromComponents(components)
        {
            let comprarison = self.compareDateOnly(yesterday);
            
            let toReturn = (comprarison != .OrderedAscending);
            
            return toReturn;
            
        }
        
        return false
    }
    
    func compareDateOnly(dateToCompare:NSDate) -> NSComparisonResult
    {
        let flags:NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month , NSCalendarUnit.Day]
        
        if let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        {
            let components = calendar.components(flags, fromDate: dateToCompare)
            let componentsForSelf = calendar.components(flags, fromDate: self)
            if  let
                dateToCompareWithoutTime = calendar.dateFromComponents(components) ,
                selfDateToCompareWithoutTime = calendar.dateFromComponents(componentsForSelf)
            {
                let result = selfDateToCompareWithoutTime.compare(dateToCompareWithoutTime)
                return result
            }
        }
        
        return NSComparisonResult.OrderedSame
    }
}

extension Int {
    var days: NSTimeInterval {
        let DAY_IN_SECONDS = 60 * 60 * 24
        let aDays:Double = Double(DAY_IN_SECONDS) * Double(self)
        return aDays
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
        
        let preDateValueString = dateUTCstring.substringToIndex(lettersCount - 5) as NSString
        let newCount = preDateValueString.length
        if newCount < 3
        {
            return nil
        }
        
        let dateValueString = preDateValueString.substringToIndex(newCount - 3) as NSString
        
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
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .ShortStyle
        let toReturn = dateFormatter.stringFromDate(lvDate)
        
        return toReturn
    }
}

extension String
{
    func localizedWithComment(comment:String) -> String
    {
        let toReturnDebug = NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: self, comment: comment)
        return toReturnDebug
    }
    
    func dateFromServerDateString() -> NSDate?
    {
        let badCharacters = NSCharacterSet(charactersInString: "1234567890-+").invertedSet
        let dateUTCstring = self.stringByTrimmingCharactersInSet(badCharacters)
        
        let lettersCount = dateUTCstring.characters.count
        if lettersCount < 5
        {
            return nil
        }
        let stringIndex = dateUTCstring.endIndex.advancedBy(-5)
        
        let preDateValueString = dateUTCstring.substringToIndex(stringIndex)
        
        let newCount = preDateValueString.characters.count
        if newCount < 3
        {
            return nil
        }
        
        let nextStringIndex = preDateValueString.endIndex.advancedBy(-3)//advance(preDateValueString.endIndex, -3)
        
        let dateValueString = preDateValueString.substringToIndex(nextStringIndex)
        
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
        
        let dateFormatter = NSDateFormatter()
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
        if array.isEmpty
        {
            return nil
        }
        
        let mutableData = NSMutableData()// NSMutableData(capacity: array.count)
        for integer in array
        {
            var lvInteger = integer
            let lvOneByte = NSData(bytes: &lvInteger, length: 1)
            mutableData.appendData(lvOneByte)//appendData(lvOneByte)
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

    func scaleToSizeKeepAspect(newSize:CGSize) -> UIImage?
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
        
        if let context:CGContextRef = UIGraphicsGetCurrentContext()
        {
            CGContextTranslateCTM(context, 0.0, newSize.height)
            CGContextScaleCTM(context, 1.0, -1.0)
            let rect = CGRectMake(newSize.width / 2 - (newSize.width * widthRatio) / 2, newSize.height / 2 - (newSize.height - heightRatio) / 2, newSize.width * widthRatio, newSize.height * heightRatio)
            CGContextDrawImage(context, rect, self.CGImage)
            
            let scaledImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
        
            return scaledImage
        }
        
        UIGraphicsEndImageContext()
        return nil
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
        //CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), CGImageGetBitsPerComponent(self.CGImage), 0, CGImageGetColorSpace(self.CGImage), <#T##bitmapInfo: UInt32##UInt32#>)
        
        if let context = CGBitmapContextCreate(nil, Int(self.size.width), Int(self.size.height), CGImageGetBitsPerComponent(self.CGImage), 0, CGImageGetColorSpace(self.CGImage), CGImageGetBitmapInfo(self.CGImage).rawValue)
        {
        
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
            
            if let cgImageLV = CGBitmapContextCreateImage(context)
            {
                let toReturnFixed = UIImage(CGImage: cgImageLV)
//                if toReturnFixed != nil
//                {
                    return toReturnFixed
//                }
            
            }
        
            // if By some reason could not create image
            return self;
        }
        
        return self
    }
}

extension UIViewController
{
    func showAlertWithTitle(alertTitle:String, message:String, cancelButtonTitle:String)
    {
//        let comparisonResult = UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch)
//        
//        switch comparisonResult
//        {
//        case .OrderedSame, .OrderedDescending: // iOS 8 and More
        if #available (iOS 8.0, *)
        {
            let closeAction:UIAlertAction = UIAlertAction(title: cancelButtonTitle as String, style: .Cancel, handler: nil)
            let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .Alert)
            alertController.addAction(closeAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        else
        {
            UIAlertView(title: alertTitle, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle).show()
        }
    }
    
    func setAppearanceForNightModeToggled(nightModeOn:Bool)
    {
        UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.LightContent  //white text colour in status bar
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.toolbar.translucent = false
        
        //    UIApplication.sharedApplication().statusBarStyle = UIStatusBarStyle.Default  // black text colour in status bar
        
        if nightModeOn
        {
            self.navigationController?.navigationBar.barStyle = UIBarStyle.Default
            self.navigationController?.navigationBar.barTintColor = kBlackColor
            self.view.backgroundColor = kBlackColor
            self.navigationController?.toolbar.tintColor = kWhiteColor
            self.navigationController?.toolbar.barTintColor = kBlackColor
        }
        else
        {
            self.navigationController?.navigationBar.barStyle = UIBarStyle.Default
            self.navigationController?.navigationBar.barTintColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.4)
            self.view.backgroundColor = kWhiteColor
            self.navigationController?.toolbar.tintColor = kWhiteColor
            self.navigationController?.toolbar.barTintColor = kDayNavigationBarBackgroundColor.colorWithAlphaComponent(0.5)
        }
    }
    
    func homeButtonPressed(sender:UIBarButtonItem)
    {
        if let currentVCs = self.navigationController?.viewControllers
        {
            if let _ = currentVCs.first as? HomeVC
            {
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
            else
            {
                if let home = self.storyboard?.instantiateViewControllerWithIdentifier("HomeVC") as? HomeVC
                {
                    self.navigationController?.setViewControllers([home], animated: true)
                }
            }
        }
    }
}
