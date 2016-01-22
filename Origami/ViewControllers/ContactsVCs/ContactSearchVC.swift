//
//  ContactSearchVC.swift
//  Origami
//
//  Created by CloudCraft on 02.11.15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

class ContactSearchVC: UIViewController, UIAlertViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var userAvatarView:UIImageView?
    @IBOutlet weak var userNameLabel:UILabel?
    @IBOutlet weak var firstNameLabel:UILabel?
    @IBOutlet weak var lastNameLabel:UILabel?
    @IBOutlet weak var emailTextField:UITextField?
    @IBOutlet var bottomTextFieldConstraint:NSLayoutConstraint!
    
    var addButtonItem:UIBarButtonItem?
    var defaultPosition:CGFloat = 0.0
    var currentFoundContact:Contact?{
        didSet{
            if currentFoundContact == nil
            {
                firstNameLabel?.attributedText = NSAttributedString(string: "first name", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor() ])
                lastNameLabel?.attributedText = NSAttributedString(string: "lasts name", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor() ])
                userNameLabel?.text = nil
                userAvatarView?.image = UIImage(named: "icon-contacts")
                addButtonItem?.enabled = false
            }
            else
            {
                if let firstName =  currentFoundContact?.firstName
                {
                   firstNameLabel?.attributedText = NSAttributedString(string:firstName, attributes: [NSForegroundColorAttributeName : UIColor.grayColor() ])
                }
                else
                {
                    firstNameLabel?.attributedText = NSAttributedString(string: "first name", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor() ])
                }
                if let lastName = currentFoundContact?.lastName
                {
                    lastNameLabel?.attributedText = NSAttributedString(string: lastName, attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor() ])
                }
                else
                {
                    lastNameLabel?.attributedText = NSAttributedString(string: "lasts name", attributes: [NSForegroundColorAttributeName : UIColor.lightGrayColor() ])
                }
                
                userNameLabel?.text = currentFoundContact?.userName
                
                addButtonItem?.enabled = true
            }
        }
    }
    
    weak var delegate:ContactsSearcherDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureNavigationButtons()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTextField:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleTextField:", name: UIKeyboardWillHideNotification, object: nil)
        defaultPosition = bottomTextFieldConstraint.constant
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil;
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func gestureRecognizerShouldBegin(recognizer:UIGestureRecognizer) -> Bool
    {
        if recognizer == self.navigationController?.interactivePopGestureRecognizer
        {
            return false
        }
        return true
    }
    
    func configureNavigationButtons()
    {
        //left button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonAction:")
        self.navigationItem.leftBarButtonItem = doneButton
        //right button
        addButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addContactButtonAction:")
        addButtonItem?.enabled = false
        self.navigationItem.rightBarButtonItem = addButtonItem!
    }
    
    func addContactButtonAction(sender:UIBarButtonItem)
    {
        guard let _ = self.delegate else
        {
            self.navigationController?.popViewControllerAnimated(true)
            return
        }
        
        showAlertForProceedingOrCancel()
    }
    
    func doneButtonAction(sender:UIBarButtonItem)
    {
        guard let _ = self.delegate else
        {
            self.navigationController?.popViewControllerAnimated(true)
            return
        }
        self.delegate?.contactsSearcherDidCancelSearch(self)
        
    }
    
    func showAlertForProceedingOrCancel()
    {
        let alertMessage = "Continue search?"
        let cancelButtonTitle = "Dismiss"
        let continueButtonTitle = "Add and Continue"
        
        if #available (iOS 8.0, *)
        {
            let alertActionCancel = UIAlertAction(title: cancelButtonTitle, style: .Cancel, handler: {[weak self] (action) -> Void in
                guard let weakSelf = self else
                {
                    return
                }
                guard let contact = weakSelf.currentFoundContact else
                {
                    weakSelf.delegate?.contactsSearcherDidCancelSearch(weakSelf)
                    return
                }
                
                weakSelf.delegate?.contactsSearcher(weakSelf, didFindContact: contact, willDismiss: true)
            })
            
            let alertActionProceed = UIAlertAction(title: continueButtonTitle, style: .Default, handler: {[weak self] (action) -> Void in
                guard let weakSelf = self else
                {
                    return
                }
                guard let contact = weakSelf.currentFoundContact else
                {
                    weakSelf.delegate?.contactsSearcherDidCancelSearch(weakSelf)
                    return
                }
                
                weakSelf.delegate?.contactsSearcher(weakSelf, didFindContact: contact, willDismiss: false)
            })
            
            
            let alertController = UIAlertController(title: alertMessage, message: nil, preferredStyle: .Alert)
            
            alertController.addAction(alertActionCancel)
            alertController.addAction(alertActionProceed)
            
            self.presentViewController(alertController, animated: false, completion: nil)
            
        }
        else
        {
            let alertView = UIAlertView(title: alertMessage, message: "", delegate: self, cancelButtonTitle: cancelButtonTitle, otherButtonTitles:continueButtonTitle)
            alertView.show()
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int)
    {
        if buttonIndex == alertView.cancelButtonIndex
        {
            self.delegate?.contactsSearcherDidCancelSearch(self)
        }
        else
        {
            if let contact = self.currentFoundContact
            {
                self.delegate?.contactsSearcher(self, didFindContact: contact, willDismiss: false)
            }
            else
            {
                self.delegate?.contactsSearcherDidCancelSearch(self)
            }
        }
    }
    
    //MARK: -
  
    
    func startSearchingForContactByEmail(email:String)
    {
        DataSource.sharedInstance.searchForContactByEmail(email) { [weak self](foundContact) -> () in
            if let weakSelf = self
            {
                if let contact = foundContact
                {
                    weakSelf.currentFoundContact = contact
                }
                else
                {
                    weakSelf.currentFoundContact = nil
                }
            }
        }
        
    }
    
    //MARK: - UITextViewDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let text = textField.text
        {
            if stringIsValidEmail(text)
            {
                startSearchingForContactByEmail(text)
            }
        }
        
        textField.resignFirstResponder()
        textField.attributedText = NSAttributedString(string: "email", attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        textField.text = nil
        return true
    }
    
    //MARK: - 
    
    private func stringIsValidEmail(string:String) -> Bool
    {
        let laxString = NSString(string: "^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$")
        let predicate = NSPredicate(format: "SELF MATCHES %@",laxString)
        let boolToReturn = predicate.evaluateWithObject(string)
        return boolToReturn
    }
//    -(BOOL) stringIsValidEmail:(NSString *)checkString //example taken from stackoverflow.com
//    {
//    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
//    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
//    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
//    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
//    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
//    return [emailTest evaluateWithObject:checkString];
//    }
    
    //MARK: -
    func handleTextField(notification:NSNotification)
    {
        guard let notifInfo = notification.userInfo else
        {
            return
        }
        
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue//()
            let keyboardHeight = keyboardFrame.size.height
            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
            let options = UIViewAnimationOptions(rawValue:UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
        
        
        let notifName = notification.name
        switch notifName
        {
        case UIKeyboardWillShowNotification:
            bottomTextFieldConstraint.constant = keyboardHeight
        case UIKeyboardWillHideNotification:
            bottomTextFieldConstraint.constant = defaultPosition
        default:
            break
        }
        
            
            
        UIView.animateWithDuration(animationTime,
            delay: 0.0,
            options: options,
            animations: {  [weak self]  in
                if let weakSelf = self
                {
                    weakSelf.view.setNeedsLayout()
                }
            },
            completion: nil)
        
    }
    

}
