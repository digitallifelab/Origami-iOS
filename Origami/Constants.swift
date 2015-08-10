//
//  Constants.swift
//  Origami
//
//  Created by CloudCraft on 04.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

let serverURL = "http://cloudcraftt1.cloudapp.net:8052/OrigamiWCFService/OrigamiService/"

let currentLogin = "CurrentUser"
let currentPassword = "CurrentPassword"

let tokenKey = "Token"
let firstNameKey = "FirstName"
let lastNameKey = "LastName"
let loginNameKey = "LoginName"
let passwordKey = "Password"
let NightModeKey = "NightModeOn"

//Users
let registerUserUrlPart = "RegisterUser"
let editUserUrlPart = "EditUser"
let loginUserUrlPart = "Login"
//Contacts
let allContactsURLPart = "GetContacts"
//Messages
let getAllMessagesPart = "GetMessages"
let sendMessageUrlPart = "SendElementMessage"
//Elements
let elementIdKey = "elementId"
let elementKey = "element"
let addElementUrlPart = "AddElement"
let getElementsUrlPart = "GetElements"
let editElementUrlPart = "EditElement"
let favouriteElementUrlPart = "SetFavoriteElement"
let passWhomelementUrlPart = "GetPassWhomIds"
let passElementUrlPart = "PassElement"
let passElementUserUrlPart = "userPassTo"
let deleteElementUrlPart = "DeleteElement"

//Attaches
let getAttachFileUrlPart = "GetAttachedFile"
let unAttachFileUrlPart = "RemoveFileFromElement"
let getElementAttachesUrlPart = "GetElementAttaches"
let attachToElementUrlPart = "AttachFileToElement"

////

let noUserTokenError = NSError(domain: "User Token", code: -55, userInfo: [NSLocalizedDescriptionKey:"NoUserToken".localizedWithComment("")])
//MARK:App-Wide colors
let kDaySignalColor = UIColor(red: 255.0/255.0, green: 64.0/255.0, blue: 129.0 / 255.0, alpha: 1.0)
let kNightSignalColor = UIColor(red: 244.0/255.0, green: 71.0/255.0, blue: 71.0/255.0, alpha: 1.0)
let kDayViewBackgroundColor = UIColor.whiteColor()//UIColor(red: 227.0/255.0, green: 242.0/255.0, blue: 253.0/255.0, alpha: 1.0)
let kDayNavigationBarBackgroundColor = UIColor(red: 33.0/255.0, green: 150.0/255.0, blue: 243.0/255.0, alpha: 1.0)

let kDayCellBackgroundColor = UIColor(red: 33.0/255.0, green: 150.0/255.0, blue: 243.0/255.0, alpha: 1.0)
let kWhiteColor = UIColor.whiteColor()
let kBlackColor = UIColor.blackColor()

//MARK:App-Wide colors end
let checkedCheckboxImage = UIImage(named: "icon-checked")?.imageWithRenderingMode(.AlwaysTemplate)
let unCheckedCheckboxImage = UIImage(named: "icon-unchecked")?.imageWithRenderingMode(.AlwaysTemplate)

let noImageIcon = UIImage(named: "icon-No-Image")

let HomeCellNormalDimension:CGFloat = 120.0
let HomeCellWideDimension:CGFloat = 250.0
let HomeCellVerticalSpacing:CGFloat = 10.0
let HomeCellHorizontalSpacing:CGFloat = 10.0
let MaximumLastMessagesCount:Int = 3

let All_New_Messages_Observation_ElementId:NSNumber = NSNumber(integer:-111)

let FinishedLoadingMessages = "MessagesFinishedLoading"


let kMenu_Buton_Tapped_Notification_Name = "MenuButtonTapped"
let kMenu_Switch_Night_Mode_Changed = "NightModeChanged"

//MARK: -- NotificationNames --

let kElementFavouriteButtonTapped = "ElementFavouriteButtonTapped"
let kElementActionButtonPressedNotification = "ElementActionButtonTapped"
let kElementEditTextNotification = "ElementEditTextTapped"
let kAttachFileDataLoadingCompleted = "AttachFileDataLoadingCompleted"
let kAddNewAttachFileTapped = "AddNewAttachFile"
let kElementWasDeletedNotification = "ElementWasDeletedNotification"
let kElementMoreDetailsNotification = "MoreButtonPressed"


