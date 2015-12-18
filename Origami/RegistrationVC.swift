//
//  RegistrationVC.swift
//  Origami
//
//  Created by CloudCraft on 12/18/15.
//  Copyright © 2015 CloudCraft. All rights reserved.
//

import UIKit

class RegistrationVC: UIViewController, UITextFieldDelegate, UIScrollViewDelegate {

    var firstNameTF:UITextField?
    var lastNameTF:UITextField?
    var emailTF:UITextField?
    var passwordTF:UITextField?
    var registerButton:UIButton?
    lazy var tapRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "tapGestureAction:")
    
    @IBOutlet weak var containerScrollView:UIScrollView!
    @IBOutlet weak var topLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.requireGestureRecognizerToFail(containerScrollView.panGestureRecognizer)

        topLabel.text = "RegistrationScreenTitle".localizedWithComment("")
        
        self.view.backgroundColor = kDayNavigationBarBackgroundColor
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardNotification:", name: UIKeyboardWillHideNotification, object: nil)
        
        if #available (iOS 8.0, *)
        {
            
        }
        else
        {
            NSNotificationCenter.defaultCenter().addObserver(self, selector:"orientationChanged:", name:UIDeviceOrientationDidChangeNotification, object:nil);
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        addSubviewsToScrollView()
    }
    

    
    private func addSubviewsToScrollView()
    {
        let textFieldsFrame = CGRectMake(0, 0, 200.0, 40.0) // used to set sizes of UITextFields,  later the layout constraints will configure actual positions of each textField
        let textFieldLeftViewMarginFrame = CGRectMake(0,0,10.0, 40.0) // user to make left text margin for textFields
        let backGroundWhiteTextFieldColor = kWhiteColor
        let textFieldCornerRadius = CGFloat(7.0)
        
        let currentScrollViewBounds = containerScrollView.bounds
        let height = max(330.0, currentScrollViewBounds.size.height)
        
        containerScrollView.contentSize = CGSizeMake(currentScrollViewBounds.size.width, height)
        let contentSize = containerScrollView.contentSize
        /* container view is used because UIStackView is only available in iOS 9 and later... */
        let containerView = UIView(frame: CGRectMake(0.0, 0.0, contentSize.width, contentSize.height))
        containerView.addGestureRecognizer(tapRecognizer)
        containerView.tag = 1
        //WARNING: remove this line for production
        //containerView.backgroundColor = UIColor.lightGrayColor()
        
        containerScrollView.addSubview(containerView)
        
        let nameField = UITextField(frame:textFieldsFrame)
        let lastNameField = UITextField(frame: textFieldsFrame)
        let emailField = UITextField(frame: textFieldsFrame)
        let passwordField = UITextField(frame:textFieldsFrame)
        
        emailField.keyboardType = .EmailAddress
        passwordField.secureTextEntry = true
        
        nameField.layer.cornerRadius = textFieldCornerRadius
        lastNameField.layer.cornerRadius = textFieldCornerRadius
        emailField.layer.cornerRadius = textFieldCornerRadius
        passwordField.layer.cornerRadius = textFieldCornerRadius
        
        //setup left margin for textfields
        let leftView1 = UIView(frame: textFieldLeftViewMarginFrame)
        let leftView2 = UIView(frame: textFieldLeftViewMarginFrame)
        let leftView3 = UIView(frame: textFieldLeftViewMarginFrame)
        let leftView4 = UIView(frame: textFieldLeftViewMarginFrame)
        
        nameField.leftViewMode = .Always
        nameField.leftView = leftView1
        lastNameField.leftViewMode = .Always
        lastNameField.leftView = leftView2
        emailField.leftViewMode = .Always
        emailField.leftView = leftView3
        passwordField.leftViewMode = .Always
        passwordField.leftView = leftView4
        
        nameField.translatesAutoresizingMaskIntoConstraints = false
        lastNameField.translatesAutoresizingMaskIntoConstraints = false
        emailField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        passwordField.backgroundColor = backGroundWhiteTextFieldColor
        emailField.backgroundColor = backGroundWhiteTextFieldColor
        nameField.backgroundColor = backGroundWhiteTextFieldColor
        lastNameField.backgroundColor = backGroundWhiteTextFieldColor
        
        firstNameTF = nameField
        lastNameTF = lastNameField
        emailTF = emailField
        passwordTF = passwordField
        
        containerView.addSubview(nameField)
        containerView.addSubview(lastNameField)
        containerView.addSubview(emailField)
        containerView.addSubview(passwordField)
        
        let startRegistrationButton = UIButton(type: .System)
        startRegistrationButton.tintColor = kWhiteColor
        startRegistrationButton.setTitle("Register".localizedWithComment(""), forState: .Normal)
        startRegistrationButton.backgroundColor = UIColor.clearColor()
        startRegistrationButton.sizeToFit()
        startRegistrationButton.translatesAutoresizingMaskIntoConstraints = false
        startRegistrationButton.addTarget(self, action: "registrationButtonAction:", forControlEvents: .TouchUpInside)
        
        registerButton = startRegistrationButton
        containerView.addSubview(startRegistrationButton)
        
        addConstraintsToSubviews([nameField, lastNameField, emailField, passwordField, startRegistrationButton] , inView:containerView)
        
        
        checkRegisterButtonEnabled()
        
        firstNameTF?.delegate = self
        lastNameTF?.delegate = self
        emailTF?.delegate = self
        passwordTF?.delegate = self
        
    }
    
    private func addConstraintsToSubviews(subviews:[UIView], inView parentView:UIView)
    {
        if let button = subviews.last as? UIButton
        {
            let centerXConstraint = NSLayoutConstraint(item: button, attribute: .CenterX, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
            let buttonHeightConstraint = NSLayoutConstraint(item: button, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 44.0)
            let bottomMarginConstraint = NSLayoutConstraint(item: parentView, attribute: NSLayoutAttribute.Bottom, relatedBy: .Equal, toItem: button, attribute: .Bottom, multiplier: 1.0, constant: 16.0)
            
            parentView.addConstraints([centerXConstraint, buttonHeightConstraint, bottomMarginConstraint])
        }
        
        var currentOffset = CGFloat(30.0)
        let textViewHeight = CGFloat(40.0)
        
        ConstraintsLoop: for aView in subviews //labeled loop
        {
            guard let textField = aView as? UITextField else
            {
                print(" Finished iterating over text fields")
                break ConstraintsLoop
            }
            
            print("adding constraints to textfield")
            let widthConstraint = NSLayoutConstraint(item: textField, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 220.0)
            let heightConstraint = NSLayoutConstraint(item: textField, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: textViewHeight)
            
            let centerXConstraint = NSLayoutConstraint(item: textField, attribute: .CenterX, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
            
            let topMarginConstraint = NSLayoutConstraint(item: textField, attribute: .Top, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1.0, constant: currentOffset)
            
            currentOffset += textViewHeight + 24.0
            
            parentView.addConstraints([widthConstraint, heightConstraint, centerXConstraint, topMarginConstraint])
            
        }
        
        if currentOffset > 30.0 //did add some constraints to text fields
        {
            //add placeholders for text fields
            print("assigning placeholders to text fields")
            
            let placeHolders = ["firstName".localizedWithComment(""),
                                "lastName".localizedWithComment(""),
                                "email".localizedWithComment(""),
                                "password".localizedWithComment("")
            ]
            
            var index = 0
            for aSubView in subviews
            {
                if let textField = aSubView as? UITextField
                {
                    setPlaceHolder(placeHolders[index], forTextField: textField)
                    
                    index += 1
                }
            }
        }
    }
    
    private func setPlaceHolder(placeHolder:String, forTextField textField:UITextField)
    {
        textField.placeholder = placeHolder
    }
    
    func tapGestureAction(recognizer:UITapGestureRecognizer)
    {
        self.view.endEditing(false)
        
        checkRegisterButtonEnabled()
    }
    
    private func checkRegisterButtonEnabled()
    {
        guard let regButton = registerButton else
        {
            return
        }
        
        regButton.enabled = false
        
        if  let name = firstNameTF?.text where name.characters.count > 0,
            let lastName = lastNameTF?.text where lastName.characters.count > 0,
            let email = emailTF?.text where email.characters.count > 0,
            let password = passwordTF?.text where password.characters.count > 0
        {
            regButton.enabled = true
        }
    }
    
    
    func handleKeyboardNotification(notification:NSNotification)
    {
        if let notifInfo = notification.userInfo
        {
            //prepare needed values
            let keyboardFrame = notifInfo[UIKeyboardFrameEndUserInfoKey]!.CGRectValue//()
            var keyboardHeight = keyboardFrame.size.height
            
            //damn iOS 7 and before for theese keyboard dimensions
            if #available (iOS 8.0, *)
            {
                
            }
            else
            {
                //detect proper orientation
                switch UIDevice.currentDevice().orientation
                {
                    case .LandscapeLeft, .LandscapeRight:
                        keyboardHeight = keyboardFrame.size.width
                    default:
                        break
                }
            }
//            let animationTime = notifInfo[UIKeyboardAnimationDurationUserInfoKey]! as! NSTimeInterval
//            let options = UIViewAnimationOptions(rawValue:UInt((notifInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16))
            
            var insets = UIEdgeInsetsZero
            
            if notification.name == UIKeyboardWillShowNotification
            {
//                if let textField = passwordTF
//                {
//                    let mainViewHeight = self.view.bounds.size.height
//                    let keyboardTop = mainViewHeight - keyboardHeight
//                    let pointInScrollViewContainerView = CGPointMake(CGRectGetMinX(textField.frame), CGRectGetMaxY(textField.frame))
//                    let pointInMainView = textField.superview!.convertPoint(pointInScrollViewContainerView, toView: self.view)
//                    
//                    
//                    
//                    let differenceInYAxis = pointInMainView.y - keyboardTop
//                    if differenceInYAxis > 0
//                    {
//                        insets.bottom = differenceInYAxis //make  contentView inside scrollview scrollable
//                        //NOTE:  it automatically scrolls password field upwards when keyboard appears - on iPhone 4
//                    }
//                }
                
                insets.bottom = keyboardHeight + 8.0 //make  contentView inside scrollview scrollable
                //NOTE:  it automatically scrolls password field upwards when keyboard appears - on iPhone 4

            }
            
            containerScrollView.contentInset = insets
            
        }
    }
    
    //MARK: - 
    func registrationButtonAction(sender:UIButton)
    {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        checkRegisterButtonEnabled()
        return true
    }
    
    
    //MARK: - device rotation
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        if let containerView = containerScrollView.viewWithTag(1)
        {
            containerView.removeFromSuperview()
        }
        
        coordinator.animateAlongsideTransition({ (coordinatorContext) -> Void in
            
            }) { [weak self] (coordinatorContext) -> Void in
                if let weakSelf = self
                {
                    weakSelf.addSubviewsToScrollView()
                }
        }
        
    }
    
    func orientationChanged(notification:NSNotification)
    {
        if let containerView = containerScrollView.viewWithTag(1)
        {
            containerView.removeFromSuperview()
        }
        addSubviewsToScrollView()
    }
    
}
