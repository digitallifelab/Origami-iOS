//
//  CustomViewControllerTransitions.swift
//  Origami
//
//  Created by CloudCraft on 23.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit
class FadeOpaqueAnimator : NSObject, UIViewControllerAnimatedTransitioning {
    
    
    var transitionDirection:FadedTransitionDirection = .FadeIn
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        if let containerView = transitionContext.containerView()
        {
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
            
            //let finalToFrame:CGRect = transitionContext.finalFrameForViewController(toVC!)
            
            if transitionDirection == .FadeIn
            {
                toVC!.view.alpha = 0.0
                containerView.insertSubview(toVC!.view, aboveSubview: fromVC!.view)
                
                UIView.animateWithDuration(transitionDuration(transitionContext),
                    delay: 0.0,
                    options: UIViewAnimationOptions.CurveEaseInOut,
                    animations: { () -> Void in
                        toVC!.view.alpha = 1.0
                    }, completion: { (finished) -> Void in
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                })
            }
            else if transitionDirection == .FadeOut
            {
                containerView.insertSubview(fromVC!.view, aboveSubview: toVC!.view)
                
                UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
                    fromVC!.view.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                })
            }
        }
    }
}



//MARK: --------
class MenuTransitionAnimator : NSObject, UIViewControllerAnimatedTransitioning
{
    var transitionDirection:FadedTransitionDirection = .FadeIn // used this enum to shorten enums quantity in project.  Better is to use some enum saying - "Display"<->"Hide"
    var shouldAnimate = true
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval
    {
        return 0.25
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning)
    {
        
        guard let containerView = transitionContext.containerView() else {
            print(" no container view to perform transition.\n")
            
            return
        }
        
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        let wholeFrame = containerView.bounds
        
        var currentDeviceIdiom:UIUserInterfaceIdiom = .Phone
        
    
        if #available (iOS 8.0, *)//FrameCounter.isLowerThanIOSVersion("8.0")
        {
            let currentTraitCollection = FrameCounter.getCurrentTraitCollection()
            currentDeviceIdiom  = currentTraitCollection.userInterfaceIdiom
        }
        else
        {
            currentDeviceIdiom = UIDevice.currentDevice().userInterfaceIdiom
        }
        
        var menuWidth:CGFloat = 210.0
        
        if currentDeviceIdiom == .Pad
        {
            menuWidth = 200.0
        }
        else
        {
            menuWidth = max(wholeFrame.size.width / 3.0, 200)
        }
        
        
        
        //prepare animation options
        var animationCurve = UIViewAnimationOptions.CurveEaseIn
        
        //perform the needed transition
        if transitionDirection == .FadeIn //show menu
        {
            //let hideMainViewFrame = CGRectOffset(fromVC!.view.frame, menuWidth, 0.0) // move to right HomeScreenVC`s view
            let menuFrame = CGRectMake(-menuWidth, 0, menuWidth, wholeFrame.size.height)
            toVC!.view.frame = menuFrame // now hidden to left
            
            containerView.insertSubview(toVC!.view, aboveSubview: fromVC!.view)
            
            if !shouldAnimate
            {
                toVC!.view.frame = CGRectOffset(menuFrame, menuWidth, 0.0)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                return
            }
            
            UIView.animateWithDuration(
                transitionDuration(transitionContext),
                delay: 0.0,
                options: animationCurve,
                animations: { () -> Void in
                
                //fromVC!.view.frame = hideMainViewFrame //move to right
                toVC!.view.frame = CGRectOffset(menuFrame, menuWidth, 0.0)//move to right
            },
                completion: { (finished) -> Void in
                    
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
        else //hide menu
        {
            animationCurve = .CurveEaseOut
            
            let toHideFrame = CGRectOffset(fromVC!.view.frame, -CGRectGetWidth(fromVC!.view.frame), 0.0)
            
            containerView.insertSubview(fromVC!.view, aboveSubview: toVC!.view)
            
            
            if !shouldAnimate
            {
                //toVC?.view.frame = wholeFrame //move to left HomeScreenVC
                fromVC!.view.frame = toHideFrame //move to left Menu VC
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                return
            }
            
            UIView.animateWithDuration(
                transitionDuration(transitionContext),
                delay: 0.0,
                options: animationCurve,
                animations: { () -> Void in
                
                    //toVC?.view.frame = wholeFrame //move to left HomeScreenVC
                    fromVC!.view.frame = toHideFrame //move to left Menu VC
                },
                completion: { (finished) -> Void in
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
    }
}

//MARK: ----

class menuRevealAnimator : MenuTransitionAnimator
{
    override func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let containerView = transitionContext.containerView()
            else{
                print(" no container view to perform transition.\n")
                
                return
        }
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        
        let wholeFrame = containerView.bounds
        
        var currentDeviceIdiom:UIUserInterfaceIdiom = .Phone
        
        
        if #available (iOS 8.0, *)//FrameCounter.isLowerThanIOSVersion("8.0")
        {
            let currentTraitCollection = FrameCounter.getCurrentTraitCollection()
            currentDeviceIdiom  = currentTraitCollection.userInterfaceIdiom
        }
        else
        {
            currentDeviceIdiom = UIDevice.currentDevice().userInterfaceIdiom
        }
        
        var menuWidth:CGFloat = 210.0
        
        if currentDeviceIdiom == .Pad
        {
            menuWidth = 200.0
        }
        else
        {
            menuWidth = max(wholeFrame.size.width / 3.0, 200)
        }
        
        
        
        //prepare animation options
        var animationCurve = UIViewAnimationOptions.CurveEaseIn
        
        //perform the needed transition
        if transitionDirection == .FadeIn //show menu
        {
            let hideMainViewFrame = CGRectOffset(fromVC!.view.frame, menuWidth, 0.0) // move to right HomeScreenVC`s view
            //let menuFrame = CGRectMake(-menuWidth, 0, menuWidth, wholeFrame.size.height)
            //toVC!.view.frame = menuFrame // now hidden to left
            
            containerView.insertSubview(toVC!.view, aboveSubview: fromVC!.view)
            
            if !shouldAnimate
            {
                fromVC!.view.frame = hideMainViewFrame//CGRectOffset(menuFrame, menuWidth, 0.0)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                return
            }
            
            UIView.animateWithDuration(
                transitionDuration(transitionContext),
                delay: 0.0,
                options: animationCurve,
                animations: { () -> Void in
                    
                    fromVC!.view.frame = hideMainViewFrame //move to right
                    //toVC!.view.frame = CGRectOffset(menuFrame, menuWidth, 0.0)//move to right
                },
                completion: { (finished) -> Void in
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
        else //hide menu
        {
            animationCurve = .CurveEaseOut
            
            let toHideFrame = CGRectOffset(fromVC!.view.frame, -CGRectGetWidth(fromVC!.view.frame), 0.0)
            
            containerView.insertSubview(fromVC!.view, aboveSubview: toVC!.view)
            
            
            if !shouldAnimate
            {
                //toVC?.view.frame = wholeFrame //move to left HomeScreenVC
                fromVC!.view.frame = toHideFrame //move to left Menu VC
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                return
            }
            
            UIView.animateWithDuration(
                transitionDuration(transitionContext),
                delay: 0.0,
                options: animationCurve,
                animations: { () -> Void in
                    
                    //toVC?.view.frame = wholeFrame //move to left HomeScreenVC
                    fromVC!.view.frame = toHideFrame //move to left Menu VC
                },
                completion: { (finished) -> Void in
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
    }

    
}


