//
//  ElementTitleAndDetailsEditingVC.swift
//  Origami
//
//  Created by CloudCraft on 27.07.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementTitleAndDetailsEditingVC: UIViewController, UITextViewDelegate {

    var editingElement:Element?
    var shouldEditTitle:Bool?
    
    
    @IBOutlet var titleTextView:UITextView!
    @IBOutlet var detailsTextView:UITextView!
    @IBOutlet var tapRecognizer:UITapGestureRecognizer!
    @IBOutlet var textViewBototmConstraint:NSLayoutConstraint!
    @IBOutlet var textViewTopConstraint:NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        titleTextView.text = editingElement?.title as? String
        detailsTextView.text = editingElement?.details as? String
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillHideNotification, object: nil)
        
        titleTextView.delegate = self
        detailsTextView.delegate = self
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if shouldEditTitle != nil
        {
            if shouldEditTitle!
            {
                self.titleTextView.becomeFirstResponder()
            }
            else
            {
                self.detailsTextView.becomeFirstResponder()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func cancelPressed(sender:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func handleKeyboardNotification(notification:NSNotification?)
    {
        if let notif = notification, notifInfo = notif.userInfo
        {
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue()
            let keyboardHeight = keyboardFrame.size.height
            //let animationOptionCurveNumber = notifInfo[UIKeyboardAnimationCurveUserInfoKey]! as! NSNumber
            //let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions.fromRaw(   animationOptionCurveNumber)
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            var keyboardIsToShow = false
            if notif.name == UIKeyboardWillShowNotification
            {
                keyboardIsToShow = true
                if firstResponderTextView() == detailsTextView
                {
                    textViewBototmConstraint.constant = keyboardHeight + 8.0
                   // textViewTopConstraint.constant -= keyboardHeight
                }
                
            }
            else
            {
                if firstResponderTextView() == detailsTextView
                {
                    textViewBototmConstraint.constant = 0.0
                    //textViewTopConstraint.constant += keyboardHeight
                }
                
            }
            
            
            
            UIView.animateWithDuration(animationTime,
                delay: 0.0,
                options: options,
                animations: {  [weak self]  in
                    if let aSelf = self
                    {
                        aSelf.view.layoutIfNeeded()
                    }
                },
                completion: { [weak self]  (finished) -> () in
                    
                })
            
        }
    }
    
    func firstResponderTextView() -> UITextView?
    {
        if titleTextView.isFirstResponder()
        {
            return titleTextView
        }
        else if detailsTextView.isFirstResponder()
        {
            return detailsTextView
        }
        else
        {
            return nil
        }
        
    }
    
    //MARK: UITextViewDelegate
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"
        {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
    
    
}
