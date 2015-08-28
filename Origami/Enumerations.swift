//
//  Enumerations.swift
//  Origami
//
//  Created by CloudCraft on 10.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation

enum ElementTableCellType:String
{
    case TitleCell = "TitleCell"
    case ChatTableCell = "ChatTableCell"
    case DescriptionCell = "DescriptionCell"
    case AttachesHolderCell = "Attaches"
    case ActionButtonsCell = "ButtonsCell"
    case DatesCellMore = "More"
    case DatesCellLess = "Less"
    case SubordinatesHolderCell = "SubordinatesHolderCell"
}

enum ElementCellType:Int
{
    case Title = 0
    case Chat
    case Details
    case Attaches
    case Buttons
    case Subordinates
}

enum ElementDashboardTitleCellMode : Int
{
    case Title = 0
    case Dates = 1
}

enum ElementEditingStyle
{
    case AddNew
    case EditCurrent
}

enum DashCellType:Int
{
    case Signal = 1
    case SignalsToggleButton = 2
    case Other = 3
    case Messages = 4  // – When HOME collection view shows only cell which serves
                        //as signals show/hide toggling button, –
                        //we also need to show wide cell with messages in it
}

enum ProfileTextCellType:Int
{
    case Mood = 1
    case Email
    case Name
    case LastName
    case Country
    case Language
    case PhoneNumber
    case Age
    case Password
}

enum DisplayMode:Int
{
    case Day = 1
    case Night = 2
}

enum ActionButtonType:Int
{
    case Edit = 1
    case Add = 2
    case Delete = 3
    case Archive = 4
    case ToggleSignal = 5
    case ToggleCheckmark = 6
    case ToggleDone = 7
    case ToggleIdea = 8
    case ToggleTask = 9
    case AddAttachment = 10
}

enum ActionButtonCellType:Int
{
    case Edit = 0
    case Add
    case Delete
    case Archive
    case Signal  //4
    case CheckMark  //5
    case Idea //6
    case Solution //7
}

enum FadedTransitionDirection:String {
    case FadeIn = "FadeIn"
    case FadeOut = "FadeOut"
}

enum FileType:String {
    case Sound = "sound"
    case Video = "video"
    case Image = "image"
    case Document = "document"
}

