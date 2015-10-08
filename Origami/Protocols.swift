//
//  Protocols.swift
//  Origami
//
//  Created by CloudCraft on 04.06.15.
//  Copyright (c) 2015 CloudCraft. All rights reserved.
//

import Foundation
import UIKit

protocol MessageObserver
{
    func newMessagesAdded(messages:[Message])
}

protocol ElementSelectionDelegate
{
    func didTapOnElement(element:Element)
}

protocol AttachmentSelectionDelegate
{
    func attachedFileTapped(attachFile:AttachFile)
}

protocol AttachViewerDelegate
{
    func attachViewerDeleteAttachButtonTapped(viewer:UIViewController)
    func attachViewerShouldAllowDeletion(viewer:UIViewController) -> Bool
}

protocol ButtonTapDelegate
{
    func didTapOnButton(button:UIButton)
}

protocol ChatInputViewDelegate
{
    func chatInputView(inputView:ChatTextInputView, wantsToChangeToNewSize desiredSize:CGSize)
    func chatInputView(inputView:ChatTextInputView, sendButtonTapped button:UIButton)
    func chatInputView(inputView:ChatTextInputView, attachButtonTapped button:UIButton)
}

@objc protocol AttachPickingDelegate {
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    func mediaPickerDidCancel(picker:AnyObject)
    optional func mediaPickerShouldAllowEditing(picker:AnyObject) -> Bool
}

@objc protocol ElementComposingDelegate
{
    func newElementComposerWantsToCancel(composer:NewElementComposerViewController)
    func newElementComposer(composer:NewElementComposerViewController, finishedCreatingNewElement newElement:Element)
    

    optional func newElementComposerTitleForNewElement(composer:NewElementComposerViewController) -> String?// { return nil }
    optional func newElementComposerDetailsForNewElement(composer:NewElementComposerViewController) -> String?// { return nil }
    optional func newElementForComposer(composer:NewElementComposerViewController) -> Element?// { return nil }
}
//extension ElementComposingDelegate
//{
//    func newElementComposerTitleForNewElement(composer:NewElementComposerViewController) -> String? { return nil }
//    func newElementComposerDetailsForNewElement(composer:NewElementComposerViewController) -> String? { return nil }
//    func newElementForComposer(composer:NewElementComposerViewController) -> Element? { return nil }
//}


protocol MessageTapDelegate
{
    func chatMessageWasTapped(message:Message?)
}

protocol UserProfileCollectionCellDelegate
{
    func showAvatarPressed()
    func changeAvatarPressed()
    func changeInfoPressed(cellType:ProfileTextCellType)
    func changeSexSwitchPresed(newValue:Int)
}

protocol TableItemPickerDelegate
{
    func itemPicker(itemPicker:AnyObject, didPickItem item:AnyObject)
    func itemPickerDidCancel(itemPicker:AnyObject)
}

protocol AllContactsDelegate
{
    func reloadUserContactsSender(sender:UIViewController?)
}

