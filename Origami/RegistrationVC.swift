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
    
    @IBOutlet weak var containerScrollView:UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        addSubviewsToScrollView()
    }
    

    
    private func addSubviewsToScrollView()
    {
        let textFieldsFrame = CGRectMake(0, 0, 200.0, 40.0) // used to set sizes of UITextFields,  later the layout constraints will configure actual positions of each textField
        let textFieldLeftViewMarginFrame = CGRectMake(0,0,10.0, 40.0) // user to make left text margin for textFields
        
        let textFieldCornerRadius = CGFloat(7.0)
        
        let currentScrollViewBounds = containerScrollView.bounds
        
        containerScrollView.contentSize = currentScrollViewBounds.size
        /* container view is used because UIStackView is only available in iOS 9 and later... */
        let containerView = UIView(frame: currentScrollViewBounds)
        
        //WARNING: remove this line for production
        containerView.backgroundColor = UIColor.lightGrayColor()
        
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
        registerButton = startRegistrationButton
        containerView.addSubview(startRegistrationButton)
        
        addConstraintsToSubviews([nameField, lastNameField, emailField, passwordField, startRegistrationButton] , inView:containerView)
        
    }
    
    private func addConstraintsToSubviews(subviews:[UIView], inView parentView:UIView)
    {
        if let button = subviews.last as? UIButton
        {
            let centerXConstraint = NSLayoutConstraint(item: button, attribute: .CenterX, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
            let bottomMarginConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.Bottom, relatedBy: .Equal, toItem: parentView, attribute: .Bottom, multiplier: 1.0, constant: 16.0)
            
            parentView.addConstraints([centerXConstraint, bottomMarginConstraint])
        }
        
        var currentOffset = CGFloat(30.0)
        let textViewHeight = CGFloat(40.0)
        for aView in subviews
        {
            guard let textField = aView as? UITextField else
            {
                print(" Finished iterating over text fields")
                return
            }
            
            let widthConstraint = NSLayoutConstraint(item: textField, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: 220.0)
            let heightConstraint = NSLayoutConstraint(item: textField, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: textViewHeight)
            
            let centerXConstraint = NSLayoutConstraint(item: textField, attribute: .CenterX, relatedBy: .Equal, toItem: parentView, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
            
            let topMarginConstraint = NSLayoutConstraint(item: textField, attribute: .Top, relatedBy: .Equal, toItem: parentView, attribute: .Top, multiplier: 1.0, constant: currentOffset)
            
            currentOffset += textViewHeight + 24.0
            
            parentView.addConstraints([widthConstraint, heightConstraint, centerXConstraint, topMarginConstraint])
        }
    }
    
    private func setPlaceHoldersForEmptyTextFields()
    {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
