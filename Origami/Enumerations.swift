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
    //case Buttons
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
    case Email //2
    case Name //3
    case LastName //4
    case Country //5
    case Language //6
    case PhoneNumber //7
    case Age //8
    case Sex //9
    case Password //10
}

enum DisplayMode:Int
{
    case Day = 1
    case Night = 2
}

enum ToggleType {
    case ToggledOn (filterType:ActionButtonCellType)
    case ToggledOff (filterType:ActionButtonCellType)
    
    func toggleToOpposite() -> ToggleType
    {
        switch self
        {
        case .ToggledOn(let type):
            return .ToggledOff(filterType: type)
        case .ToggledOff(let type):
            return .ToggledOn(filterType: type)
        }
    }
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
    case Task  //5
    case Idea //6
    case Decision //7
}

enum ElementFinishState:Int{
    case Default = 10
    case InProcess = 20
    case FinishedGood = 30
    case FinishedBad = 40
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

enum TableItemPickerType:Int{
    case Country = 1
    case Language = 2
}


enum NewElementCreationType
{
    case Signal
    case Idea
    case Task
    case Decision
    case None
}
