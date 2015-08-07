//
//  FrameCounter.swift
//  Origami
//
//  Created by CloudCraft on 16.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

class FrameCounter
{
    class func countFrameForElements(elements:[Element], forRectWidth targetWidth:CGFloat) -> [CGRect]
    {
        var elementFrames = [CGRect]()
        let elementsCount = elements.count
        if elementsCount > 0
        {
            let interItemSpace:CGFloat = 5.0
            let itemHeight:CGFloat = 100.0
            var xOrigin:CGFloat = 5.0
            var yOrigin:CGFloat = 0.0
            
            
            //fill frames array
            for var counter = 0; counter < elements.count; counter++
            {
                var lvFrameWidth:CGFloat = 100.0
                let element = elements[counter]
                if DataSource.sharedInstance.getSubordinateElementsForElement(element.elementId?.integerValue).count > 0
                {
                    lvFrameWidth = 200.0
                }
                
                var elementFrame = CGRectMake(xOrigin + interItemSpace, yOrigin + interItemSpace, lvFrameWidth, itemHeight)
                
                let maxX = CGRectGetMaxX(elementFrame)
                
                xOrigin = maxX //next element will be positioned to the right
                
                // or
                if maxX >= targetWidth - 10.0// next element will be positioned at the next line, leftmost
                {
                    yOrigin += itemHeight //(itemHeight - interItemSpace)
                    xOrigin = 5.0
                    elementFrame = CGRectMake(xOrigin + interItemSpace, yOrigin + interItemSpace, lvFrameWidth, itemHeight)
                }
                
                elementFrames.append(elementFrame)
            }
            
            // detect maximum height value
            let lastFrame = elementFrames.last!
            let maxY = CGRectGetMaxY(lastFrame)
            let frameToReturn = CGRectMake(0, 0, targetWidth, maxY)
            //println("\(frameToReturn)")
            
            return elementFrames
        }
        else
        {
            return elementFrames
        }
    }
    
    class func calculateFrameForTextViewWithFont(textFont:UIFont , text:String, targetWidth:CGFloat) -> CGSize
    {
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraphStyle.lineSpacing = 10//.textFont.lineHeight
        
        let maximumLabelSize = CGSize(width: targetWidth /*Double(textView.frame.size.width-100.0)*/, height: CGFloat.max)
        let drawOptions =  NSStringDrawingOptions.UsesLineFragmentOrigin
        let attribute = [NSFontAttributeName : textFont, NSParagraphStyleAttributeName : paragraphStyle]
        let str = NSString(string: text)
        
        
        let labelBounds = str.boundingRectWithSize(maximumLabelSize,
            options: drawOptions, //NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: attribute,
            context: nil)
        
        let roundedWidth = ceil(labelBounds.size.width)
        let roundedHeight = ceil(labelBounds.size.height)
        let roundedSize = CGSizeMake(roundedWidth, roundedHeight)
        
        return roundedSize
    }
    
    class func getCurrentTraitCollection() -> UITraitCollection
    {
        let traitCollection = UIScreen.mainScreen().traitCollection
        return traitCollection
    }
    
}
