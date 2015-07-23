//
//  ElementTextEditingVC.swift
//  Origami
//
//  Created by CloudCraft on 22.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import UIKit

class ElementTextEditingVC: UIViewController, UITextViewDelegate {

    
    @IBOutlet weak var editorTextView: UITextView!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var toolbarToBottomConstraint: NSLayoutConstraint!
    
    var editingElement:Element = Element()
    var isEditingElementTitle = false
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        editorTextView.delegate = self
        // Do any additional setup after loading the view.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillHideNotification, object: nil)
        if isEditingElementTitle
        {
            editorTextView.text = editingElement.title as? String
        }
        else
        {
            editorTextView.text = editingElement.details as? String
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        editorTextView.becomeFirstResponder()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func submitPressed(sender:UIBarButtonItem) {
        if isEditingElementTitle
        {
            if editingElement.title != editorTextView.text
            {
                let copyElement = editingElement.createCopy() //Element(info: editingElement.toDictionary() as! [String : AnyObject])
                copyElement.title = editorTextView.text as NSString
                DataSource.sharedInstance.editElement(copyElement) {[weak self] (edited) -> () in
                    if edited
                    {
                        if let aSelf = self
                        {
                            aSelf.editingElement.title = copyElement.title
                            aSelf.sendReloadElementTextViewCellMessageForTitle(true)
                            aSelf.cancelPressed(self!.cancelBarButtonItem)
                        }
                    }
                    else
                    {
                        if let aSelf = self
                        {
                            aSelf.cancelPressed(self!.cancelBarButtonItem)
                        }
                    }
                }
            }
            else
            {
                cancelPressed(cancelBarButtonItem)
            }
        }
        else
        {
            if editingElement.details != editorTextView.text
            {
                let copyElement = editingElement.createCopy()//Element(info: editingElement.toDictionary() as! [String : AnyObject])
                copyElement.details = editorTextView.text as NSString
                DataSource.sharedInstance.editElement(copyElement) {[weak self] (edited) -> () in
                    if edited
                    {
                        if let aSelf = self
                        {
                            aSelf.editingElement.details = copyElement.details
                            aSelf.sendReloadElementTextViewCellMessageForTitle(false)
                            aSelf.cancelPressed(self!.cancelBarButtonItem)
                        }
                    }
                    else
                    {
                        if  let aSelf = self
                        {
                            aSelf.cancelPressed(self!.cancelBarButtonItem)
                        }
                    }
                }
            }
            else
            {
                cancelPressed(cancelBarButtonItem)
            }
        }
    }
    
    func sendReloadElementTextViewCellMessageForTitle(shouldReloadTitleCell:Bool)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("TextEditorSubmittedNewText", object: self, userInfo: ["test":"success"] )
    }
    
    
    @IBAction func cancelPressed(sender:UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func handleKeyboardNotification(notification:NSNotification) {
        
        if let notifInfo = notification.userInfo
        {
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue()
            let keyboardHeight = keyboardFrame.size.height
            //let animationOptionCurveNumber = notifInfo[UIKeyboardAnimationCurveUserInfoKey]! as! NSNumber
            //let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions.fromRaw(   animationOptionCurveNumber)
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            var keyboardIsToShow = false
            if notification.name == UIKeyboardWillShowNotification
            {
                keyboardIsToShow = true
                toolbarToBottomConstraint.constant = keyboardHeight
            }
            else
            {
                toolbarToBottomConstraint.constant = 0.0
            }
            
            
            UIView.animateWithDuration(animationTime,
                delay: 0.0,
                options: options,
                animations: {  [weak self]  in
                    self?.view.layoutIfNeeded()
                    
                },
                completion: { [weak self]  (finished) -> () in
                    
                })
        }
    }

}
