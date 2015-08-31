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

protocol AttachPickingDelegate {
    func mediaPicker(picker:AnyObject, didPickMediaToAttach mediaFile:MediaFile)
    func mediaPickerDidCancel(picker:AnyObject)
}

protocol ElementComposingDelegate
{
    func newElementComposerWantsToCancel(composer:NewElementComposerViewController)
    func newElementComposer(composer:NewElementComposerViewController, finishedCreatingNewElement newElement:Element)
}

protocol MessageTapDelegate
{
    func chatMessageWasTapped(message:Message?)
}


protocol UserProfileAvatarCollectionCellDelegate
{
    func showAvatarPressed()
    func changeAvatarPressed()
    func changeInfoPressed(cellType:ProfileTextCellType)
}

protocol TableItemPickerDelegate
{
    func itemPicker(itemPicker:AnyObject, didPickItem item:AnyObject)
    func itemPickerDidCancel(itemPicker:AnyObject)
}